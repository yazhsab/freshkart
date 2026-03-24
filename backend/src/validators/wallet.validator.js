const Joi = require('joi');

const topup = Joi.object({
  amount: Joi.number().positive().max(10000).required(),
});

const verifyTopup = Joi.object({
  razorpay_order_id: Joi.string().required(),
  razorpay_payment_id: Joi.string().required(),
  razorpay_signature: Joi.string().required(),
  amount: Joi.number().positive().required(),
});

const adminCredit = Joi.object({
  amount: Joi.number().positive().required(),
  description: Joi.string().max(200).allow(null, ''),
});

module.exports = { topup, verifyTopup, adminCredit };
