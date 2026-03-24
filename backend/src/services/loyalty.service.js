const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

const getLoyaltyBalance = async (userId) => {
  let { data: loyalty } = await supabaseAdmin
    .from('loyalty_points')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (!loyalty) {
    const { data: created } = await supabaseAdmin
      .from('loyalty_points')
      .insert({ user_id: userId })
      .select()
      .single();
    return created || { total_earned: 0, total_redeemed: 0, current_balance: 0 };
  }
  return loyalty;
};

const earnPoints = async (userId, orderAmount, orderId) => {
  const { data: points, error } = await supabaseAdmin.rpc('loyalty_earn', {
    p_user_id: userId,
    p_order_amount: orderAmount,
    p_order_id: orderId
  });

  if (error) {
    logger.error('Loyalty earn failed', { userId, error: error.message });
    return 0;
  }

  logger.info('Loyalty points earned', { userId, points: points, orderId });
  return points;
};

const redeemPoints = async (userId, points, orderId) => {
  // Check minimum redemption
  const { data: minRedeem } = await supabaseAdmin
    .from('platform_config')
    .select('value')
    .eq('key', 'loyalty_min_redeem_points')
    .single();

  const minPoints = parseInt(minRedeem?.value || '50');
  if (points < minPoints) {
    throw new Error(`Minimum ${minPoints} points required for redemption`);
  }

  const { data: discount, error } = await supabaseAdmin.rpc('loyalty_redeem', {
    p_user_id: userId,
    p_points: points,
    p_order_id: orderId
  });

  if (error) {
    throw new Error(error.message);
  }

  logger.info('Loyalty points redeemed', { userId, points, discount, orderId });
  return discount;
};

const getTransactions = async (userId, page = 1, limit = 20) => {
  const from = (page - 1) * limit;
  const to = from + limit - 1;

  const { data, count } = await supabaseAdmin
    .from('loyalty_transactions')
    .select('*', { count: 'exact' })
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(from, to);

  return { transactions: data || [], total: count || 0 };
};

module.exports = { getLoyaltyBalance, earnPoints, redeemPoints, getTransactions };
