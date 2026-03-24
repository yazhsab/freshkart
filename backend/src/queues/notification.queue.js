const { Queue, Worker } = require('bullmq');
const { connection, defaultJobOptions } = require('./queue.config');
const fcmService = require('../services/fcm.service');
const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

const notificationQueue = new Queue('notifications', {
  connection,
  defaultJobOptions
});

const notificationWorker = new Worker('notifications', async (job) => {
  const { name, data } = job;

  try {
    switch (name) {
      case 'new-order-vendor': {
        const { data: order } = await supabaseAdmin
          .from('orders')
          .select('order_number, final_amount, vendors(owner_id, shop_name, profiles!owner_id(fcm_token))')
          .eq('id', data.orderId)
          .single();

        if (order?.vendors?.profiles?.fcm_token) {
          await fcmService.sendToToken(order.vendors.profiles.fcm_token, {
            title: 'New Order Received!',
            body: `Order #${order.order_number} — ₹${order.final_amount}`,
            data: { type: 'new_order', orderId: data.orderId }
          });
        }
        break;
      }

      case 'order-status-update': {
        await fcmService.sendOrderNotification(data.orderId, data.status);
        break;
      }

      case 'new-booking-admin': {
        const { data: admins } = await supabaseAdmin
          .from('profiles')
          .select('fcm_token')
          .eq('role', 'admin')
          .not('fcm_token', 'is', null);

        const { data: booking } = await supabaseAdmin
          .from('bookings')
          .select('booking_number, service_categories(name)')
          .eq('id', data.bookingId)
          .single();

        if (admins?.length && booking) {
          const tokens = admins.map((a) => a.fcm_token);
          await fcmService.sendToMultiple(tokens, {
            title: 'New Booking Needs Assignment',
            body: `Booking #${booking.booking_number} — ${booking.service_categories?.name}`,
            data: { type: 'new_booking', bookingId: data.bookingId }
          });
        }
        break;
      }

      case 'booking-status-update': {
        await fcmService.sendBookingNotification(data.bookingId, data.status);
        break;
      }

      case 'rating-reminder': {
        const { data: profile } = await supabaseAdmin
          .from('profiles')
          .select('fcm_token')
          .eq('id', data.customerId)
          .single();

        if (profile?.fcm_token) {
          const title = data.type === 'order'
            ? 'How was your order?'
            : 'How was the service?';
          await fcmService.sendToToken(profile.fcm_token, {
            title,
            body: 'Rate your experience to help us improve!',
            data: { type: 'rating_reminder', refType: data.type, refId: data.refId }
          });
        }
        break;
      }

      default:
        logger.warn('Unknown notification job', { name });
    }
  } catch (err) {
    logger.error('Notification queue job failed', { name, error: err.message, data });
    throw err;
  }
}, { connection, concurrency: 5 });

notificationWorker.on('failed', (job, err) => {
  logger.error('Notification job failed', { jobId: job?.id, name: job?.name, error: err.message });
});

module.exports = { notificationQueue, notificationWorker };
