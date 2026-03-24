const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

// ───── Profile ─────
const getProfile = async (userId) => {
  const { data, error } = await supabaseAdmin
    .from('profiles')
    .select('*, addresses(*)')
    .eq('id', userId)
    .single();
  return { data, error };
};

const updateProfile = async (userId, updates) => {
  const { data, error } = await supabaseAdmin
    .from('profiles')
    .update(updates)
    .eq('id', userId)
    .select()
    .single();
  return { data, error };
};

// ───── Vendor ─────
const getVendorByOwnerId = async (ownerId) => {
  const { data, error } = await supabaseAdmin
    .from('vendors')
    .select('*')
    .eq('owner_id', ownerId)
    .single();
  return { data, error };
};

const getVendorById = async (vendorId) => {
  const { data, error } = await supabaseAdmin
    .from('vendors')
    .select('*, profiles!owner_id(full_name, phone, fcm_token)')
    .eq('id', vendorId)
    .single();
  return { data, error };
};

const approveVendor = async (vendorId) => {
  const { data, error } = await supabaseAdmin
    .from('vendors')
    .update({ is_approved: true, is_active: true, approved_at: new Date().toISOString() })
    .eq('id', vendorId)
    .select('*, profiles!owner_id(full_name, phone, fcm_token)')
    .single();
  return { data, error };
};

const suspendVendor = async (vendorId, reason) => {
  const { data, error } = await supabaseAdmin
    .from('vendors')
    .update({ is_active: false, suspension_reason: reason, suspended_at: new Date().toISOString() })
    .eq('id', vendorId)
    .select()
    .single();
  return { data, error };
};

// ───── Product ─────
const getProductsByVendor = async (vendorId, page = 1, limit = 50) => {
  const from = (page - 1) * limit;
  const to = from + limit - 1;

  const { data, error, count } = await supabaseAdmin
    .from('products')
    .select('*', { count: 'exact' })
    .eq('vendor_id', vendorId)
    .order('created_at', { ascending: false })
    .range(from, to);
  return { data, error, count };
};

const getProductById = async (productId) => {
  const { data, error } = await supabaseAdmin
    .from('products')
    .select('*, vendors(shop_name, is_open)')
    .eq('id', productId)
    .single();
  return { data, error };
};

const decrementStock = async (productId, qty) => {
  const { data, error } = await supabaseAdmin.rpc('decrement_stock', {
    p_product_id: productId,
    p_quantity: qty
  });
  return { data, error };
};

// ───── Order ─────
const createOrder = async (orderData) => {
  const { data, error } = await supabaseAdmin.rpc('create_order', orderData);
  return { data, error };
};

const createOrderItems = async (items) => {
  const { data, error } = await supabaseAdmin
    .from('order_items')
    .insert(items)
    .select();
  return { data, error };
};

const getOrderById = async (orderId) => {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .select('*, order_items(*), vendors(shop_name, phone, lat, lng), profiles!customer_id(full_name, phone, fcm_token)')
    .eq('id', orderId)
    .single();
  return { data, error };
};

const getOrdersByCustomer = async (customerId, page = 1, limit = 10) => {
  const from = (page - 1) * limit;
  const to = from + limit - 1;

  const { data, error, count } = await supabaseAdmin
    .from('orders')
    .select('*, order_items(*), vendors(shop_name)', { count: 'exact' })
    .eq('customer_id', customerId)
    .order('created_at', { ascending: false })
    .range(from, to);
  return { data, error, count };
};

const getOrdersByVendor = async (vendorId, filters = {}) => {
  const { status, page = 1, limit = 20, dateFrom, dateTo } = filters;
  const from = (page - 1) * limit;
  const to = from + limit - 1;

  let query = supabaseAdmin
    .from('orders')
    .select('*, order_items(*), profiles!customer_id(full_name, phone)', { count: 'exact' })
    .eq('vendor_id', vendorId)
    .order('created_at', { ascending: false })
    .range(from, to);

  if (status) query = query.eq('status', status);
  if (dateFrom) query = query.gte('created_at', dateFrom);
  if (dateTo) query = query.lte('created_at', dateTo);

  const { data, error, count } = await query;
  return { data, error, count };
};

const updateOrderStatus = async (orderId, status, extra = {}) => {
  const updates = { status, ...extra, updated_at: new Date().toISOString() };

  if (status === 'picked_up') updates.picked_up_at = new Date().toISOString();
  if (status === 'delivered') updates.delivered_at = new Date().toISOString();
  if (status === 'cancelled') updates.cancelled_at = new Date().toISOString();

  const { data, error } = await supabaseAdmin
    .from('orders')
    .update(updates)
    .eq('id', orderId)
    .select()
    .single();
  return { data, error };
};

// ───── Booking ─────
const createBooking = async (bookingData) => {
  const { data, error } = await supabaseAdmin
    .from('bookings')
    .insert(bookingData)
    .select()
    .single();
  return { data, error };
};

const getBookingById = async (bookingId) => {
  const { data, error } = await supabaseAdmin
    .from('bookings')
    .select('*, service_categories(name, description), profiles!customer_id(full_name, phone, fcm_token), workers(*, profiles!user_id(full_name, phone, fcm_token))')
    .eq('id', bookingId)
    .single();
  return { data, error };
};

const getBookingsByCustomer = async (customerId, page = 1, limit = 10) => {
  const from = (page - 1) * limit;
  const to = from + limit - 1;

  const { data, error, count } = await supabaseAdmin
    .from('bookings')
    .select('*, service_categories(name), workers(profiles!user_id(full_name))', { count: 'exact' })
    .eq('customer_id', customerId)
    .order('created_at', { ascending: false })
    .range(from, to);
  return { data, error, count };
};

const updateBookingStatus = async (bookingId, status, extra = {}) => {
  const updates = { status, ...extra, updated_at: new Date().toISOString() };

  if (status === 'in_progress') updates.checkin_at = new Date().toISOString();
  if (status === 'completed') updates.checkout_at = new Date().toISOString();
  if (status === 'cancelled') updates.cancelled_at = new Date().toISOString();

  const { data, error } = await supabaseAdmin
    .from('bookings')
    .update(updates)
    .eq('id', bookingId)
    .select()
    .single();
  return { data, error };
};

const assignWorkerToBooking = async (bookingId, workerId) => {
  const { data, error } = await supabaseAdmin
    .from('bookings')
    .update({ worker_id: workerId, status: 'assigned', assigned_at: new Date().toISOString() })
    .eq('id', bookingId)
    .select()
    .single();
  return { data, error };
};

const lockWorkerSlot = async (workerId, slotDate, slotStart, bookingId) => {
  const { data, error } = await supabaseAdmin
    .from('worker_slots')
    .update({ is_booked: true, booking_id: bookingId })
    .eq('worker_id', workerId)
    .eq('slot_date', slotDate)
    .eq('slot_start', slotStart)
    .select()
    .single();
  return { data, error };
};

const getAvailableWorkers = async (serviceCategoryId, slotDate, slotStart, pincode) => {
  const { data, error } = await supabaseAdmin
    .from('workers')
    .select('*, profiles!user_id(full_name, phone, avatar_url), worker_slots!inner(*)')
    .eq('is_approved', true)
    .eq('is_available', true)
    .contains('service_category_ids', [serviceCategoryId])
    .contains('service_pincodes', [pincode])
    .eq('worker_slots.slot_date', slotDate)
    .eq('worker_slots.slot_start', slotStart)
    .eq('worker_slots.is_booked', false);
  return { data, error };
};

// ───── Worker ─────
const getWorkerById = async (workerId) => {
  const { data, error } = await supabaseAdmin
    .from('workers')
    .select('*, profiles!user_id(full_name, phone, email, avatar_url, fcm_token)')
    .eq('id', workerId)
    .single();
  return { data, error };
};

const approveWorker = async (workerId) => {
  const { data, error } = await supabaseAdmin
    .from('workers')
    .update({ is_approved: true, bgv_status: 'approved', approved_at: new Date().toISOString() })
    .eq('id', workerId)
    .select('*, profiles!user_id(full_name, phone, fcm_token)')
    .single();
  return { data, error };
};

const rejectWorker = async (workerId, reason) => {
  const { data, error } = await supabaseAdmin
    .from('workers')
    .update({ bgv_status: 'rejected', bgv_notes: reason })
    .eq('id', workerId)
    .select()
    .single();
  return { data, error };
};

// ───── Payment ─────
const createPayment = async (paymentData) => {
  const { data, error } = await supabaseAdmin
    .from('payments')
    .insert(paymentData)
    .select()
    .single();
  return { data, error };
};

const updatePaymentStatus = async (paymentId, status, extra = {}) => {
  const { data, error } = await supabaseAdmin
    .from('payments')
    .update({ status, ...extra, updated_at: new Date().toISOString() })
    .eq('id', paymentId)
    .select()
    .single();
  return { data, error };
};

// ───── Payout ─────
const createPayout = async (payoutData) => {
  const { data, error } = await supabaseAdmin
    .from('payouts')
    .insert(payoutData)
    .select()
    .single();
  return { data, error };
};

const markPayoutPaid = async (payoutId, reference) => {
  const { data, error } = await supabaseAdmin
    .from('payouts')
    .update({ status: 'paid', payment_reference: reference, paid_at: new Date().toISOString() })
    .eq('id', payoutId)
    .select()
    .single();
  return { data, error };
};

// ───── Admin ─────
const logAdminAction = async (adminId, actionType, refType, refId, notes) => {
  const { data, error } = await supabaseAdmin
    .from('admin_actions_log')
    .insert({
      admin_id: adminId,
      action_type: actionType,
      ref_type: refType,
      ref_id: refId,
      notes
    })
    .select()
    .single();
  if (error) logger.error('Failed to log admin action', { error, adminId, actionType });
  return { data, error };
};

module.exports = {
  getProfile,
  updateProfile,
  getVendorByOwnerId,
  getVendorById,
  approveVendor,
  suspendVendor,
  getProductsByVendor,
  getProductById,
  decrementStock,
  createOrder,
  createOrderItems,
  getOrderById,
  getOrdersByCustomer,
  getOrdersByVendor,
  updateOrderStatus,
  createBooking,
  getBookingById,
  getBookingsByCustomer,
  updateBookingStatus,
  assignWorkerToBooking,
  lockWorkerSlot,
  getAvailableWorkers,
  getWorkerById,
  approveWorker,
  rejectWorker,
  createPayment,
  updatePaymentStatus,
  createPayout,
  markPayoutPaid,
  logAdminAction
};
