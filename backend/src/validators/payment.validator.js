const Joi = require('joi');

const razorpayCreateOrderSchema = Joi.object({
  ref_type: Joi.string().valid('order', 'booking').required(),
  ref_id: Joi.string().uuid().required()
});

const razorpayVerifySchema = Joi.object({
  razorpay_order_id: Joi.string().required(),
  razorpay_payment_id: Joi.string().required(),
  razorpay_signature: Joi.string().required(),
  ref_type: Joi.string().valid('order', 'booking').required(),
  ref_id: Joi.string().uuid().required()
});

const phonePeInitiateSchema = Joi.object({
  ref_type: Joi.string().valid('order', 'booking').required(),
  ref_id: Joi.string().uuid().required(),
  customer_phone: Joi.string().pattern(/^[6-9]\d{9}$/).required(),
  redirect_url: Joi.string().uri().required(),
  callback_url: Joi.string().uri().required()
});

const refundSchema = Joi.object({
  ref_type: Joi.string().valid('order', 'booking').required(),
  ref_id: Joi.string().uuid().required(),
  amount: Joi.number().positive().required(),
  reason: Joi.string().max(200).optional()
});

module.exports = {
  razorpayCreateOrderSchema,
  razorpayVerifySchema,
  phonePeInitiateSchema,
  refundSchema
};
