const Joi = require('joi');

const sendOTPSchema = Joi.object({
  phone: Joi.string()
    .pattern(/^(\+?91)?[6-9]\d{9}$/)
    .required()
    .messages({
      'string.pattern.base': 'Phone must be a valid 10-digit Indian mobile number starting with 6-9'
    })
});

const verifyOTPSchema = Joi.object({
  phone: Joi.string()
    .pattern(/^(\+?91)?[6-9]\d{9}$/)
    .required(),
  otp: Joi.string()
    .length(6)
    .pattern(/^\d+$/)
    .required()
    .messages({
      'string.pattern.base': 'OTP must be 6 digits'
    }),
  role: Joi.string()
    .valid('customer', 'vendor', 'worker', 'delivery_agent')
    .default('customer')
});

const updateProfileSchema = Joi.object({
  full_name: Joi.string().min(2).max(100).optional(),
  email: Joi.string().email().optional(),
  fcm_token: Joi.string().optional()
});

module.exports = {
  sendOTPSchema,
  verifyOTPSchema,
  updateProfileSchema
};
