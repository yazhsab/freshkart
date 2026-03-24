const { supabaseAdmin } = require('../config/supabase');
const supabaseService = require('../services/supabase.service');
const fcmService = require('../services/fcm.service');
const smsService = require('../services/sms.service');
const slotService = require('../services/slot.service');
const { notificationQueue } = require('../queues/notification.queue');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

// ───── Dashboard ─────
const getDashboardStats = async (req, res, next) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const todayStart = `${today}T00:00:00`;
    const todayEnd = `${today}T23:59:59`;

    const [
      ordersToday,
      bookingsToday,
      pendingVendors,
      pendingWorkers,
      unassignedBookings,
      failedPayments,
      groceryRevenue,
      serviceRevenue
    ] = await Promise.all([
      supabaseAdmin.from('orders').select('*', { count: 'exact', head: true }).gte('created_at', todayStart).lte('created_at', todayEnd),
      supabaseAdmin.from('bookings').select('*', { count: 'exact', head: true }).gte('created_at', todayStart).lte('created_at', todayEnd),
      supabaseAdmin.from('vendors').select('*', { count: 'exact', head: true }).eq('is_approved', false),
      supabaseAdmin.from('workers').select('*', { count: 'exact', head: true }).eq('bgv_status', 'pending'),
      supabaseAdmin.from('bookings').select('*', { count: 'exact', head: true }).is('worker_id', null).eq('status', 'pending'),
      supabaseAdmin.from('payments').select('*', { count: 'exact', head: true }).eq('status', 'failed').gte('created_at', todayStart),
      supabaseAdmin.from('orders').select('final_amount').eq('status', 'delivered').gte('created_at', todayStart).lte('created_at', todayEnd),
      supabaseAdmin.from('bookings').select('final_price').eq('status', 'completed').gte('created_at', todayStart).lte('created_at', todayEnd)
    ]);

    // Last 7 days daily counts
    const last7Days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      last7Days.push(d.toISOString().split('T')[0]);
    }

    const [ordersLast7, bookingsLast7] = await Promise.all([
      supabaseAdmin.from('orders').select('created_at').gte('created_at', `${last7Days[0]}T00:00:00`),
      supabaseAdmin.from('bookings').select('created_at').gte('created_at', `${last7Days[0]}T00:00:00`)
    ]);

    const ordersByDay = {};
    const bookingsByDay = {};
    last7Days.forEach((d) => { ordersByDay[d] = 0; bookingsByDay[d] = 0; });

    (ordersLast7.data || []).forEach((o) => {
      const d = o.created_at.split('T')[0];
      if (ordersByDay[d] !== undefined) ordersByDay[d]++;
    });
    (bookingsLast7.data || []).forEach((b) => {
      const d = b.created_at.split('T')[0];
      if (bookingsByDay[d] !== undefined) bookingsByDay[d]++;
    });

    return successResponse(res, {
      orders_today: ordersToday.count || 0,
      bookings_today: bookingsToday.count || 0,
      pending_vendors: pendingVendors.count || 0,
      pending_workers: pendingWorkers.count || 0,
      unassigned_bookings: unassignedBookings.count || 0,
      failed_payments: failedPayments.count || 0,
      grocery_revenue: (groceryRevenue.data || []).reduce((s, o) => s + Number(o.final_amount), 0),
      service_revenue: (serviceRevenue.data || []).reduce((s, b) => s + Number(b.final_price || 0), 0),
      orders_last_7_days: ordersByDay,
      bookings_last_7_days: bookingsByDay
    });
  } catch (err) {
    next(err);
  }
};

const getActivityFeed = async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('admin_actions_log')
      .select('*, profiles!admin_id(full_name)')
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) return errorResponse(res, 'Failed to fetch activity feed', 400);

    return successResponse(res, data || []);
  } catch (err) {
    next(err);
  }
};

// ───── Vendors ─────
const getVendors = async (req, res, next) => {
  try {
    const { filter, search, page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('vendors')
      .select('*, profiles!owner_id(full_name, phone, email)', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to);

    if (filter === 'pending') query = query.eq('is_approved', false);
    if (filter === 'approved') query = query.eq('is_approved', true);
    if (filter === 'suspended') query = query.eq('is_active', false).eq('is_approved', true);
    if (search) query = query.ilike('shop_name', `%${search}%`);

    const { data, error, count } = await query;
    if (error) return errorResponse(res, 'Failed to fetch vendors', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const approveVendor = async (req, res, next) => {
  try {
    const { data: vendor, error } = await supabaseService.approveVendor(req.params.id);
    if (error) return errorResponse(res, 'Failed to approve vendor', 400);

    await supabaseService.logAdminAction(req.user.id, 'vendor_approved', 'vendor', req.params.id, null);

    if (vendor.profiles?.fcm_token) {
      await fcmService.sendToToken(vendor.profiles.fcm_token, {
        title: 'Shop Approved!',
        body: 'Your shop is now live on FreshKart. Start adding products!'
      });
    }

    if (vendor.profiles?.phone) {
      await smsService.sendVendorApprovalSMS(vendor.profiles.phone, vendor.shop_name);
    }

    return successResponse(res, { success: true }, 200, 'Vendor approved');
  } catch (err) {
    next(err);
  }
};

const suspendVendor = async (req, res, next) => {
  try {
    const { reason } = req.body;
    const { data, error } = await supabaseService.suspendVendor(req.params.id, reason);
    if (error) return errorResponse(res, 'Failed to suspend vendor', 400);

    await supabaseService.logAdminAction(req.user.id, 'vendor_suspended', 'vendor', req.params.id, reason);

    return successResponse(res, { success: true }, 200, 'Vendor suspended');
  } catch (err) {
    next(err);
  }
};

// ───── Orders ─────
const getOrders = async (req, res, next) => {
  try {
    const { status, date_from, date_to, page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('orders')
      .select('*, vendors(shop_name), profiles!customer_id(full_name, phone)', { count: 'exact' })
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

const updateOrderStatus = async (req, res, next) => {
  try {
    const { status, reason } = req.body;

    const { data, error } = await supabaseAdmin
      .from('orders')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to update order', 400);

    await supabaseService.logAdminAction(req.user.id, 'order_status_updated', 'order', req.params.id, `Status: ${status}. ${reason || ''}`);

    await notificationQueue.add('order-status-update', { orderId: req.params.id, status });

    return successResponse(res, data);
  } catch (err) {
    next(err);
  }
};

const assignAgentToOrder = async (req, res, next) => {
  try {
    const { agent_id } = req.body;

    const { data, error } = await supabaseAdmin
      .from('orders')
      .update({ delivery_agent_id: agent_id, assigned_at: new Date().toISOString() })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to assign agent', 400);

    await supabaseService.logAdminAction(req.user.id, 'agent_assigned', 'order', req.params.id, `Agent: ${agent_id}`);

    return successResponse(res, data);
  } catch (err) {
    next(err);
  }
};

// ───── Workers ─────
const getWorkers = async (req, res, next) => {
  try {
    const { bgv_status, skill, page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('workers')
      .select('*, profiles!user_id(full_name, phone, email)', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to);

    if (bgv_status) query = query.eq('bgv_status', bgv_status);
    if (skill) query = query.contains('service_category_ids', [skill]);

    const { data, error, count } = await query;
    if (error) return errorResponse(res, 'Failed to fetch workers', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const updateBGV = async (req, res, next) => {
  try {
    const { bgv_status, bgv_notes } = req.body;

    const updates = { bgv_status, bgv_notes };
    if (bgv_status === 'approved') {
      updates.is_approved = true;
    }

    const { data, error } = await supabaseAdmin
      .from('workers')
      .update(updates)
      .eq('id', req.params.id)
      .select('*, profiles!user_id(full_name, phone, fcm_token)')
      .single();

    if (error) return errorResponse(res, 'Failed to update BGV', 400);

    await supabaseService.logAdminAction(req.user.id, 'worker_bgv_updated', 'worker', req.params.id, `Status: ${bgv_status}. ${bgv_notes || ''}`);

    if (bgv_status === 'approved' && data.profiles?.fcm_token) {
      await fcmService.sendToToken(data.profiles.fcm_token, {
        title: 'Profile Verified!',
        body: 'You can now receive service bookings on FreshKart'
      });
      if (data.profiles?.phone) {
        await smsService.sendWorkerApprovalSMS(data.profiles.phone, data.profiles.full_name);
      }
    }

    return successResponse(res, { success: true });
  } catch (err) {
    next(err);
  }
};

const approveWorker = async (req, res, next) => {
  try {
    const { data, error } = await supabaseService.approveWorker(req.params.id);
    if (error) return errorResponse(res, 'Failed to approve worker', 400);

    await supabaseService.logAdminAction(req.user.id, 'worker_approved', 'worker', req.params.id, null);

    if (data.profiles?.fcm_token) {
      await fcmService.sendToToken(data.profiles.fcm_token, {
        title: 'Profile Verified!',
        body: 'You can now receive service bookings on FreshKart'
      });
    }
    if (data.profiles?.phone) {
      await smsService.sendWorkerApprovalSMS(data.profiles.phone, data.profiles.full_name);
    }

    return successResponse(res, { success: true }, 200, 'Worker approved');
  } catch (err) {
    next(err);
  }
};

const suspendWorker = async (req, res, next) => {
  try {
    const { reason } = req.body;

    const { error } = await supabaseAdmin
      .from('workers')
      .update({ is_available: false, is_approved: false, suspension_reason: reason })
      .eq('id', req.params.id);

    if (error) return errorResponse(res, 'Failed to suspend worker', 400);

    await supabaseService.logAdminAction(req.user.id, 'worker_suspended', 'worker', req.params.id, reason);

    return successResponse(res, { success: true }, 200, 'Worker suspended');
  } catch (err) {
    next(err);
  }
};

// ───── Bookings ─────
const getBookings = async (req, res, next) => {
  try {
    const { status, date, service, page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('bookings')
      .select('*, service_categories(name), profiles!customer_id(full_name, phone), workers(profiles!user_id(full_name))', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to);

    if (status) query = query.eq('status', status);
    if (date) query = query.eq('slot_date', date);
    if (service) query = query.eq('service_category_id', service);

    const { data, error, count } = await query;
    if (error) return errorResponse(res, 'Failed to fetch bookings', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const assignWorkerToBooking = async (req, res, next) => {
  try {
    const { worker_id } = req.body;
    if (!worker_id) return errorResponse(res, 'worker_id is required', 400);

    const { data: booking } = await supabaseAdmin
      .from('bookings')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (!booking) return errorResponse(res, 'Booking not found', 404);

    // Check worker availability
    const availability = await slotService.checkSlotAvailability(worker_id, booking.slot_date, booking.slot_start);
    if (!availability.available) {
      return errorResponse(res, 'Worker not available for this slot', 409);
    }

    // Lock slot
    const locked = await slotService.lockSlotRedis(worker_id, booking.slot_date, booking.slot_start, booking.id);
    if (!locked) {
      return errorResponse(res, 'Slot already locked by another booking', 409);
    }

    // Assign worker
    const { data: updated, error } = await supabaseAdmin
      .from('bookings')
      .update({ worker_id, status: 'assigned', assigned_at: new Date().toISOString() })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) {
      await slotService.releaseSlotRedis(worker_id, booking.slot_date, booking.slot_start);
      return errorResponse(res, 'Failed to assign worker', 400);
    }

    // Confirm slot in DB
    await slotService.confirmSlotBooking(worker_id, booking.slot_date, booking.slot_start, booking.id);

    await supabaseService.logAdminAction(req.user.id, 'worker_assigned', 'booking', req.params.id, `Worker: ${worker_id}`);

    // Send notifications
    await notificationQueue.add('booking-status-update', { bookingId: req.params.id, status: 'assigned' });

    // Schedule worker reminder 30min before
    const slotDateTime = new Date(`${booking.slot_date}T${booking.slot_start}:00+05:30`);
    const workerReminderDelay = slotDateTime.getTime() - Date.now() - 30 * 60 * 1000;
    if (workerReminderDelay > 0) {
      const { bookingQueue } = require('../queues/booking.queue');
      await bookingQueue.add('booking-reminder-worker', { bookingId: booking.id }, { delay: workerReminderDelay });
    }

    return successResponse(res, updated, 200, 'Worker assigned');
  } catch (err) {
    next(err);
  }
};

const updateBookingStatus = async (req, res, next) => {
  try {
    const { status, reason } = req.body;

    const { data, error } = await supabaseAdmin
      .from('bookings')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to update booking', 400);

    await supabaseService.logAdminAction(req.user.id, 'booking_status_updated', 'booking', req.params.id, `Status: ${status}. ${reason || ''}`);

    await notificationQueue.add('booking-status-update', { bookingId: req.params.id, status });

    return successResponse(res, data);
  } catch (err) {
    next(err);
  }
};

// ───── Customers ─────
const getCustomers = async (req, res, next) => {
  try {
    const { filter, search, page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('profiles')
      .select('*', { count: 'exact' })
      .eq('role', 'customer')
      .order('created_at', { ascending: false })
      .range(from, to);

    if (filter === 'banned') query = query.eq('is_banned', true);
    if (search) query = query.or(`full_name.ilike.%${search}%,phone.ilike.%${search}%`);

    const { data, error, count } = await query;
    if (error) return errorResponse(res, 'Failed to fetch customers', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const banCustomer = async (req, res, next) => {
  try {
    const { is_banned, reason } = req.body;

    const { error } = await supabaseAdmin
      .from('profiles')
      .update({ is_banned: is_banned !== false, ban_reason: reason })
      .eq('id', req.params.id);

    if (error) return errorResponse(res, 'Failed to update customer', 400);

    await supabaseService.logAdminAction(req.user.id, is_banned ? 'customer_banned' : 'customer_unbanned', 'customer', req.params.id, reason);

    return successResponse(res, { success: true });
  } catch (err) {
    next(err);
  }
};

// ───── Payouts ─────
const getVendorPayouts = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('payouts')
      .select('*, vendors!payee_id(shop_name)', { count: 'exact' })
      .eq('payee_type', 'vendor')
      .order('created_at', { ascending: false })
      .range(from, to);

    if (status) query = query.eq('status', status);

    const { data, error, count } = await query;
    if (error) return errorResponse(res, 'Failed to fetch payouts', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getWorkerPayouts = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('payouts')
      .select('*, workers!payee_id(full_name)', { count: 'exact' })
      .eq('payee_type', 'worker')
      .order('created_at', { ascending: false })
      .range(from, to);

    if (status) query = query.eq('status', status);

    const { data, error, count } = await query;
    if (error) return errorResponse(res, 'Failed to fetch payouts', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const markVendorPayoutPaid = async (req, res, next) => {
  try {
    const { payment_reference } = req.body;
    const { data, error } = await supabaseService.markPayoutPaid(req.params.id, payment_reference);
    if (error) return errorResponse(res, 'Failed to mark payout', 400);

    await supabaseService.logAdminAction(req.user.id, 'payout_marked_paid', 'payout', req.params.id, `Ref: ${payment_reference}`);

    return successResponse(res, data, 200, 'Payout marked as paid');
  } catch (err) {
    next(err);
  }
};

const markWorkerPayoutPaid = async (req, res, next) => {
  try {
    const { payment_reference } = req.body;
    const { data, error } = await supabaseService.markPayoutPaid(req.params.id, payment_reference);
    if (error) return errorResponse(res, 'Failed to mark payout', 400);

    await supabaseService.logAdminAction(req.user.id, 'payout_marked_paid', 'payout', req.params.id, `Ref: ${payment_reference}`);

    return successResponse(res, data, 200, 'Payout marked as paid');
  } catch (err) {
    next(err);
  }
};

// ───── Analytics ─────
const getAnalytics = async (req, res, next) => {
  try {
    const { period = '7days' } = req.query;

    let dateFrom;
    const now = new Date();
    if (period === 'today') dateFrom = new Date(now.toISOString().split('T')[0]);
    else if (period === '7days') dateFrom = new Date(now.getTime() - 7 * 86400000);
    else if (period === '30days') dateFrom = new Date(now.getTime() - 30 * 86400000);
    else if (period === '90days') dateFrom = new Date(now.getTime() - 90 * 86400000);
    else dateFrom = new Date(now.getTime() - 7 * 86400000);

    const dateFromISO = dateFrom.toISOString();

    const [orders, bookings, payments, newCustomers, newVendors] = await Promise.all([
      supabaseAdmin.from('orders').select('status, final_amount, created_at').gte('created_at', dateFromISO),
      supabaseAdmin.from('bookings').select('status, final_price, created_at').gte('created_at', dateFromISO),
      supabaseAdmin.from('payments').select('status, amount, gateway').gte('created_at', dateFromISO),
      supabaseAdmin.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'customer').gte('created_at', dateFromISO),
      supabaseAdmin.from('vendors').select('*', { count: 'exact', head: true }).gte('created_at', dateFromISO)
    ]);

    const orderData = orders.data || [];
    const bookingData = bookings.data || [];
    const paymentData = payments.data || [];

    const deliveredOrders = orderData.filter((o) => o.status === 'delivered');
    const completedBookings = bookingData.filter((b) => b.status === 'completed');
    const successfulPayments = paymentData.filter((p) => p.status === 'success');

    return successResponse(res, {
      period,
      orders: {
        total: orderData.length,
        delivered: deliveredOrders.length,
        cancelled: orderData.filter((o) => o.status === 'cancelled').length,
        revenue: deliveredOrders.reduce((s, o) => s + Number(o.final_amount), 0)
      },
      bookings: {
        total: bookingData.length,
        completed: completedBookings.length,
        cancelled: bookingData.filter((b) => b.status === 'cancelled').length,
        revenue: completedBookings.reduce((s, b) => s + Number(b.final_price || 0), 0)
      },
      payments: {
        total: paymentData.length,
        successful: successfulPayments.length,
        failed: paymentData.filter((p) => p.status === 'failed').length,
        total_amount: successfulPayments.reduce((s, p) => s + Number(p.amount), 0)
      },
      growth: {
        new_customers: newCustomers.count || 0,
        new_vendors: newVendors.count || 0
      }
    });
  } catch (err) {
    next(err);
  }
};

// ───── Notifications ─────
const sendBulkNotification = async (req, res, next) => {
  try {
    const { audience, title, body, channels = ['push'] } = req.body;

    if (!audience || !title || !body) {
      return errorResponse(res, 'audience, title, and body are required', 400);
    }

    let query = supabaseAdmin.from('profiles').select('id, fcm_token, phone');

    switch (audience) {
      case 'all_customers': query = query.eq('role', 'customer'); break;
      case 'all_vendors': query = query.eq('role', 'vendor'); break;
      case 'all_workers': query = query.eq('role', 'worker'); break;
      case 'all_agents': query = query.eq('role', 'delivery_agent'); break;
      case 'all': break;
      default: return errorResponse(res, 'Invalid audience', 400);
    }

    const { data: profiles } = await query;
    if (!profiles?.length) return errorResponse(res, 'No recipients found', 404);

    let pushResults = { successCount: 0, failureCount: 0 };
    let smsCount = 0;

    if (channels.includes('push')) {
      const tokens = profiles.map((p) => p.fcm_token).filter(Boolean);
      if (tokens.length) {
        pushResults = await fcmService.sendToMultiple(tokens, { title, body });
      }
    }

    if (channels.includes('sms')) {
      const phones = profiles.map((p) => p.phone).filter(Boolean);
      for (const phone of phones) {
        await smsService.sendOrderSMS(phone, { customerName: '', orderNumber: '', status: body, vendorName: 'FreshKart' });
        smsCount++;
      }
    }

    // Log for each user
    const logs = profiles.map((p) => ({
      user_id: p.id,
      type: 'admin_broadcast',
      title,
      body,
      ref_type: 'admin',
      ref_id: req.user.id
    }));

    await supabaseAdmin.from('notifications_log').insert(logs);

    await supabaseService.logAdminAction(req.user.id, 'bulk_notification_sent', 'notification', null, `Audience: ${audience}, Push: ${pushResults.successCount}, SMS: ${smsCount}`);

    return successResponse(res, {
      push_sent: pushResults.successCount,
      push_failed: pushResults.failureCount,
      sms_sent: smsCount,
      total_recipients: profiles.length
    });
  } catch (err) {
    next(err);
  }
};

// ───── Config ─────
const getConfig = async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('platform_config')
      .select('*')
      .single();

    if (error) return errorResponse(res, 'Failed to fetch config', 400);

    return successResponse(res, data);
  } catch (err) {
    next(err);
  }
};

const updateConfig = async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('platform_config')
      .update(req.body)
      .eq('id', 1)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to update config', 400);

    await supabaseService.logAdminAction(req.user.id, 'config_updated', 'config', '1', JSON.stringify(req.body));

    return successResponse(res, data, 200, 'Config updated');
  } catch (err) {
    next(err);
  }
};

// ───── Zones ─────
const getZones = async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('delivery_zones')
      .select('*')
      .order('name', { ascending: true });

    if (error) return errorResponse(res, 'Failed to fetch zones', 400);

    return successResponse(res, data || []);
  } catch (err) {
    next(err);
  }
};

const createZone = async (req, res, next) => {
  try {
    const { name, pincodes, is_active = true } = req.body;

    const { data, error } = await supabaseAdmin
      .from('delivery_zones')
      .insert({ name, pincodes, is_active })
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to create zone', 400);

    return successResponse(res, data, 201, 'Zone created');
  } catch (err) {
    next(err);
  }
};

const updateZone = async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('delivery_zones')
      .update(req.body)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to update zone', 400);

    return successResponse(res, data, 200, 'Zone updated');
  } catch (err) {
    next(err);
  }
};

const toggleZone = async (req, res, next) => {
  try {
    const { data: zone } = await supabaseAdmin
      .from('delivery_zones')
      .select('is_active')
      .eq('id', req.params.id)
      .single();

    if (!zone) return errorResponse(res, 'Zone not found', 404);

    const { data, error } = await supabaseAdmin
      .from('delivery_zones')
      .update({ is_active: !zone.is_active })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to toggle zone', 400);

    return successResponse(res, data);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getDashboardStats,
  getActivityFeed,
  getVendors,
  approveVendor,
  suspendVendor,
  getOrders,
  updateOrderStatus,
  assignAgentToOrder,
  getWorkers,
  updateBGV,
  approveWorker,
  suspendWorker,
  getBookings,
  assignWorkerToBooking,
  updateBookingStatus,
  getCustomers,
  banCustomer,
  getVendorPayouts,
  getWorkerPayouts,
  markVendorPayoutPaid,
  markWorkerPayoutPaid,
  getAnalytics,
  sendBulkNotification,
  getConfig,
  updateConfig,
  getZones,
  createZone,
  updateZone,
  toggleZone
};
