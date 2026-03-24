const { supabaseAdmin } = require('../config/supabase');
const { verifyRazorpayWebhookSignature } = require('../utils/crypto.util');
const phonePeService = require('../services/phonepe.service');
const slotService = require('../services/slot.service');
const { notificationQueue } = require('../queues/notification.queue');
const logger = require('../utils/logger');

const razorpayWebhook = async (req, res) => {
  try {
    const signature = req.headers['x-razorpay-signature'];
    const rawBody = typeof req.body === 'string' ? req.body : req.body.toString('utf8');

    const isValid = verifyRazorpayWebhookSignature(rawBody, signature);
    if (!isValid) {
      logger.warn('Razorpay webhook signature verification failed');
      return res.status(200).json({ status: 'signature_invalid' });
    }

    const event = JSON.parse(rawBody);
    const eventType = event.event;
    const payload = event.payload;

    logger.info('Razorpay webhook received', { event: eventType });

    switch (eventType) {
      case 'payment.captured': {
        const payment = payload.payment?.entity;
        if (!payment) break;

        const razorpayOrderId = payment.order_id;

        // Find our payment record
        const { data: paymentRecord } = await supabaseAdmin
          .from('payments')
          .select('ref_type, ref_id')
          .eq('gateway_order_id', razorpayOrderId)
          .single();

        if (paymentRecord) {
          // Update payment record
          await supabaseAdmin
            .from('payments')
            .update({
              status: 'success',
              gateway_payment_id: payment.id,
              updated_at: new Date().toISOString()
            })
            .eq('gateway_order_id', razorpayOrderId);

          // Update order/booking
          const table = paymentRecord.ref_type === 'order' ? 'orders' : 'bookings';
          await supabaseAdmin
            .from(table)
            .update({
              payment_status: 'paid',
              razorpay_payment_id: payment.id
            })
            .eq('id', paymentRecord.ref_id);

          // Queue notification
          const queueName = paymentRecord.ref_type === 'order' ? 'order-status-update' : 'booking-status-update';
          const queueData = paymentRecord.ref_type === 'order'
            ? { orderId: paymentRecord.ref_id, status: 'payment_confirmed' }
            : { bookingId: paymentRecord.ref_id, status: 'payment_confirmed' };

          await notificationQueue.add(queueName, queueData);
        }
        break;
      }

      case 'payment.failed': {
        const payment = payload.payment?.entity;
        if (!payment) break;

        const razorpayOrderId = payment.order_id;

        const { data: paymentRecord } = await supabaseAdmin
          .from('payments')
          .select('ref_type, ref_id')
          .eq('gateway_order_id', razorpayOrderId)
          .single();

        if (paymentRecord) {
          await supabaseAdmin
            .from('payments')
            .update({ status: 'failed', updated_at: new Date().toISOString() })
            .eq('gateway_order_id', razorpayOrderId);

          // Restore stock for orders
          if (paymentRecord.ref_type === 'order') {
            const { data: order } = await supabaseAdmin
              .from('orders')
              .select('id, order_items(*)')
              .eq('id', paymentRecord.ref_id)
              .single();

            if (order) {
              for (const item of (order.order_items || [])) {
                await supabaseAdmin.rpc('increment_stock', {
                  p_product_id: item.product_id,
                  p_quantity: item.quantity
                });
              }
              await supabaseAdmin
                .from('orders')
                .update({ payment_status: 'failed', status: 'cancelled', cancel_reason: 'Payment failed' })
                .eq('id', paymentRecord.ref_id);
            }
          }

          // Release slot lock for bookings
          if (paymentRecord.ref_type === 'booking') {
            const { data: booking } = await supabaseAdmin
              .from('bookings')
              .select('worker_id, slot_date, slot_start')
              .eq('id', paymentRecord.ref_id)
              .single();

            if (booking?.worker_id) {
              await slotService.releaseSlotRedis(booking.worker_id, booking.slot_date, booking.slot_start);
            }

            await supabaseAdmin
              .from('bookings')
              .update({ payment_status: 'failed', status: 'cancelled', cancel_reason: 'Payment failed' })
              .eq('id', paymentRecord.ref_id);
          }
        }
        break;
      }

      case 'refund.processed': {
        const refund = payload.refund?.entity;
        if (!refund) break;

        await supabaseAdmin
          .from('payments')
          .update({
            refund_id: refund.id,
            refund_amount: refund.amount / 100,
            updated_at: new Date().toISOString()
          })
          .eq('gateway_payment_id', refund.payment_id);

        break;
      }

      default:
        logger.info('Unhandled Razorpay webhook event', { event: eventType });
    }

    return res.status(200).json({ status: 'ok' });
  } catch (err) {
    logger.error('Razorpay webhook error', { error: err.message });
    return res.status(200).json({ status: 'error_logged' });
  }
};

const phonePeWebhook = async (req, res) => {
  try {
    const xVerify = req.headers['x-verify'];
    const rawBody = typeof req.body === 'string' ? req.body : req.body.toString('utf8');
    const body = JSON.parse(rawBody);

    const isValid = phonePeService.verifyCallback(xVerify, body);
    if (!isValid) {
      logger.warn('PhonePe webhook signature verification failed');
      return res.status(200).json({ status: 'signature_invalid' });
    }

    const response = body.response ? JSON.parse(Buffer.from(body.response, 'base64').toString('utf8')) : body;
    const code = response.code;
    const merchantTransactionId = response.data?.merchantTransactionId;

    logger.info('PhonePe webhook received', { code, merchantTransactionId });

    if (code === 'PAYMENT_SUCCESS' && merchantTransactionId) {
      // Find payment record
      const { data: paymentRecord } = await supabaseAdmin
        .from('payments')
        .select('ref_type, ref_id')
        .eq('gateway_order_id', merchantTransactionId)
        .single();

      if (paymentRecord) {
        await supabaseAdmin
          .from('payments')
          .update({ status: 'success', updated_at: new Date().toISOString() })
          .eq('gateway_order_id', merchantTransactionId);

        const table = paymentRecord.ref_type === 'order' ? 'orders' : 'bookings';
        await supabaseAdmin
          .from(table)
          .update({ payment_status: 'paid' })
          .eq('id', paymentRecord.ref_id);

        const queueName = paymentRecord.ref_type === 'order' ? 'order-status-update' : 'booking-status-update';
        const queueData = paymentRecord.ref_type === 'order'
          ? { orderId: paymentRecord.ref_id, status: 'payment_confirmed' }
          : { bookingId: paymentRecord.ref_id, status: 'payment_confirmed' };

        await notificationQueue.add(queueName, queueData);
      }
    } else if (code && (code.includes('FAIL') || code.includes('ERROR'))) {
      if (merchantTransactionId) {
        const { data: paymentRecord } = await supabaseAdmin
          .from('payments')
          .select('ref_type, ref_id')
          .eq('gateway_order_id', merchantTransactionId)
          .single();

        if (paymentRecord) {
          await supabaseAdmin
            .from('payments')
            .update({ status: 'failed', updated_at: new Date().toISOString() })
            .eq('gateway_order_id', merchantTransactionId);

          if (paymentRecord.ref_type === 'order') {
            const { data: order } = await supabaseAdmin
              .from('orders')
              .select('id, order_items(*)')
              .eq('id', paymentRecord.ref_id)
              .single();

            if (order) {
              for (const item of (order.order_items || [])) {
                await supabaseAdmin.rpc('increment_stock', { p_product_id: item.product_id, p_quantity: item.quantity });
              }
            }
          }

          if (paymentRecord.ref_type === 'booking') {
            const { data: booking } = await supabaseAdmin
              .from('bookings')
              .select('worker_id, slot_date, slot_start')
              .eq('id', paymentRecord.ref_id)
              .single();

            if (booking?.worker_id) {
              await slotService.releaseSlotRedis(booking.worker_id, booking.slot_date, booking.slot_start);
            }
          }
        }
      }
    }

    return res.status(200).json({ status: 'ok' });
  } catch (err) {
    logger.error('PhonePe webhook error', { error: err.message });
    return res.status(200).json({ status: 'error_logged' });
  }
};

module.exports = {
  razorpayWebhook,
  phonePeWebhook
};
