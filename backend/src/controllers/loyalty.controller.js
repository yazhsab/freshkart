const loyaltyService = require('../services/loyalty.service');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');

const getLoyalty = async (req, res, next) => {
  try {
    const loyalty = await loyaltyService.getLoyaltyBalance(req.user.id);
    const { transactions } = await loyaltyService.getTransactions(req.user.id, 1, 5);
    return successResponse(res, { ...loyalty, recent_transactions: transactions });
  } catch (err) {
    next(err);
  }
};

const getTransactions = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const { transactions, total } = await loyaltyService.getTransactions(req.user.id, Number(page), Number(limit));
    return paginatedResponse(res, transactions, total, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const redeemPoints = async (req, res, next) => {
  try {
    const { points, order_id } = req.body;
    if (!points || points <= 0) return errorResponse(res, 'Invalid points', 400);

    const discount = await loyaltyService.redeemPoints(req.user.id, points, order_id);
    return successResponse(res, { discount_amount: discount }, 200, 'Points redeemed');
  } catch (err) {
    if (err.message.includes('Insufficient') || err.message.includes('Minimum')) {
      return errorResponse(res, err.message, 400);
    }
    next(err);
  }
};

module.exports = { getLoyalty, getTransactions, redeemPoints };
