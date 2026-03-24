const Joi = require('joi');

const createOrderSchema = Joi.object({
  vendor_id: Joi.string().uuid().required(),
  items: Joi.array().items(Joi.object({
    product_id: Joi.string().uuid().required(),
    quantity: Joi.number().integer().min(1).max(50).required()
  })).min(1).max(20).required(),
  delivery_address: Joi.object({
    flat_no: Joi.string().required(),
    area: Joi.string().required(),
    city: Joi.string().required(),
    pincode: Joi.string().length(6).pattern(/^\d+$/).required(),
    lat: Joi.number().required(),
    lng: Joi.number().required()
  }).required(),
  payment_method: Joi.string().valid('upi', 'card', 'cod', 'wallet').required(),
  special_instructions: Joi.string().max(200).optional()
});

const updateOrderStatusSchema = Joi.object({
  status: Joi.string().valid(
    'confirmed', 'packing', 'ready', 'picked_up', 'delivered', 'cancelled'
  ).required(),
  cancel_reason: Joi.string().max(200).when('status', {
    is: 'cancelled',
    then: Joi.optional()
  })
});

const cancelOrderSchema = Joi.object({
  cancel_reason: Joi.string().max(200).optional()
});

module.exports = {
  createOrderSchema,
  updateOrderStatusSchema,
  cancelOrderSchema
};
