const { supabaseAdmin } = require('../config/supabase');
const razorpayService = require('../services/razorpay.service');
const phonePeService = require('../services/phonepe.service');
const { notificationQueue } = require('../queues/notification.queue');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

const getRefRecord = async (refType, refId) => {
  const table = refType === 'order' ? 'orders' : 'bookings';
  const { data, error } = await supabaseAdmin
    .from(table)
    .select('*')
    .eq('id', refId)
    .single();
  return { data, error };
};

const razorpayCreateOrder = async (req, res, next) => {
  try {
    const { ref_type, ref_id } = req.body;

    const { data: record, error } = await getRefRecord(ref_type, ref_id);
    if (error || !record) {
      return errorResponse(res, `${ref_type} not found`, 404);
    }

    const amount = ref_type === 'order' ? record.final_amount : record.booking_fee || record.quoted_price;

    const razorpayOrder = await razorpayService.createOrder({
      amount,
      receipt: ref_id,
      notes: { ref_type, ref_id }
    });

    // Update record with razorpay order ID
    const table = ref_type === 'order' ? 'orders' : 'bookings';
    await supabaseAdmin
      .from(table)
      .update({ razorpay_order_id: razorpayOrder.id })
      .eq('id', ref_id);

    // Log payment
    await supabaseAdmin.from('payments').insert({
      ref_type,
      ref_id,
      gateway: 'razorpay',
      gateway_order_id: razorpayOrder.id,
      amount,
      currency: 'INR',
      status: 'pending'
    });

    return successResponse(res, {
      razorpay_order_id: razorpayOrder.id,
      razorpay_key_id: process.env.RAZORPAY_KEY_ID,
      amount: razorpayOrder.amount,
      currency: 'INR',
      name: 'FreshKart',
      description: `Payment for ${ref_type} ${ref_id.slice(0, 8)}`
    });
  } catch (err) {
    next(err);
  }
};

const razorpayVerify = async (req, res, next) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, ref_type, ref_id } = req.body;

    const { valid } = razorpayService.verifyPayment({
      orderId: razorpay_order_id,
      paymentId: razorpay_payment_id,
      signature: razorpay_signature
    });

    // Update payment record
    const paymentUpdate = valid
      ? { status: 'success', gateway_payment_id: razorpay_payment_id }
      : { status: 'failed' };

    await supabaseAdmin
      .from('payments')
      .update(paymentUpdate)
      .eq('gateway_order_id', razorpay_order_id);

    if (!valid) {
      return errorResponse(res, 'Payment verification failed', 400);
    }

    // Update order/booking payment status
    const table = ref_type === 'order' ? 'orders' : 'bookings';
    await supabaseAdmin
      .from(table)
      .update({
        payment_status: 'paid',
        razorpay_payment_id
      })
      .eq('id', ref_id);

    // Queue notification
    const notifType = ref_type === 'order' ? 'order-status-update' : 'booking-status-update';
    const notifData = ref_type === 'order'
      ? { orderId: ref_id, status: 'payment_confirmed' }
      : { bookingId: ref_id, status: 'payment_confirmed' };

    await notificationQueue.add(notifType, notifData);

    logger.info('Payment verified', { ref_type, ref_id, razorpay_payment_id });

    return successResponse(res, { success: true, ref_type, ref_id });
  } catch (err) {
    next(err);
  }
};

const phonePeInitiate = async (req, res, next) => {
  try {
    const { ref_type, ref_id, customer_phone, redirect_url, callback_url } = req.body;

    const { data: record, error } = await getRefRecord(ref_type, ref_id);
    if (error || !record) {
      return errorResponse(res, `${ref_type} not found`, 404);
    }

    const amount = ref_type === 'order' ? record.final_amount : record.booking_fee || record.quoted_price;

    const result = await phonePeService.initiatePayment({
      orderId: ref_id,
      amount,
      customerPhone: customer_phone,
      redirectUrl: redirect_url,
      callbackUrl: callback_url
    });

    // Log payment
    await supabaseAdmin.from('payments').insert({
      ref_type,
      ref_id,
      gateway: 'phonepe',
      gateway_order_id: ref_id,
      amount,
      currency: 'INR',
      status: 'pending'
    });

    return successResponse(res, {
      redirect_url: result.redirectUrl,
      transaction_id: result.transactionId
    });
  } catch (err) {
    next(err);
  }
};

const phonePeStatus = async (req, res, next) => {
  try {
    const { transactionId } = req.params;

    const result = await phonePeService.verifyPayment(transactionId);

    // Update payment status
    const status = result.success ? 'success' : 'failed';
    await supabaseAdmin
      .from('payments')
      .update({ status })
      .eq('gateway_order_id', transactionId);

    if (result.success) {
      // Try to find and update the order/booking
      const { data: payment } = await supabaseAdmin
        .from('payments')
        .select('ref_type, ref_id')
        .eq('gateway_order_id', transactionId)
        .single();

      if (payment) {
        const table = payment.ref_type === 'order' ? 'orders' : 'bookings';
        await supabaseAdmin
          .from(table)
          .update({ payment_status: 'paid' })
          .eq('id', payment.ref_id);
      }
    }

    return successResponse(res, {
      status: result.status,
      amount: result.amount,
      transaction_id: transactionId
    });
  } catch (err) {
    next(err);
  }
};

const initiateRefund = async (req, res, next) => {
  try {
    const { ref_type, ref_id, amount, reason } = req.body;

    const { data: record, error } = await getRefRecord(ref_type, ref_id);
    if (error || !record) {
      return errorResponse(res, `${ref_type} not found`, 404);
    }

    // Verify ownership or admin
    if (req.user.role !== 'admin' && record.customer_id !== req.user.id) {
      return errorResponse(res, 'Not authorized', 403);
    }

    const originalAmount = ref_type === 'order' ? record.final_amount : record.quoted_price;
    if (amount > originalAmount) {
      return errorResponse(res, 'Refund amount exceeds original amount', 400);
    }

    if (!record.razorpay_payment_id) {
      return errorResponse(res, 'No payment found for this record', 400);
    }

    const refund = await razorpayService.createRefund(
      record.razorpay_payment_id,
      amount,
      { reason: reason || 'Refund requested', ref_type, ref_id }
    );

    // Update payment record
    await supabaseAdmin
      .from('payments')
      .update({ refund_id: refund.id, refund_amount: amount })
      .eq('ref_id', ref_id);

    // Update order/booking
    const table = ref_type === 'order' ? 'orders' : 'bookings';
    await supabaseAdmin
      .from(table)
      .update({ payment_status: 'refunded' })
      .eq('id', ref_id);

    if (req.user.role === 'admin') {
      await supabaseAdmin.from('admin_actions_log').insert({
        admin_id: req.user.id,
        action_type: 'refund_initiated',
        ref_type,
        ref_id,
        notes: `Refund of ₹${amount}. ${reason || ''}`
      });
    }

    return successResponse(res, { refund_id: refund.id, amount, status: refund.status });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  razorpayCreateOrder,
  razorpayVerify,
  phonePeInitiate,
  phonePeStatus,
  initiateRefund
};
