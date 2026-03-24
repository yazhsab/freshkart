const { supabaseAdmin } = require('../config/supabase');
const olamapsService = require('../services/olamaps.service');
const { notificationQueue } = require('../queues/notification.queue');
const { maskPhone } = require('../utils/crypto.util');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const updateLocation = async (req, res, next) => {
  try {
    const { lat, lng, order_id } = req.body;

    if (!lat || !lng) {
      return errorResponse(res, 'lat and lng are required', 400);
    }

    const locationData = {
      agent_id: req.user.id,
      lat,
      lng,
      updated_at: new Date().toISOString()
    };

    if (order_id) locationData.order_id = order_id;

    const { error } = await supabaseAdmin
      .from('delivery_locations')
      .upsert(locationData, { onConflict: 'agent_id' });

    if (error) {
      return errorResponse(res, 'Failed to update location', 400);
    }

    return successResponse(res, { success: true });
  } catch (err) {
    next(err);
  }
};

const trackOrder = async (req, res, next) => {
  try {
    const { data: order } = await supabaseAdmin
      .from('orders')
      .select('id, customer_id, delivery_agent_id, delivery_address, status')
      .eq('id', req.params.orderId)
      .single();

    if (!order) return errorResponse(res, 'Order not found', 404);
    if (order.customer_id !== req.user.id) return errorResponse(res, 'Access denied', 403);
    if (!order.delivery_agent_id) return errorResponse(res, 'No delivery agent assigned yet', 400);

    // Fetch agent location
    const { data: location } = await supabaseAdmin
      .from('delivery_locations')
      .select('lat, lng, updated_at')
      .eq('agent_id', order.delivery_agent_id)
      .single();

    // Fetch agent profile
    const { data: agentProfile } = await supabaseAdmin
      .from('profiles')
      .select('full_name, phone')
      .eq('id', order.delivery_agent_id)
      .single();

    let estimatedMins = null;
    if (location && order.delivery_address?.lat) {
      estimatedMins = await olamapsService.estimateDeliveryTime(
        location.lat, location.lng,
        order.delivery_address.lat, order.delivery_address.lng
      );
    }

    return successResponse(res, {
      agent: {
        name: agentProfile?.full_name,
        phone: maskPhone(agentProfile?.phone)
      },
      location: location ? { lat: location.lat, lng: location.lng } : null,
      estimated_mins: estimatedMins,
      status: order.status
    });
  } catch (err) {
    next(err);
  }
};

const getAvailableOrders = async (req, res, next) => {
  try {
    if (req.user.role !== 'delivery_agent') {
      return errorResponse(res, 'Only delivery agents can view available orders', 403);
    }

    const { data: orders, error } = await supabaseAdmin
      .from('orders')
      .select('id, order_number, vendor_id, delivery_address, final_amount, created_at, vendors(shop_name, address, lat, lng)')
      .eq('status', 'ready')
      .is('delivery_agent_id', null)
      .order('created_at', { ascending: true })
      .limit(20);

    if (error) return errorResponse(res, 'Failed to fetch orders', 400);

    return successResponse(res, orders || []);
  } catch (err) {
    next(err);
  }
};

const acceptOrder = async (req, res, next) => {
  try {
    if (req.user.role !== 'delivery_agent') {
      return errorResponse(res, 'Only delivery agents can accept orders', 403);
    }

    // Check no active delivery
    const { data: active } = await supabaseAdmin
      .from('orders')
      .select('id')
      .eq('delivery_agent_id', req.user.id)
      .in('status', ['picked_up'])
      .limit(1);

    if (active?.length) {
      return errorResponse(res, 'Complete your current delivery first', 400);
    }

    const { data: order, error } = await supabaseAdmin
      .from('orders')
      .update({
        delivery_agent_id: req.user.id,
        assigned_at: new Date().toISOString()
      })
      .eq('id', req.params.orderId)
      .eq('status', 'ready')
      .is('delivery_agent_id', null)
      .select()
      .single();

    if (error || !order) {
      return errorResponse(res, 'Order no longer available', 409);
    }

    await notificationQueue.add('order-status-update', {
      orderId: order.id,
      status: 'agent_assigned'
    });

    return successResponse(res, order, 200, 'Order accepted');
  } catch (err) {
    next(err);
  }
};

const confirmPickup = async (req, res, next) => {
  try {
    const { otp } = req.body;

    const { data: order } = await supabaseAdmin
      .from('orders')
      .select('id, delivery_agent_id, delivery_otp, status')
      .eq('id', req.params.orderId)
      .single();

    if (!order) return errorResponse(res, 'Order not found', 404);
    if (order.delivery_agent_id !== req.user.id) return errorResponse(res, 'Not your order', 403);
    if (!['ready', 'confirmed'].includes(order.status)) {
      return errorResponse(res, 'Order not ready for pickup', 400);
    }

    if (otp !== order.delivery_otp) {
      return errorResponse(res, 'Invalid OTP', 400);
    }

    const { data: updated, error } = await supabaseAdmin
      .from('orders')
      .update({ status: 'picked_up', picked_up_at: new Date().toISOString() })
      .eq('id', req.params.orderId)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to confirm pickup', 400);

    await notificationQueue.add('order-status-update', {
      orderId: order.id,
      status: 'picked_up'
    });

    return successResponse(res, { success: true });
  } catch (err) {
    next(err);
  }
};

const confirmDelivery = async (req, res, next) => {
  try {
    const { otp } = req.body;

    const { data: order } = await supabaseAdmin
      .from('orders')
      .select('id, delivery_agent_id, delivery_otp, status, payment_method, customer_id')
      .eq('id', req.params.orderId)
      .single();

    if (!order) return errorResponse(res, 'Order not found', 404);
    if (order.delivery_agent_id !== req.user.id) return errorResponse(res, 'Not your order', 403);
    if (order.status !== 'picked_up') return errorResponse(res, 'Order not in transit', 400);

    if (otp !== order.delivery_otp) {
      return errorResponse(res, 'Invalid delivery OTP', 400);
    }

    const updates = {
      status: 'delivered',
      delivered_at: new Date().toISOString()
    };

    if (order.payment_method === 'cod') {
      updates.payment_status = 'paid';
    }

    const { error } = await supabaseAdmin
      .from('orders')
      .update(updates)
      .eq('id', req.params.orderId);

    if (error) return errorResponse(res, 'Failed to confirm delivery', 400);

    await notificationQueue.add('order-status-update', {
      orderId: order.id,
      status: 'delivered'
    });

    await notificationQueue.add('rating-reminder', {
      customerId: order.customer_id,
      type: 'order',
      refId: order.id
    }, { delay: 30 * 60 * 1000 });

    return successResponse(res, { success: true, earnings: 30 });
  } catch (err) {
    next(err);
  }
};

const getEarnings = async (req, res, next) => {
  try {
    const { period = '7days' } = req.query;

    let dateFrom;
    const now = new Date();
    if (period === 'today') {
      dateFrom = new Date(now.toISOString().split('T')[0]);
    } else if (period === '7days') {
      dateFrom = new Date(now.getTime() - 7 * 86400000);
    } else if (period === '30days') {
      dateFrom = new Date(now.getTime() - 30 * 86400000);
    } else {
      dateFrom = new Date(now.getTime() - 7 * 86400000);
    }

    const { data: deliveries, count } = await supabaseAdmin
      .from('orders')
      .select('id, delivered_at, final_amount', { count: 'exact' })
      .eq('delivery_agent_id', req.user.id)
      .eq('status', 'delivered')
      .gte('delivered_at', dateFrom.toISOString());

    const deliveryCount = count || 0;
    const totalEarnings = deliveryCount * 30; // ₹30 per delivery

    return successResponse(res, {
      period,
      delivery_count: deliveryCount,
      total_earnings: totalEarnings,
      per_delivery: 30
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  updateLocation,
  trackOrder,
  getAvailableOrders,
  acceptOrder,
  confirmPickup,
  confirmDelivery,
  getEarnings
};
