const { fcm } = require('../config/firebase');
const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

const sendToToken = async (token, { title, body, data = {}, imageUrl }) => {
  if (!fcm) {
    logger.warn('FCM not initialized, skipping push notification');
    return { success: false, error: 'FCM not initialized' };
  }

  if (!token) {
    logger.warn('No FCM token provided, skipping notification');
    return { success: false, error: 'No token' };
  }

  try {
    const message = {
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'freshkart_default'
        }
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 }
        }
      }
    };

    if (imageUrl) {
      message.notification.imageUrl = imageUrl;
    }

    const response = await fcm.send(message);
    logger.info('FCM sent', { title, token: token.slice(0, 10) + '...' });
    return { success: true, messageId: response };
  } catch (err) {
    if (err.code === 'messaging/registration-token-not-registered' ||
        err.code === 'messaging/invalid-registration-token') {
      logger.warn('Invalid FCM token, removing', { token: token.slice(0, 10) + '...' });
      await supabaseAdmin
        .from('profiles')
        .update({ fcm_token: null })
        .eq('fcm_token', token);
    } else {
      logger.error('FCM send failed', { error: err.message, title });
    }
    return { success: false, error: err.message };
  }
};

const sendToMultiple = async (tokens, { title, body, data = {}, imageUrl }) => {
  if (!fcm || !tokens.length) {
    return { successCount: 0, failureCount: 0, failedTokens: [] };
  }

  const validTokens = tokens.filter(Boolean);
  const results = { successCount: 0, failureCount: 0, failedTokens: [] };

  // Batch in groups of 500
  for (let i = 0; i < validTokens.length; i += 500) {
    const batch = validTokens.slice(i, i + 500);

    try {
      const message = {
        tokens: batch,
        notification: { title, body },
        data: Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
        android: {
          priority: 'high',
          notification: { sound: 'default', channelId: 'freshkart_default' }
        },
        apns: {
          payload: { aps: { sound: 'default' } }
        }
      };

      if (imageUrl) message.notification.imageUrl = imageUrl;

      const response = await fcm.sendEachForMulticast(message);
      results.successCount += response.successCount;
      results.failureCount += response.failureCount;

      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          results.failedTokens.push(batch[idx]);
        }
      });
    } catch (err) {
      logger.error('FCM multicast failed', { error: err.message, batchSize: batch.length });
      results.failureCount += batch.length;
    }
  }

  logger.info('FCM multicast results', {
    successCount: results.successCount,
    failureCount: results.failureCount
  });

  return results;
};

const sendOrderNotification = async (orderId, status) => {
  const { data: order } = await supabaseAdmin
    .from('orders')
    .select('*, profiles!customer_id(full_name, fcm_token), vendors(shop_name)')
    .eq('id', orderId)
    .single();

  if (!order) return;

  const notifications = {
    confirmed: { title: 'Order Confirmed!', body: `Your order from ${order.vendors?.shop_name} is being prepared.` },
    packing: { title: 'Packing in Progress', body: 'Your items are being packed carefully.' },
    picked_up: { title: 'On the Way!', body: 'Delivery partner picked up your order.' },
    delivered: { title: 'Delivered!', body: 'Your order has been delivered. Enjoy!' },
    cancelled: { title: 'Order Cancelled', body: order.cancel_reason || 'Your order has been cancelled.' }
  };

  const notif = notifications[status];
  if (!notif) return;

  // Notify customer
  if (order.profiles?.fcm_token) {
    await sendToToken(order.profiles.fcm_token, {
      ...notif,
      data: { type: 'order_update', orderId, status }
    });
  }

  // Notify agent if assigned and relevant
  if (order.delivery_agent_id && ['confirmed', 'cancelled'].includes(status)) {
    const { data: agentProfile } = await supabaseAdmin
      .from('profiles')
      .select('fcm_token')
      .eq('id', order.delivery_agent_id)
      .single();

    if (agentProfile?.fcm_token) {
      await sendToToken(agentProfile.fcm_token, {
        title: `Order ${status}`,
        body: `Order #${order.order_number} has been ${status}.`,
        data: { type: 'order_update', orderId, status }
      });
    }
  }
};

const sendBookingNotification = async (bookingId, status) => {
  const { data: booking } = await supabaseAdmin
    .from('bookings')
    .select('*, profiles!customer_id(full_name, fcm_token), workers(profiles!user_id(full_name, fcm_token)), service_categories(name)')
    .eq('id', bookingId)
    .single();

  if (!booking) return;

  const workerName = booking.workers?.profiles?.full_name || 'Your worker';
  const notifications = {
    assigned: {
      customer: { title: 'Worker Assigned!', body: `${workerName} will handle your ${booking.service_categories?.name} service.` },
      worker: { title: 'New Assignment', body: `You have a new ${booking.service_categories?.name} booking.` }
    },
    worker_on_way: {
      customer: { title: 'Worker on the Way!', body: `${workerName} is heading to your location.` }
    },
    in_progress: {
      customer: { title: 'Service Started', body: `${workerName} has checked in and started the service.` }
    },
    completed: {
      customer: { title: 'Service Completed!', body: 'Rate your experience to help us improve.' }
    },
    cancelled: {
      customer: { title: 'Booking Cancelled', body: booking.cancel_reason || 'Your booking has been cancelled.' },
      worker: { title: 'Booking Cancelled', body: `Booking for ${booking.service_categories?.name} has been cancelled.` }
    }
  };

  const notif = notifications[status];
  if (!notif) return;

  if (notif.customer && booking.profiles?.fcm_token) {
    await sendToToken(booking.profiles.fcm_token, {
      ...notif.customer,
      data: { type: 'booking_update', bookingId, status }
    });
  }

  if (notif.worker && booking.workers?.profiles?.fcm_token) {
    await sendToToken(booking.workers.profiles.fcm_token, {
      ...notif.worker,
      data: { type: 'booking_update', bookingId, status }
    });
  }
};

const sendToVendor = async (vendorId, notification) => {
  const { data: vendor } = await supabaseAdmin
    .from('vendors')
    .select('profiles!owner_id(fcm_token)')
    .eq('id', vendorId)
    .single();

  if (vendor?.profiles?.fcm_token) {
    return sendToToken(vendor.profiles.fcm_token, notification);
  }
  return { success: false, error: 'No vendor token' };
};

const sendBulkByRole = async (role, notification) => {
  const { data: profiles } = await supabaseAdmin
    .from('profiles')
    .select('fcm_token')
    .eq('role', role)
    .not('fcm_token', 'is', null);

  if (!profiles?.length) return { successCount: 0, failureCount: 0 };

  const tokens = profiles.map((p) => p.fcm_token);
  return sendToMultiple(tokens, notification);
};

module.exports = {
  sendToToken,
  sendToMultiple,
  sendOrderNotification,
  sendBookingNotification,
  sendToVendor,
  sendBulkByRole
};
