const cron = require('node-cron');
const { supabaseAdmin } = require('../config/supabase');
const { notificationQueue } = require('../queues/notification.queue');
const logger = require('../utils/logger');

const AUTO_CONFIRM_SECONDS = 60;

const startAutoConfirmCron = () => {
  // Run every 30 seconds
  cron.schedule('*/30 * * * * *', async () => {
    try {
      const cutoff = new Date(Date.now() - AUTO_CONFIRM_SECONDS * 1000).toISOString();

      const { data: orders, error } = await supabaseAdmin
        .from('orders')
        .select('id, order_number, customer_id')
        .eq('status', 'pending')
        .lt('created_at', cutoff)
        .limit(50);

      if (error) {
        logger.error('Auto-confirm cron query failed', { error });
        return;
      }

      if (!orders?.length) return;

      for (const order of orders) {
        await supabaseAdmin
          .from('orders')
          .update({
            status: 'confirmed',
            confirmed_at: new Date().toISOString()
          })
          .eq('id', order.id)
          .eq('status', 'pending'); // Ensure still pending (idempotent)

        await notificationQueue.add('order-status-update', {
          orderId: order.id,
          status: 'confirmed'
        });
      }

      if (orders.length > 0) {
        logger.info('Auto-confirmed orders', { count: orders.length });
      }
    } catch (err) {
      logger.error('Auto-confirm cron failed', { error: err.message });
    }
  });

  logger.info('Auto-confirm cron started (every 30s)');
};

module.exports = { startAutoConfirmCron };
