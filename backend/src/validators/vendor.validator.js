const Joi = require('joi');

const registerVendorSchema = Joi.object({
  shop_name: Joi.string().min(2).max(100).required(),
  description: Joi.string().max(500).optional(),
  category: Joi.string().valid('grocery', 'fruits', 'vegetables', 'dairy', 'bakery', 'meat', 'general').required(),
  address: Joi.object({
    line1: Joi.string().required(),
    line2: Joi.string().optional(),
    area: Joi.string().required(),
    city: Joi.string().required(),
    pincode: Joi.string().length(6).pattern(/^\d+$/).required(),
    lat: Joi.number().required(),
    lng: Joi.number().required()
  }).required(),
  phone: Joi.string().pattern(/^[6-9]\d{9}$/).required(),
  fssai_number: Joi.string().optional(),
  gstin: Joi.string().optional(),
  opening_time: Joi.string().pattern(/^\d{2}:\d{2}$/).default('08:00'),
  closing_time: Joi.string().pattern(/^\d{2}:\d{2}$/).default('21:00'),
  working_days: Joi.array().items(Joi.number().min(0).max(6)).default([0, 1, 2, 3, 4, 5, 6]),
  delivery_radius_km: Joi.number().min(1).max(30).default(5),
  min_order_amount: Joi.number().min(0).default(0),
  free_delivery_above: Joi.number().min(0).default(500)
});

const updateVendorSchema = Joi.object({
  shop_name: Joi.string().min(2).max(100).optional(),
  description: Joi.string().max(500).optional(),
  address: Joi.object({
    line1: Joi.string().required(),
    line2: Joi.string().optional(),
    area: Joi.string().required(),
    city: Joi.string().required(),
    pincode: Joi.string().length(6).pattern(/^\d+$/).required(),
    lat: Joi.number().required(),
    lng: Joi.number().required()
  }).optional(),
  opening_time: Joi.string().pattern(/^\d{2}:\d{2}$/).optional(),
  closing_time: Joi.string().pattern(/^\d{2}:\d{2}$/).optional(),
  working_days: Joi.array().items(Joi.number().min(0).max(6)).optional(),
  delivery_radius_km: Joi.number().min(1).max(30).optional(),
  min_order_amount: Joi.number().min(0).optional(),
  free_delivery_above: Joi.number().min(0).optional()
}).min(1);

module.exports = {
  registerVendorSchema,
  updateVendorSchema
};
