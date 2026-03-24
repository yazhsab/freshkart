const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

const auth = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access token is required'
      });
    }

    const token = authHeader.split(' ')[1];

    const decoded = jwt.verify(token, process.env.SUPABASE_JWT_SECRET);

    req.user = {
      id: decoded.sub,
      email: decoded.email,
      phone: decoded.phone,
      role: decoded.user_metadata?.role || decoded.role || 'customer',
      aud: decoded.aud
    };

    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(403).json({
        success: false,
        message: 'Token expired. Please refresh your session.'
      });
    }

    logger.warn('Auth middleware — invalid token', {
      error: err.message,
      ip: req.ip
    });

    return res.status(401).json({
      success: false,
      message: 'Invalid or malformed token'
    });
  }
};

module.exports = auth;
