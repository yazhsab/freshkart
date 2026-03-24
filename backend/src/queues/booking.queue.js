const { Queue, Worker } = require('bullmq');
const { connection, defaultJobOptions } = require('./queue.config');
const { supabaseAdmin } = require('../config/supabase');
const fcmService = require('../services/fcm.service');
const smsService = require('../services/sms.service');
const logger = require('../utils/logger');

const bookingQueue = new Queue('bookings', {
  connection,
  defaultJobOptions
});

const bookingWorker = new Worker('bookings', async (job) => {
  const { name, data } = job;

  try {
    switch (name) {
      case 'booking-reminder-customer': {
        const { data: booking } = await supabaseAdmin
          .from('bookings')
          .select('id, booking_number, slot_date, slot_start, status, service_categories(name), profiles!customer_id(full_name, phone, fcm_token), workers(profiles!user_id(full_name))')
          .eq('id', data.bookingId)
          .single();

        if (booking && ['assigned', 'confirmed'].includes(booking.status)) {
          if (booking.profiles?.fcm_token) {
            await fcmService.sendToToken(booking.profiles.fcm_token, {
              title: 'Booking Reminder',
              body: `Your ${booking.service_categories?.name} service is scheduled for ${booking.slot_start} today.`,
              data: { type: 'booking_reminder', bookingId: booking.id }
            });
          }

          if (booking.profiles?.phone) {
            await smsService.sendBookingSMS(booking.profiles.phone, {
              customerName: booking.profiles.full_name,
              bookingNumber: booking.booking_number,
              serviceName: booking.service_categories?.name,
              slotDate: booking.slot_date,
              workerName: booking.workers?.profiles?.full_name || 'Assigned worker'
            });
          }
        }
        break;
      }

      case 'booking-reminder-worker': {
        const { data: booking } = await supabaseAdmin
          .from('bookings')
          .select('id, booking_number, slot_date, slot_start, service_address, status, service_categories(name), profiles!customer_id(full_name, phone), workers(user_id, profiles!user_id(fcm_token))')
          .eq('id', data.bookingId)
          .single();

        if (booking && ['assigned', 'confirmed'].includes(booking.status)) {
          if (booking.workers?.profiles?.fcm_token) {
            await fcmService.sendToToken(booking.workers.profiles.fcm_token, {
              title: 'Upcoming Service',
              body: `${booking.service_categories?.name} at ${booking.slot_start}. Customer: ${booking.profiles?.full_name}`,
              data: {
                type: 'booking_reminder',
                bookingId: booking.id,
                customerAddress: JSON.stringify(booking.service_address)
              }
            });
          }
        }
        break;
      }

      case 'payout-calculation': {
        const { data: booking } = await supabaseAdmin
          .from('bookings')
          .select('worker_id, final_price, booking_fee')
          .eq('id', data.bookingId)
          .single();

        if (booking?.worker_id) {
          const earnings = (booking.final_price || 0) * 0.80;
          logger.info('Worker payout calculated', {
            bookingId: data.bookingId,
            workerId: booking.worker_id,
            earnings
          });
        }
        break;
      }

      default:
        logger.warn('Unknown booking job', { name });
    }
  } catch (err) {
    logger.error('Booking queue job failed', { name, error: err.message, data });
    throw err;
  }
}, { connection, concurrency: 3 });

bookingWorker.on('failed', (job, err) => {
  logger.error('Booking job failed', { jobId: job?.id, name: job?.name, error: err.message });
});

module.exports = { bookingQueue, bookingWorker };
