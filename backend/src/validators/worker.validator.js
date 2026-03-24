const Joi = require('joi');

const registerWorkerSchema = Joi.object({
  full_name: Joi.string().min(2).max(100).required(),
  phone: Joi.string().pattern(/^[6-9]\d{9}$/).required(),
  service_category_ids: Joi.array().items(Joi.string().uuid()).min(1).required(),
  service_pincodes: Joi.array().items(
    Joi.string().length(6).pattern(/^\d+$/)
  ).min(1).required(),
  experience_years: Joi.number().integer().min(0).max(50).optional(),
  languages: Joi.array().items(Joi.string()).default(['Tamil']),
  address: Joi.object({
    line1: Joi.string().required(),
    area: Joi.string().required(),
    city: Joi.string().required(),
    pincode: Joi.string().length(6).pattern(/^\d+$/).required()
  }).required(),
  aadhaar_number: Joi.string().length(12).pattern(/^\d+$/).optional()
});

const updateWorkerSchema = Joi.object({
  service_category_ids: Joi.array().items(Joi.string().uuid()).optional(),
  service_pincodes: Joi.array().items(Joi.string().length(6).pattern(/^\d+$/)).optional(),
  experience_years: Joi.number().integer().min(0).max(50).optional(),
  languages: Joi.array().items(Joi.string()).optional()
}).min(1);

module.exports = {
  registerWorkerSchema,
  updateWorkerSchema
};
