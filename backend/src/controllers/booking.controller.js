const { supabaseAdmin } = require('../config/supabase');
const razorpayService = require('../services/razorpay.service');
const slotService = require('../services/slot.service');
const { generateOTP } = require('../utils/crypto.util');
const { notificationQueue } = require('../queues/notification.queue');
const { bookingQueue } = require('../queues/booking.queue');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const createBooking = async (req, res, next) => {
  try {
    const { service_category_id, slot_date, slot_start, slot_end, service_address, customer_notes, payment_method } = req.body;

    // 1. Fetch service category pricing
    const { data: category } = await supabaseAdmin
      .from('service_categories')
      .select('*')
      .eq('id', service_category_id)
      .single();

    if (!category) {
      return errorResponse(res, 'Service category not found', 404);
    }

    // 2. Calculate pricing
    const quotedPrice = category.base_price;
    const bookingFee = 99;
    const platformCommission = Math.round(quotedPrice * 0.20 * 100) / 100;

    // 3. Create booking
    const { data: booking, error } = await supabaseAdmin
      .from('bookings')
      .insert({
        customer_id: req.user.id,
        service_category_id,
        slot_date,
        slot_start,
        slot_end,
        quoted_price: quotedPrice,
        booking_fee: bookingFee,
        platform_commission: platformCommission,
        payment_method,
        service_address,
        customer_notes,
        status: 'pending',
        checkin_otp: generateOTP(4)
      })
      .select()
      .single();

    if (error) {
      logger.error('Booking creation failed', { error, userId: req.user.id });
      return errorResponse(res, 'Failed to create booking', 400);
    }

    // 4. If not COD: create Razorpay order for booking fee
    let razorpayOrder = null;
    if (payment_method !== 'cod') {
      razorpayOrder = await razorpayService.createOrder({
        amount: bookingFee,
        receipt: booking.id,
        notes: { type: 'booking_fee', booking_id: booking.id }
      });

      await supabaseAdmin
        .from('bookings')
        .update({ razorpay_order_id: razorpayOrder.id })
        .eq('id', booking.id);
    }

    // 5. Alert admin
    await notificationQueue.add('new-booking-admin', { bookingId: booking.id });

    // 6. Schedule reminders
    const slotDateTime = new Date(`${slot_date}T${slot_start}:00+05:30`);
    const reminderDelay = slotDateTime.getTime() - Date.now() - 60 * 60 * 1000; // 1hr before
    if (reminderDelay > 0) {
      await bookingQueue.add('booking-reminder-customer', { bookingId: booking.id }, { delay: reminderDelay });
    }

    logger.info('Booking created', { bookingId: booking.id, userId: req.user.id });

    return successResponse(res, {
      booking,
      razorpay_order: razorpayOrder ? {
        id: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: 'INR'
      } : null
    }, 201, 'Booking created');
  } catch (err) {
    next(err);
  }
};

const getCustomerBookings = async (req, res, next) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('bookings')
      .select('*, service_categories(name, description), workers(profiles!user_id(full_name, phone))', { count: 'exact' })
      .eq('customer_id', req.user.id)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (status) query = query.eq('status', status);

    const { data, error, count } = await query;
    if (error) return errorResponse(res, 'Failed to fetch bookings', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getWorkerBookings = async (req, res, next) => {
  try {
    const { data: worker } = await supabaseAdmin
      .from('workers')
      .select('id')
      .eq('user_id', req.user.id)
      .single();

    if (!worker) return errorResponse(res, 'Worker not found', 404);

    const { page = 1, limit = 10, status } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('bookings')
      .select('*, service_categories(name), profiles!customer_id(full_name, phone)', { count: 'exact' })
      .eq('worker_id', worker.id)
      .order('slot_date', { ascending: false })
      .range(from, to);

    if (status) query = query.eq('status', status);

    const { data, error, count } = await query;
    if (error) return errorResponse(res, 'Failed to fetch bookings', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getWorkerSlots = async (req, res, next) => {
  try {
    const { data: worker } = await supabaseAdmin
      .from('workers')
      .select('id')
      .eq('user_id', req.user.id)
      .single();

    if (!worker) return errorResponse(res, 'Worker not found', 404);

    const { date } = req.query;
    let query = supabaseAdmin
      .from('worker_slots')
      .select('*')
      .eq('worker_id', worker.id)
      .order('slot_date', { ascending: true })
      .order('slot_start', { ascending: true });

    if (date) {
      query = query.eq('slot_date', date);
    } else {
      query = query.gte('slot_date', new Date().toISOString().split('T')[0]);
    }

    const { data, error } = await query;
    if (error) return errorResponse(res, 'Failed to fetch slots', 400);

    return successResponse(res, data || []);
  } catch (err) {
    next(err);
  }
};

const addWorkerSlots = async (req, res, next) => {
  try {
    const { data: worker } = await supabaseAdmin
      .from('workers')
      .select('id, is_approved')
      .eq('user_id', req.user.id)
      .single();

    if (!worker) return errorResponse(res, 'Worker not found', 404);
    if (!worker.is_approved) return errorResponse(res, 'Worker not yet approved', 403);

    const slotsToInsert = req.body.slots.map((s) => ({
      worker_id: worker.id,
      slot_date: s.slot_date,
      slot_start: s.slot_start,
      slot_end: s.slot_end,
      is_booked: false
    }));

    const { data, error } = await supabaseAdmin
      .from('worker_slots')
      .upsert(slotsToInsert, { onConflict: 'worker_id,slot_date,slot_start', ignoreDuplicates: true })
      .select();

    if (error) return errorResponse(res, 'Failed to add slots', 400);

    return successResponse(res, { added: data?.length || 0 }, 201, 'Slots added');
  } catch (err) {
    next(err);
  }
};

const deleteWorkerSlot = async (req, res, next) => {
  try {
    const { data: worker } = await supabaseAdmin
      .from('workers')
      .select('id')
      .eq('user_id', req.user.id)
      .single();

    if (!worker) return errorResponse(res, 'Worker not found', 404);

    const { error } = await supabaseAdmin
      .from('worker_slots')
      .delete()
      .eq('id', req.params.slotId)
      .eq('worker_id', worker.id)
      .eq('is_booked', false);

    if (error) return errorResponse(res, 'Failed to delete slot', 400);

    return successResponse(res, null, 200, 'Slot deleted');
  } catch (err) {
    next(err);
  }
};

const getBookingById = async (req, res, next) => {
  try {
    const { data: booking, error } = await supabaseAdmin
      .from('bookings')
      .select('*, service_categories(name, description), profiles!customer_id(full_name, phone), workers(*, profiles!user_id(full_name, phone, avatar_url))')
      .eq('id', req.params.id)
      .single();

    if (error || !booking) return errorResponse(res, 'Booking not found', 404);

    // Verify access
    const isCustomer = booking.customer_id === req.user.id;
    let isWorker = false;
    if (booking.worker_id) {
      const { data: worker } = await supabaseAdmin
        .from('workers')
        .select('user_id')
        .eq('id', booking.worker_id)
        .single();
      isWorker = worker?.user_id === req.user.id;
    }

    if (!isCustomer && !isWorker && req.user.role !== 'admin') {
      return errorResponse(res, 'Access denied', 403);
    }

    return successResponse(res, booking);
  } catch (err) {
    next(err);
  }
};

const updateBookingStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    const { data: booking } = await supabaseAdmin
      .from('bookings')
      .select('*, workers(user_id)')
      .eq('id', req.params.id)
      .single();

    if (!booking) return errorResponse(res, 'Booking not found', 404);

    if (booking.workers?.user_id !== req.user.id && req.user.role !== 'admin') {
      return errorResponse(res, 'Not authorized', 403);
    }

    const { data: updated, error } = await supabaseAdmin
      .from('bookings')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to update status', 400);

    await notificationQueue.add('booking-status-update', {
      bookingId: req.params.id,
      status
    });

    return successResponse(res, updated);
  } catch (err) {
    next(err);
  }
};

const cancelBooking = async (req, res, next) => {
  try {
    const { data: booking } = await supabaseAdmin
      .from('bookings')
      .select('*')
      .eq('id', req.params.id)
      .eq('customer_id', req.user.id)
      .single();

    if (!booking) return errorResponse(res, 'Booking not found', 404);

    if (!['pending', 'assigned'].includes(booking.status)) {
      return errorResponse(res, 'Cannot cancel booking in current status', 400);
    }

    // Release slot if worker assigned
    if (booking.worker_id) {
      await slotService.releaseSlotRedis(booking.worker_id, booking.slot_date, booking.slot_start);

      await supabaseAdmin
        .from('worker_slots')
        .update({ is_booked: false, booking_id: null })
        .eq('worker_id', booking.worker_id)
        .eq('slot_date', booking.slot_date)
        .eq('slot_start', booking.slot_start);
    }

    await supabaseAdmin
      .from('bookings')
      .update({
        status: 'cancelled',
        cancelled_by: 'customer',
        cancel_reason: req.body.cancel_reason || 'Cancelled by customer',
        cancelled_at: new Date().toISOString()
      })
      .eq('id', req.params.id);

    // Refund booking fee if paid
    let refundData = null;
    if (booking.payment_status === 'paid' && booking.razorpay_payment_id) {
      try {
        refundData = await require('../services/razorpay.service').createRefund(
          booking.razorpay_payment_id,
          booking.booking_fee
        );
      } catch (err) {
        logger.error('Booking refund failed', { error: err.message, bookingId: booking.id });
      }
    }

    await notificationQueue.add('booking-status-update', {
      bookingId: req.params.id,
      status: 'cancelled'
    });

    return successResponse(res, { message: 'Booking cancelled', refund: refundData });
  } catch (err) {
    next(err);
  }
};

const workerCheckin = async (req, res, next) => {
  try {
    const { otp } = req.body;

    const { data: worker } = await supabaseAdmin
      .from('workers')
      .select('id')
      .eq('user_id', req.user.id)
      .single();

    if (!worker) return errorResponse(res, 'Worker not found', 404);

    const { data: booking } = await supabaseAdmin
      .from('bookings')
      .select('*')
      .eq('id', req.params.id)
      .eq('worker_id', worker.id)
      .single();

    if (!booking) return errorResponse(res, 'Booking not found', 404);

    if (!['assigned', 'confirmed'].includes(booking.status)) {
      return errorResponse(res, 'Booking not ready for check-in', 400);
    }

    if (otp !== booking.checkin_otp) {
      return errorResponse(res, 'Invalid check-in OTP', 400);
    }

    const { error } = await supabaseAdmin
      .from('bookings')
      .update({ status: 'in_progress', checkin_at: new Date().toISOString() })
      .eq('id', req.params.id);

    if (error) return errorResponse(res, 'Failed to check in', 400);

    await notificationQueue.add('booking-status-update', {
      bookingId: req.params.id,
      status: 'in_progress'
    });

    return successResponse(res, { success: true });
  } catch (err) {
    next(err);
  }
};

const workerCheckout = async (req, res, next) => {
  try {
    const { worker_notes, final_price } = req.body;

    const { data: worker } = await supabaseAdmin
      .from('workers')
      .select('id')
      .eq('user_id', req.user.id)
      .single();

    if (!worker) return errorResponse(res, 'Worker not found', 404);

    const { data: booking } = await supabaseAdmin
      .from('bookings')
      .select('*')
      .eq('id', req.params.id)
      .eq('worker_id', worker.id)
      .single();

    if (!booking) return errorResponse(res, 'Booking not found', 404);
    if (booking.status !== 'in_progress') return errorResponse(res, 'Booking not in progress', 400);

    const actualPrice = final_price || booking.quoted_price;

    const { data: updated, error } = await supabaseAdmin
      .from('bookings')
      .update({
        status: 'completed',
        checkout_at: new Date().toISOString(),
        worker_notes,
        final_price: actualPrice
      })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to check out', 400);

    // Increment worker stats
    await supabaseAdmin.rpc('increment_worker_jobs', { p_worker_id: worker.id });

    // Queue rating reminder
    await notificationQueue.add('rating-reminder', {
      customerId: booking.customer_id,
      type: 'booking',
      refId: booking.id
    }, { delay: 30 * 60 * 1000 });

    // Queue payout calculation
    await bookingQueue.add('payout-calculation', { bookingId: booking.id });

    await notificationQueue.add('booking-status-update', {
      bookingId: req.params.id,
      status: 'completed'
    });

    const earnings = Math.round(actualPrice * 0.80 * 100) / 100;
    return successResponse(res, { booking: updated, earnings });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createBooking,
  getCustomerBookings,
  getWorkerBookings,
  getWorkerSlots,
  addWorkerSlots,
  deleteWorkerSlot,
  getBookingById,
  updateBookingStatus,
  cancelBooking,
  workerCheckin,
  workerCheckout
};
