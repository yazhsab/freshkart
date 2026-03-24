const referralService = require('../services/referral.service');
const { successResponse, errorResponse } = require('../utils/response');

const getReferralCode = async (req, res, next) => {
  try {
    const referralCode = await referralService.getOrCreateReferralCode(req.user.id);
    return successResponse(res, referralCode);
  } catch (err) {
    next(err);
  }
};

const applyReferral = async (req, res, next) => {
  try {
    const { code } = req.body;
    if (!code) return errorResponse(res, 'Referral code is required', 400);

    const result = await referralService.applyReferralCode(req.user.id, code);
    if (!result.success) return errorResponse(res, result.reason, 400);

    return successResponse(res, { reward: result.reward }, 200, 'Referral code applied! Welcome bonus added to wallet.');
  } catch (err) {
    next(err);
  }
};

const getStats = async (req, res, next) => {
  try {
    const stats = await referralService.getStats(req.user.id);
    return successResponse(res, stats);
  } catch (err) {
    next(err);
  }
};

module.exports = { getReferralCode, applyReferral, getStats };
