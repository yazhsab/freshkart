const cron = require('node-cron');
const { supabaseAdmin } = require('../config/supabase');
const slotService = require('../services/slot.service');
const logger = require('../utils/logger');

const startSlotCleanupCron = () => {
  // Daily at midnight IST (18:30 UTC previous day)
  cron.schedule('30 18 * * *', async () => {
    try {
      const today = new Date().toISOString().split('T')[0];

      // Delete old unbooked slots
      const { error: deleteError, count } = await supabaseAdmin
        .from('worker_slots')
        .delete({ count: 'exact' })
        .lt('slot_date', today)
        .eq('is_booked', false);

      if (deleteError) {
        logger.error('Slot cleanup delete failed', { error: deleteError });
      } else {
        logger.info('Old unbooked slots deleted', { count });
      }

      // Generate new slots for approved workers who need them
      const { data: workers } = await supabaseAdmin
        .from('workers')
        .select('id')
        .eq('is_approved', true);

      if (!workers?.length) return;

      // Check each worker's furthest slot date
      let regenerated = 0;
      for (const worker of workers) {
        const { data: latestSlot } = await supabaseAdmin
          .from('worker_slots')
          .select('slot_date')
          .eq('worker_id', worker.id)
          .order('slot_date', { ascending: false })
          .limit(1)
          .single();

        const furthestDate = latestSlot?.slot_date;
        const thirtyDaysOut = new Date();
        thirtyDaysOut.setDate(thirtyDaysOut.getDate() + 30);
        const targetDate = thirtyDaysOut.toISOString().split('T')[0];

        if (!furthestDate || furthestDate < targetDate) {
          const startDate = furthestDate
            ? new Date(new Date(furthestDate).getTime() + 86400000)
            : new Date();

          const daysNeeded = Math.ceil((thirtyDaysOut - startDate) / 86400000);
          if (daysNeeded > 0) {
            await slotService.generateDefaultSlots(worker.id, startDate, daysNeeded);
            regenerated++;
          }
        }
      }

      logger.info('Slot cleanup cron completed', { workersRegenerated: regenerated });
    } catch (err) {
      logger.error('Slot cleanup cron failed', { error: err.message });
    }
  });

  logger.info('Slot cleanup cron started (daily at midnight IST)');
};

module.exports = { startSlotCleanupCron };
