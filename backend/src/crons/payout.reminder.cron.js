const cron = require('node-cron');
const payoutService = require('../services/payout.service');
const fcmService = require('../services/fcm.service');
const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

const startPayoutReminderCron = () => {
  // Every Monday at 10 AM IST (04:30 UTC)
  cron.schedule('30 4 * * 1', async () => {
    try {
      logger.info('Weekly payout generation started');

      const result = await payoutService.generateWeeklyPayouts();

      // Notify admins
      const { data: admins } = await supabaseAdmin
        .from('profiles')
        .select('fcm_token')
        .eq('role', 'admin')
        .not('fcm_token', 'is', null);

      if (admins?.length) {
        const tokens = admins.map((a) => a.fcm_token);
        await fcmService.sendToMultiple(tokens, {
          title: 'Weekly Payouts Ready',
          body: `${result.vendorPayoutsCreated} vendor and ${result.workerPayoutsCreated} worker payouts pending processing.`,
          data: { type: 'payout_reminder' }
        });
      }

      logger.info('Weekly payout cron completed', result);
    } catch (err) {
      logger.error('Payout reminder cron failed', { error: err.message });
    }
  });

  logger.info('Payout reminder cron started (Monday 10 AM IST)');
};

module.exports = { startPayoutReminderCron };
