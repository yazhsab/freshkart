const logger = require('../utils/logger');

class AppError extends Error {
  constructor(message, statusCode, code) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
  }
}

class ValidationError extends AppError {
  constructor(message) { super(message, 400, 'VALIDATION_ERROR'); }
}
class AuthenticationError extends AppError {
  constructor(message) { super(message || 'Authentication required', 401, 'AUTH_ERROR'); }
}
class ForbiddenError extends AppError {
  constructor(message) { super(message || 'Access forbidden', 403, 'FORBIDDEN'); }
}
class NotFoundError extends AppError {
  constructor(message) { super(message || 'Resource not found', 404, 'NOT_FOUND'); }
}
class ConflictError extends AppError {
  constructor(message) { super(message || 'Resource conflict', 409, 'CONFLICT'); }
}

const errorHandler = (err, req, res, _next) => {
  logger.error('Error caught by handler', {
    requestId: req.requestId,
    message: err.message,
    code: err.code,
    statusCode: err.statusCode,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
    url: req.originalUrl,
    method: req.method,
    userId: req.user?.id
  });

  if (err.isOperational) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      code: err.code
    });
  }

  // Joi validation error
  if (err.isJoi) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: err.details?.map((d) => d.message)
    });
  }

  // Supabase errors
  if (err.code && err.code.startsWith('P')) {
    return res.status(400).json({
      success: false,
      message: 'Database operation failed',
      code: err.code
    });
  }

  // Default 500
  return res.status(500).json({
    success: false,
    message: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message,
    code: 'INTERNAL_ERROR'
  });
};

module.exports = errorHandler;
module.exports.AppError = AppError;
module.exports.ValidationError = ValidationError;
module.exports.AuthenticationError = AuthenticationError;
module.exports.ForbiddenError = ForbiddenError;
module.exports.NotFoundError = NotFoundError;
module.exports.ConflictError = ConflictError;
