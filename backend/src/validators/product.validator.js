const Joi = require('joi');

const createProductSchema = Joi.object({
  name: Joi.string().min(2).max(200).required(),
  description: Joi.string().max(500).optional(),
  category_id: Joi.string().uuid().optional(),
  category_name: Joi.string().max(100).optional(),
  price: Joi.number().positive().max(100000).required(),
  mrp: Joi.number().positive().max(100000).optional(),
  unit: Joi.string().valid('kg', 'g', 'l', 'ml', 'piece', 'pack', 'dozen', 'bundle').required(),
  unit_value: Joi.number().positive().optional(),
  stock_quantity: Joi.number().integer().min(0).max(99999).required(),
  low_stock_threshold: Joi.number().integer().min(0).default(10),
  is_available: Joi.boolean().default(true),
  tags: Joi.array().items(Joi.string()).optional()
});

const updateProductSchema = Joi.object({
  name: Joi.string().min(2).max(200).optional(),
  description: Joi.string().max(500).optional(),
  category_id: Joi.string().uuid().optional(),
  category_name: Joi.string().max(100).optional(),
  price: Joi.number().positive().max(100000).optional(),
  mrp: Joi.number().positive().max(100000).optional(),
  unit: Joi.string().valid('kg', 'g', 'l', 'ml', 'piece', 'pack', 'dozen', 'bundle').optional(),
  unit_value: Joi.number().positive().optional(),
  low_stock_threshold: Joi.number().integer().min(0).optional(),
  tags: Joi.array().items(Joi.string()).optional()
}).min(1);

const updateStockSchema = Joi.object({
  stock_quantity: Joi.number().integer().min(0).max(99999).required()
});

const searchProductsSchema = Joi.object({
  q: Joi.string().min(1).max(100).required(),
  lat: Joi.number().optional(),
  lng: Joi.number().optional(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(50).default(20)
});

module.exports = {
  createProductSchema,
  updateProductSchema,
  updateStockSchema,
  searchProductsSchema
};
