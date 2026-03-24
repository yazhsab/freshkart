const Joi = require('joi');

const createBookingSchema = Joi.object({
  service_category_id: Joi.string().uuid().required(),
  slot_date: Joi.date().min('now').required(),
  slot_start: Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
  slot_end: Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
  service_address: Joi.object({
    flat_no: Joi.string().required(),
    area: Joi.string().required(),
    city: Joi.string().required(),
    pincode: Joi.string().length(6).pattern(/^\d+$/).required(),
    lat: Joi.number().required(),
    lng: Joi.number().required()
  }).required(),
  customer_notes: Joi.string().max(500).optional(),
  payment_method: Joi.string().valid('upi', 'card', 'cod').required()
});

const updateBookingStatusSchema = Joi.object({
  status: Joi.string().valid(
    'confirmed', 'assigned', 'worker_on_way', 'in_progress', 'completed', 'cancelled'
  ).required(),
  cancel_reason: Joi.string().max(200).optional(),
  worker_notes: Joi.string().max(500).optional(),
  final_price: Joi.number().positive().optional()
});

const checkinSchema = Joi.object({
  otp: Joi.string().length(4).pattern(/^\d+$/).required()
});

const checkoutSchema = Joi.object({
  worker_notes: Joi.string().max(500).optional(),
  final_price: Joi.number().positive().optional()
});

const addSlotsSchema = Joi.object({
  slots: Joi.array().items(Joi.object({
    slot_date: Joi.date().required(),
    slot_start: Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
    slot_end: Joi.string().pattern(/^\d{2}:\d{2}$/).required()
  })).min(1).max(100).required()
});

module.exports = {
  createBookingSchema,
  updateBookingStatusSchema,
  checkinSchema,
  checkoutSchema,
  addSlotsSchema
};
