const { Queue, Worker } = require('bullmq');
const { connection, defaultJobOptions } = require('./queue.config');
const { supabaseAdmin } = require('../config/supabase');
const fcmService = require('../services/fcm.service');
const logger = require('../utils/logger');

const orderQueue = new Queue('orders', {
  connection,
  defaultJobOptions
});

const orderWorker = new Worker('orders', async (job) => {
  const { name, data } = job;

  try {
    switch (name) {
      case 'auto-confirm-vendor': {
        // Check if order is still pending before auto-confirming
        const { data: order } = await supabaseAdmin
          .from('orders')
          .select('id, status, customer_id, order_number, profiles!customer_id(fcm_token)')
          .eq('id', data.orderId)
          .single();

        if (order && order.status === 'pending') {
          await supabaseAdmin
            .from('orders')
            .update({ status: 'confirmed', confirmed_at: new Date().toISOString() })
            .eq('id', data.orderId);

          if (order.profiles?.fcm_token) {
            await fcmService.sendToToken(order.profiles.fcm_token, {
              title: 'Order Confirmed!',
              body: `Your order #${order.order_number} has been confirmed.`,
              data: { type: 'order_update', orderId: data.orderId, status: 'confirmed' }
            });
          }

          logger.info('Order auto-confirmed', { orderId: data.orderId });
        }
        break;
      }

      case 'low-stock-alert': {
        const { data: product } = await supabaseAdmin
          .from('products')
          .select('id, name, stock_quantity, low_stock_threshold, vendor_id, vendors(owner_id, profiles!owner_id(fcm_token))')
          .eq('id', data.productId)
          .single();

        if (product && product.stock_quantity <= product.low_stock_threshold) {
          if (product.vendors?.profiles?.fcm_token) {
            await fcmService.sendToToken(product.vendors.profiles.fcm_token, {
              title: 'Low Stock Alert',
              body: `${product.name} is running low (${product.stock_quantity} left)`,
              data: { type: 'low_stock', productId: product.id }
            });
          }

          await supabaseAdmin.from('notifications_log').insert({
            user_id: product.vendors?.owner_id,
            type: 'low_stock',
            title: 'Low Stock Alert',
            body: `${product.name} has only ${product.stock_quantity} units left`,
            ref_type: 'product',
            ref_id: product.id
          });
        }
        break;
      }

      default:
        logger.warn('Unknown order job', { name });
    }
  } catch (err) {
    logger.error('Order queue job failed', { name, error: err.message, data });
    throw err;
  }
}, { connection, concurrency: 3 });

orderWorker.on('failed', (job, err) => {
  logger.error('Order job failed', { jobId: job?.id, name: job?.name, error: err.message });
});

module.exports = { orderQueue, orderWorker };
