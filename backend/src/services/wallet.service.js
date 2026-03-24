const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

const getOrCreateWallet = async (userId) => {
  // Try to get existing wallet
  let { data: wallet } = await supabaseAdmin
    .from('wallets')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (!wallet) {
    const { data: newWallet, error } = await supabaseAdmin
      .from('wallets')
      .insert({ user_id: userId, balance: 0 })
      .select()
      .single();
    if (error) {
      // Race condition: wallet was created by another request
      const { data: existing } = await supabaseAdmin
        .from('wallets')
        .select('*')
        .eq('user_id', userId)
        .single();
      return existing;
    }
    return newWallet;
  }
  return wallet;
};

const credit = async (userId, amount, referenceType, referenceId = null, description = null) => {
  const newBalance = await supabaseAdmin.rpc('wallet_credit', {
    p_user_id: userId,
    p_amount: amount,
    p_reference_type: referenceType,
    p_reference_id: referenceId,
    p_description: description
  });

  logger.info('Wallet credited', { userId, amount, referenceType, newBalance: newBalance.data });
  return newBalance.data;
};

const debit = async (userId, amount, referenceType, referenceId = null, description = null) => {
  const { data: newBalance, error } = await supabaseAdmin.rpc('wallet_debit', {
    p_user_id: userId,
    p_amount: amount,
    p_reference_type: referenceType,
    p_reference_id: referenceId,
    p_description: description
  });

  if (error) {
    logger.error('Wallet debit failed', { userId, amount, error: error.message });
    throw new Error(error.message);
  }

  logger.info('Wallet debited', { userId, amount, referenceType, newBalance });
  return newBalance;
};

const getTransactions = async (userId, page = 1, limit = 20) => {
  const from = (page - 1) * limit;
  const to = from + limit - 1;

  const { data, error, count } = await supabaseAdmin
    .from('wallet_transactions')
    .select('*', { count: 'exact' })
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(from, to);

  return { transactions: data || [], total: count || 0 };
};

module.exports = { getOrCreateWallet, credit, debit, getTransactions };
