const cron = require('node-cron');
const { supabaseAdmin } = require('../config/supabase');
const { notificationQueue } = require('../queues/notification.queue');
const { orderQueue } = require('../queues/order.queue');
const logger = require('../utils/logger');

const startScheduledOrderCron = () => {
  // Run every 5 minutes
  cron.schedule('*/5 * * * *', async () => {
    try {
      const now = new Date().toISOString();

      // Find scheduled orders that should be activated
      const { data: orders, error } = await supabaseAdmin
        .from('orders')
        .select('id, order_number, customer_id, vendor_id')
        .eq('status', 'pending_scheduled')
        .eq('is_scheduled', true)
        .lte('scheduled_at', now);

      if (error || !orders?.length) return;

      logger.info(`Processing ${orders.length} scheduled orders`);

      for (const order of orders) {
        // Transition to pending
        await supabaseAdmin
          .from('orders')
          .update({ status: 'pending' })
          .eq('id', order.id);

        // Queue vendor notification
        await notificationQueue.add('new-order-vendor', { orderId: order.id });

        // Queue auto-confirm
        await orderQueue.add('auto-confirm-vendor', { orderId: order.id }, { delay: 60000 });

        logger.info('Scheduled order activated', { orderId: order.id, orderNumber: order.order_number });
      }
    } catch (err) {
      logger.error('Scheduled order cron error', { error: err.message });
    }
  });

  logger.info('Scheduled order cron started (every 5 minutes)');
};

module.exports = { startScheduledOrderCron };
