const Joi = require('joi');

const createCoupon = Joi.object({
  code: Joi.string().uppercase().trim().min(3).max(20).required(),
  title: Joi.string().trim().max(100).required(),
  title_tamil: Joi.string().trim().max(200).allow(null, ''),
  description: Joi.string().trim().max(500).allow(null, ''),
  description_tamil: Joi.string().trim().max(500).allow(null, ''),
  discount_type: Joi.string().valid('percentage', 'flat').required(),
  discount_value: Joi.number().positive().required(),
  max_discount: Joi.number().positive().allow(null),
  min_order_amount: Joi.number().min(0).default(0),
  usage_limit: Joi.number().integer().positive().allow(null),
  per_user_limit: Joi.number().integer().positive().default(1),
  vendor_id: Joi.string().uuid().allow(null),
  category_id: Joi.string().uuid().allow(null),
  valid_from: Joi.date().iso().allow(null),
  valid_until: Joi.date().iso().greater(Joi.ref('valid_from')).allow(null),
});

const applyCoupon = Joi.object({
  code: Joi.string().uppercase().trim().required(),
  subtotal: Joi.number().positive().required(),
  vendor_id: Joi.string().uuid().required(),
});

const updateCoupon = Joi.object({
  title: Joi.string().trim().max(100),
  title_tamil: Joi.string().trim().max(200).allow(null, ''),
  description: Joi.string().trim().max(500).allow(null, ''),
  description_tamil: Joi.string().trim().max(500).allow(null, ''),
  discount_value: Joi.number().positive(),
  max_discount: Joi.number().positive().allow(null),
  min_order_amount: Joi.number().min(0),
  usage_limit: Joi.number().integer().positive().allow(null),
  per_user_limit: Joi.number().integer().positive(),
  valid_from: Joi.date().iso(),
  valid_until: Joi.date().iso(),
  is_active: Joi.boolean(),
}).min(1);

module.exports = { createCoupon, applyCoupon, updateCoupon };
