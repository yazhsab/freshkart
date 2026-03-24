const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

const GROCERY_COMMISSION = Number(process.env.PLATFORM_COMMISSION_GROCERY) || 10;
const SERVICE_COMMISSION = Number(process.env.PLATFORM_COMMISSION_SERVICE) || 20;

const calculateVendorPayout = async (vendorId, periodStart, periodEnd) => {
  const { data: orders, error } = await supabaseAdmin
    .from('orders')
    .select('id, final_amount')
    .eq('vendor_id', vendorId)
    .eq('status', 'delivered')
    .gte('created_at', periodStart)
    .lte('created_at', periodEnd);

  if (error) {
    logger.error('Failed to calculate vendor payout', { error, vendorId });
    return null;
  }

  const orderCount = orders?.length || 0;
  const gross = orders?.reduce((sum, o) => sum + Number(o.final_amount), 0) || 0;
  const commission = gross * (GROCERY_COMMISSION / 100);
  const net = gross - commission;

  return {
    vendorId,
    orderCount,
    gross: Math.round(gross * 100) / 100,
    commission: Math.round(commission * 100) / 100,
    net: Math.round(net * 100) / 100,
    periodStart,
    periodEnd
  };
};

const calculateWorkerPayout = async (workerId, periodStart, periodEnd) => {
  const { data: bookings, error } = await supabaseAdmin
    .from('bookings')
    .select('id, final_price, booking_fee')
    .eq('worker_id', workerId)
    .eq('status', 'completed')
    .gte('created_at', periodStart)
    .lte('created_at', periodEnd);

  if (error) {
    logger.error('Failed to calculate worker payout', { error, workerId });
    return null;
  }

  const jobCount = bookings?.length || 0;
  const gross = bookings?.reduce((sum, b) => sum + Number(b.final_price || 0), 0) || 0;
  const commission = gross * (SERVICE_COMMISSION / 100);
  const net = gross - commission;

  return {
    workerId,
    jobCount,
    gross: Math.round(gross * 100) / 100,
    commission: Math.round(commission * 100) / 100,
    net: Math.round(net * 100) / 100,
    periodStart,
    periodEnd
  };
};

const generateWeeklyPayouts = async () => {
  const now = new Date();
  const periodEnd = new Date(now);
  periodEnd.setDate(periodEnd.getDate() - periodEnd.getDay()); // Last Sunday
  periodEnd.setHours(23, 59, 59, 999);

  const periodStart = new Date(periodEnd);
  periodStart.setDate(periodStart.getDate() - 6); // Last Monday
  periodStart.setHours(0, 0, 0, 0);

  const startISO = periodStart.toISOString();
  const endISO = periodEnd.toISOString();

  logger.info('Generating weekly payouts', { periodStart: startISO, periodEnd: endISO });

  // Vendor payouts
  const { data: vendors } = await supabaseAdmin
    .from('vendors')
    .select('id')
    .eq('is_approved', true);

  let vendorPayoutsCreated = 0;
  for (const vendor of (vendors || [])) {
    const payout = await calculateVendorPayout(vendor.id, startISO, endISO);
    if (payout && payout.net > 0) {
      await supabaseAdmin.from('payouts').insert({
        payee_type: 'vendor',
        payee_id: vendor.id,
        period_start: startISO,
        period_end: endISO,
        gross_amount: payout.gross,
        commission_amount: payout.commission,
        net_amount: payout.net,
        order_count: payout.orderCount,
        status: 'pending'
      });
      vendorPayoutsCreated++;
    }
  }

  // Worker payouts
  const { data: workers } = await supabaseAdmin
    .from('workers')
    .select('id')
    .eq('is_approved', true);

  let workerPayoutsCreated = 0;
  for (const worker of (workers || [])) {
    const payout = await calculateWorkerPayout(worker.id, startISO, endISO);
    if (payout && payout.net > 0) {
      await supabaseAdmin.from('payouts').insert({
        payee_type: 'worker',
        payee_id: worker.id,
        period_start: startISO,
        period_end: endISO,
        gross_amount: payout.gross,
        commission_amount: payout.commission,
        net_amount: payout.net,
        job_count: payout.jobCount,
        status: 'pending'
      });
      workerPayoutsCreated++;
    }
  }

  logger.info('Weekly payouts generated', { vendorPayoutsCreated, workerPayoutsCreated });
  return { vendorPayoutsCreated, workerPayoutsCreated };
};

module.exports = {
  calculateVendorPayout,
  calculateWorkerPayout,
  generateWeeklyPayouts
};
