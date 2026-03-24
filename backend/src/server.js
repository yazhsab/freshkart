require('dotenv').config();
const app = require('./app');
const logger = require('./utils/logger');
const { redis } = require('./config/redis');

// Import queues
const { notificationQueue, notificationWorker } = require('./queues/notification.queue');
const { orderQueue, orderWorker } = require('./queues/order.queue');
const { bookingQueue, bookingWorker } = require('./queues/booking.queue');

// Import crons
const { startAutoConfirmCron } = require('./crons/auto.confirm.cron');
const { startSlotCleanupCron } = require('./crons/slot.cleanup.cron');
const { startPayoutReminderCron } = require('./crons/payout.reminder.cron');
const { startScheduledOrderCron } = require('./crons/scheduled.order.cron');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  logger.info(`FreshKart server running on port ${PORT} in ${process.env.NODE_ENV} mode`);

  // Start cron jobs
  startAutoConfirmCron();
  startSlotCleanupCron();
  startPayoutReminderCron();
  startScheduledOrderCron();
  logger.info('Cron jobs started');
  logger.info('BullMQ workers initialized');
});

// Graceful shutdown
const gracefulShutdown = async (signal) => {
  logger.info(`${signal} received. Starting graceful shutdown...`);

  server.close(async () => {
    logger.info('HTTP server closed');

    try {
      // Close queue workers
      await notificationWorker.close();
      await orderWorker.close();
      await bookingWorker.close();
      logger.info('Queue workers closed');

      // Close queues
      await notificationQueue.close();
      await orderQueue.close();
      await bookingQueue.close();
      logger.info('Queues closed');

      // Close Redis
      await redis.quit();
      logger.info('Redis connection closed');

      logger.info('Graceful shutdown complete');
      process.exit(0);
    } catch (err) {
      logger.error('Error during shutdown', err);
      process.exit(1);
    }
  });

  // Force shutdown after 30 seconds
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 30000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled rejection', err);
});
process.on('uncaughtException', (err) => {
  logger.error('Uncaught exception', err);
  process.exit(1);
});
