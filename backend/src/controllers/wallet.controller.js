const walletService = require('../services/wallet.service');
const razorpayService = require('../services/razorpay.service');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const getWallet = async (req, res, next) => {
  try {
    const wallet = await walletService.getOrCreateWallet(req.user.id);
    const { transactions } = await walletService.getTransactions(req.user.id, 1, 5);
    return successResponse(res, { ...wallet, recent_transactions: transactions });
  } catch (err) {
    next(err);
  }
};

const getTransactions = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const { transactions, total } = await walletService.getTransactions(req.user.id, Number(page), Number(limit));
    return paginatedResponse(res, transactions, total, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const topupWallet = async (req, res, next) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0) return errorResponse(res, 'Invalid amount', 400);
    if (amount > 10000) return errorResponse(res, 'Maximum topup is ₹10,000', 400);

    // Check max balance
    const wallet = await walletService.getOrCreateWallet(req.user.id);
    if (wallet.balance + amount > 10000) {
      return errorResponse(res, `Topup would exceed maximum wallet balance of ₹10,000`, 400);
    }

    // Create Razorpay order for topup
    const razorpayOrder = await razorpayService.createOrder({
      amount,
      receipt: `wallet_topup_${req.user.id}_${Date.now()}`
    });

    return successResponse(res, {
      razorpay_order: {
        id: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency
      }
    }, 200, 'Topup order created');
  } catch (err) {
    next(err);
  }
};

const verifyTopup = async (req, res, next) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, amount } = req.body;

    const isValid = razorpayService.verifyPayment(razorpay_order_id, razorpay_payment_id, razorpay_signature);
    if (!isValid) return errorResponse(res, 'Payment verification failed', 400);

    const newBalance = await walletService.credit(req.user.id, amount, 'topup', null, 'Wallet topup via Razorpay');

    logger.info('Wallet topup successful', { userId: req.user.id, amount, newBalance });
    return successResponse(res, { balance: newBalance }, 200, 'Wallet topped up successfully');
  } catch (err) {
    next(err);
  }
};

// Admin: credit user wallet
const adminCreditWallet = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { amount, description } = req.body;
    if (!amount || amount <= 0) return errorResponse(res, 'Invalid amount', 400);

    const newBalance = await walletService.credit(userId, amount, 'admin_credit', null, description || 'Admin credit');
    return successResponse(res, { balance: newBalance }, 200, 'Wallet credited');
  } catch (err) {
    next(err);
  }
};

// Admin: debit user wallet
const adminDebitWallet = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { amount, description } = req.body;
    if (!amount || amount <= 0) return errorResponse(res, 'Invalid amount', 400);

    const newBalance = await walletService.debit(userId, amount, 'admin_credit', null, description || 'Admin debit');
    return successResponse(res, { balance: newBalance }, 200, 'Wallet debited');
  } catch (err) {
    next(err);
  }
};

module.exports = { getWallet, getTransactions, topupWallet, verifyTopup, adminCreditWallet, adminDebitWallet };
