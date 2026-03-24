const { supabaseAdmin } = require('../config/supabase');
const razorpayService = require('../services/razorpay.service');
const { generateDeliveryOTP } = require('../utils/crypto.util');
const { notificationQueue } = require('../queues/notification.queue');
const { orderQueue } = require('../queues/order.queue');
const couponService = require('../services/coupon.service');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const createOrder = async (req, res, next) => {
  try {
    const { vendor_id, items, delivery_address, payment_method, special_instructions, coupon_code, wallet_amount, loyalty_points_to_redeem, scheduled_at } = req.body;

    // 1. Verify vendor exists and is active
    const { data: vendor } = await supabaseAdmin
      .from('vendors')
      .select('id, is_approved, is_open, free_delivery_above, min_order_amount')
      .eq('id', vendor_id)
      .single();

    if (!vendor || !vendor.is_approved) {
      return errorResponse(res, 'Vendor not found or not active', 404);
    }

    // 2. Fetch and verify all products
    const productIds = items.map((i) => i.product_id);
    const { data: products } = await supabaseAdmin
      .from('products')
      .select('*')
      .in('id', productIds)
      .eq('vendor_id', vendor_id);

    if (!products || products.length !== productIds.length) {
      return errorResponse(res, 'One or more products not found or not from this vendor', 400);
    }

    const productMap = {};
    for (const p of products) productMap[p.id] = p;

    // Verify availability and stock
    for (const item of items) {
      const product = productMap[item.product_id];
      if (!product) {
        return errorResponse(res, `Product ${item.product_id} not found`, 400);
      }
      if (!product.is_available) {
        return errorResponse(res, `${product.name} is currently unavailable`, 400);
      }
      if (product.stock_quantity < item.quantity) {
        return errorResponse(res, `Insufficient stock for ${product.name}. Available: ${product.stock_quantity}`, 400);
      }
    }

    // 3. Calculate totals
    let subtotal = 0;
    for (const item of items) {
      subtotal += productMap[item.product_id].price * item.quantity;
    }

    if (vendor.min_order_amount && subtotal < vendor.min_order_amount) {
      return errorResponse(res, `Minimum order amount is ₹${vendor.min_order_amount}`, 400);
    }

    const freeDeliveryThreshold = vendor.free_delivery_above || 500;
    const deliveryFee = subtotal >= freeDeliveryThreshold ? 0 : 30;

    // Apply coupon if provided
    let couponDiscount = 0;
    let couponId = null;
    if (coupon_code) {
      const couponResult = await couponService.validateCoupon(coupon_code, req.user.id, subtotal, vendor_id);
      if (!couponResult.valid) return errorResponse(res, couponResult.reason, 400);
      couponDiscount = couponResult.discount_amount;
      couponId = couponResult.coupon.id;
    }

    // Apply loyalty points if provided
    let loyaltyDiscount = 0;
    if (loyalty_points_to_redeem && loyalty_points_to_redeem > 0) {
      loyaltyDiscount = loyalty_points_to_redeem; // 1 point = ₹1
    }

    const finalAmount = subtotal + deliveryFee - couponDiscount - loyaltyDiscount - (wallet_amount || 0);

    // 4. Generate delivery OTP
    const deliveryOtp = generateDeliveryOTP();

    // 5. Create order via RPC (atomic stock decrement)
    const { data: orderId, error: orderError } = await supabaseAdmin.rpc('create_order', {
      p_customer_id: req.user.id,
      p_vendor_id: vendor_id,
      p_items: items,
      p_delivery_address: delivery_address,
      p_payment_method: payment_method,
      p_subtotal: subtotal,
      p_delivery_fee: deliveryFee,
      p_final_amount: finalAmount,
      p_delivery_otp: deliveryOtp,
      p_special_instructions: special_instructions || null
    });

    if (orderError) {
      logger.error('Order creation RPC failed', { error: orderError, userId: req.user.id });
      return errorResponse(res, 'Failed to create order', 500);
    }

    // 6. Fetch created order
    const { data: order } = await supabaseAdmin
      .from('orders')
      .select('*')
      .eq('id', orderId)
      .single();

    // 7. If not COD: create Razorpay order
    let razorpayOrder = null;
    if (payment_method !== 'cod') {
      razorpayOrder = await razorpayService.createOrder({
        amount: finalAmount,
        receipt: orderId
      });

      await supabaseAdmin
        .from('orders')
        .update({ razorpay_order_id: razorpayOrder.id })
        .eq('id', orderId);
    }

    // 8. Record coupon usage if applied
    if (couponId) {
      await couponService.recordUsage(couponId, req.user.id, orderId, couponDiscount);
    }

    // 9. Queue notifications
    await notificationQueue.add('new-order-vendor', { orderId });

    // 10. Queue auto-confirm (60s delay)
    await orderQueue.add('auto-confirm-vendor', { orderId }, { delay: 60000 });

    logger.info('Order created', { orderId, userId: req.user.id, amount: finalAmount });

    return successResponse(res, {
      order,
      razorpay_order: razorpayOrder ? {
        id: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency
      } : null
    }, 201, 'Order created');
  } catch (err) {
    next(err);
  }
};

const getCustomerOrders = async (req, res, next) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('orders')
      .select('*, order_items(*), vendors(shop_name, phone)', { count: 'exact' })
      .eq('customer_id', req.user.id)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (status) query = query.eq('status', status);

    const { data, error, count } = await query;

    if (error) return errorResponse(res, 'Failed to fetch orders', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getVendorOrders = async (req, res, next) => {
  try {
    const { data: vendor } = await supabaseAdmin
      .from('vendors')
      .select('id')
      .eq('owner_id', req.user.id)
      .single();

    if (!vendor) return errorResponse(res, 'Vendor not found', 404);

    const { status, page = 1, limit = 20, date_from, date_to } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('orders')
      .select('*, order_items(*), profiles!customer_id(full_name, phone)', { count: 'exact' })
      .eq('vendor_id', vendor.id)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (status) query = query.eq('status', status);
    if (date_from) query = query.gte('created_at', date_from);
    if (date_to) query = query.lte('created_at', date_to);

    const { data, error, count } = await query;

    if (error) return errorResponse(res, 'Failed to fetch orders', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getAgentOrders = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('orders')
      .select('*, vendors(shop_name, lat, lng, phone)', { count: 'exact' })
      .eq('delivery_agent_id', req.user.id)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (status) query = query.eq('status', status);

    const { data, error, count } = await query;

    if (error) return errorResponse(res, 'Failed to fetch orders', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getOrderById = async (req, res, next) => {
  try {
    const { data: order, error } = await supabaseAdmin
      .from('orders')
      .select('*, order_items(*), vendors(shop_name, phone, lat, lng), profiles!customer_id(full_name, phone)')
      .eq('id', req.params.id)
      .single();

    if (error || !order) {
      return errorResponse(res, 'Order not found', 404);
    }

    // Verify access
    const userId = req.user.id;
    const isCustomer = order.customer_id === userId;
    const isAgent = order.delivery_agent_id === userId;

    // Check if user is vendor owner
    let isVendor = false;
    if (!isCustomer && !isAgent) {
      const { data: vendor } = await supabaseAdmin
        .from('vendors')
        .select('id')
        .eq('id', order.vendor_id)
        .eq('owner_id', userId)
        .single();
      isVendor = !!vendor;
    }

    if (!isCustomer && !isAgent && !isVendor && req.user.role !== 'admin') {
      return errorResponse(res, 'Access denied', 403);
    }

    return successResponse(res, order);
  } catch (err) {
    next(err);
  }
};

const updateOrderStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    const { data: order } = await supabaseAdmin
      .from('orders')
      .select('*, vendors(owner_id)')
      .eq('id', req.params.id)
      .single();

    if (!order) return errorResponse(res, 'Order not found', 404);

    // Validate role-based transitions
    const vendorTransitions = { pending: 'confirmed', confirmed: 'packing', packing: 'ready' };
    const agentTransitions = { ready: 'picked_up', picked_up: 'delivered' };

    const isVendorOwner = order.vendors?.owner_id === req.user.id;
    const isAgent = order.delivery_agent_id === req.user.id;

    if (isVendorOwner) {
      if (vendorTransitions[order.status] !== status) {
        return errorResponse(res, `Cannot transition from ${order.status} to ${status}`, 400);
      }
    } else if (isAgent) {
      if (agentTransitions[order.status] !== status) {
        return errorResponse(res, `Cannot transition from ${order.status} to ${status}`, 400);
      }
    } else if (req.user.role !== 'admin') {
      return errorResponse(res, 'Not authorized to update this order', 403);
    }

    const extra = {};
    if (status === 'delivered' && order.payment_method === 'cod') {
      extra.payment_status = 'paid';
    }

    const { data: updated, error } = await supabaseAdmin
      .from('orders')
      .update({ status, ...extra, updated_at: new Date().toISOString() })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to update status', 400);

    // Queue notifications
    await notificationQueue.add('order-status-update', {
      orderId: req.params.id,
      status
    });

    // Queue rating reminder on delivery
    if (status === 'delivered') {
      await notificationQueue.add('rating-reminder', {
        customerId: order.customer_id,
        type: 'order',
        refId: order.id
      }, { delay: 30 * 60 * 1000 });

      // Earn loyalty points
      const loyaltyService = require('../services/loyalty.service');
      await loyaltyService.earnPoints(order.customer_id, order.final_amount, order.id);

      // Complete referral if first order
      const referralService = require('../services/referral.service');
      await referralService.completeReferral(order.customer_id, order.id);
    }

    return successResponse(res, updated, 200, `Order ${status}`);
  } catch (err) {
    next(err);
  }
};

const cancelOrder = async (req, res, next) => {
  try {
    const { data: order } = await supabaseAdmin
      .from('orders')
      .select('*, order_items(*)')
      .eq('id', req.params.id)
      .eq('customer_id', req.user.id)
      .single();

    if (!order) return errorResponse(res, 'Order not found', 404);

    if (order.status !== 'pending') {
      return errorResponse(res, 'Can only cancel pending orders', 400);
    }

    // Restore stock
    for (const item of (order.order_items || [])) {
      await supabaseAdmin.rpc('increment_stock', {
        p_product_id: item.product_id,
        p_quantity: item.quantity
      });
    }

    // Update order
    await supabaseAdmin
      .from('orders')
      .update({
        status: 'cancelled',
        cancelled_by: 'customer',
        cancel_reason: req.body.cancel_reason || 'Cancelled by customer',
        cancelled_at: new Date().toISOString()
      })
      .eq('id', req.params.id);

    // Initiate refund if paid
    let refundData = null;
    if (order.payment_status === 'paid' && order.razorpay_payment_id) {
      try {
        refundData = await razorpayService.createRefund(
          order.razorpay_payment_id,
          order.final_amount,
          { reason: 'customer_cancellation', order_id: order.id }
        );

        await supabaseAdmin
          .from('orders')
          .update({ payment_status: 'refunded' })
          .eq('id', req.params.id);
      } catch (refundErr) {
        logger.error('Refund failed for cancelled order', { error: refundErr.message, orderId: order.id });
      }
    }

    await notificationQueue.add('order-status-update', {
      orderId: req.params.id,
      status: 'cancelled'
    });

    return successResponse(res, {
      message: 'Order cancelled',
      refund: refundData
    });
  } catch (err) {
    next(err);
  }
};

const assignAgent = async (req, res, next) => {
  try {
    if (req.user.role !== 'delivery_agent') {
      return errorResponse(res, 'Only delivery agents can self-assign', 403);
    }

    // Check agent has no active delivery
    const { data: activeOrders } = await supabaseAdmin
      .from('orders')
      .select('id')
      .eq('delivery_agent_id', req.user.id)
      .in('status', ['picked_up']);

    if (activeOrders?.length) {
      return errorResponse(res, 'You already have an active delivery', 400);
    }

    const { data: order } = await supabaseAdmin
      .from('orders')
      .select('id, status')
      .eq('id', req.params.id)
      .eq('status', 'ready')
      .is('delivery_agent_id', null)
      .single();

    if (!order) {
      return errorResponse(res, 'Order not available for pickup', 404);
    }

    const { data: updated, error } = await supabaseAdmin
      .from('orders')
      .update({
        delivery_agent_id: req.user.id,
        assigned_at: new Date().toISOString()
      })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to assign', 400);

    await notificationQueue.add('order-status-update', {
      orderId: req.params.id,
      status: 'agent_assigned'
    });

    return successResponse(res, updated, 200, 'Order assigned to you');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createOrder,
  getCustomerOrders,
  getVendorOrders,
  getAgentOrders,
  getOrderById,
  updateOrderStatus,
  cancelOrder,
  assignAgent
};
