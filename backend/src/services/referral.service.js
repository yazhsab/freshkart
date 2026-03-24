const { supabaseAdmin } = require('../config/supabase');
const walletService = require('./wallet.service');
const logger = require('../utils/logger');

const generateCode = (name) => {
  const prefix = (name || 'FK').substring(0, 3).toUpperCase().replace(/[^A-Z]/g, 'F');
  const random = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `${prefix}${random}`;
};

const getOrCreateReferralCode = async (userId) => {
  let { data: existing } = await supabaseAdmin
    .from('referral_codes')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (existing) return existing;

  // Get user name for code generation
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('full_name')
    .eq('id', userId)
    .single();

  const code = generateCode(profile?.full_name);

  const { data: created, error } = await supabaseAdmin
    .from('referral_codes')
    .insert({ user_id: userId, code })
    .select()
    .single();

  if (error) {
    // Code collision, try again with different random
    const retryCode = generateCode(profile?.full_name);
    const { data: retry } = await supabaseAdmin
      .from('referral_codes')
      .insert({ user_id: userId, code: retryCode })
      .select()
      .single();
    return retry;
  }

  return created;
};

const applyReferralCode = async (refereeId, code) => {
  const { data: referralCode } = await supabaseAdmin
    .from('referral_codes')
    .select('*')
    .eq('code', code.toUpperCase())
    .eq('is_active', true)
    .single();

  if (!referralCode) return { success: false, reason: 'Invalid referral code' };
  if (referralCode.user_id === refereeId) return { success: false, reason: 'Cannot use your own referral code' };

  // Check if already referred
  const { data: existing } = await supabaseAdmin
    .from('referrals')
    .select('id')
    .eq('referee_id', refereeId)
    .single();

  if (existing) return { success: false, reason: 'You have already been referred' };

  // Get reward amounts from config
  const { data: configs } = await supabaseAdmin
    .from('platform_config')
    .select('key, value')
    .in('key', ['referral_referrer_reward', 'referral_referee_reward']);

  const configMap = {};
  (configs || []).forEach(c => configMap[c.key] = parseFloat(c.value));
  const referrerReward = configMap.referral_referrer_reward || 50;
  const refereeReward = configMap.referral_referee_reward || 25;

  // Create referral record
  await supabaseAdmin.from('referrals').insert({
    referrer_id: referralCode.user_id,
    referee_id: refereeId,
    referral_code_id: referralCode.id,
    referrer_reward: referrerReward,
    referee_reward: refereeReward,
    status: 'pending'
  });

  // Credit referee wallet immediately
  await walletService.getOrCreateWallet(refereeId);
  await walletService.credit(refereeId, refereeReward, 'referral_bonus', null, 'Welcome bonus for joining via referral');

  logger.info('Referral applied', { refereeId, referrerId: referralCode.user_id });
  return { success: true, reward: refereeReward };
};

const completeReferral = async (refereeId, orderId) => {
  const { data: referral } = await supabaseAdmin
    .from('referrals')
    .select('*')
    .eq('referee_id', refereeId)
    .eq('status', 'pending')
    .single();

  if (!referral) return;

  // Credit referrer wallet
  await walletService.getOrCreateWallet(referral.referrer_id);
  await walletService.credit(
    referral.referrer_id,
    referral.referrer_reward,
    'referral_bonus',
    orderId,
    'Referral reward: your friend placed their first order!'
  );

  // Update referral status
  await supabaseAdmin.from('referrals')
    .update({
      status: 'rewarded',
      referee_first_order_id: orderId,
      completed_at: new Date().toISOString()
    })
    .eq('id', referral.id);

  // Update referral code stats
  await supabaseAdmin.from('referral_codes')
    .update({
      total_referrals: referral.total_referrals + 1,
      total_earned: referral.total_earned + referral.referrer_reward
    })
    .eq('id', referral.referral_code_id);

  logger.info('Referral completed', { referrerId: referral.referrer_id, refereeId, orderId });
};

const getStats = async (userId) => {
  const { data: code } = await supabaseAdmin
    .from('referral_codes')
    .select('*')
    .eq('user_id', userId)
    .single();

  const { data: referrals } = await supabaseAdmin
    .from('referrals')
    .select('*, profiles!referee_id(full_name)')
    .eq('referrer_id', userId)
    .order('created_at', { ascending: false });

  return {
    code: code?.code || null,
    total_referrals: code?.total_referrals || 0,
    total_earned: code?.total_earned || 0,
    referrals: referrals || []
  };
};

module.exports = { getOrCreateReferralCode, applyReferralCode, completeReferral, getStats };
