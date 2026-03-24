require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { v4: uuidv4 } = require('uuid');
const logger = require('./utils/logger');
const { generalLimiter } = require('./middleware/rateLimiter');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Security headers
app.use(helmet());

// CORS
const allowedOrigins = [process.env.FRONTEND_URL];
if (process.env.NODE_ENV === 'development') {
  allowedOrigins.push('http://localhost:3000', 'http://localhost:5173');
}
app.use(cors({
  origin: allowedOrigins,
  credentials: true
}));

// Raw body for webhook signature verification
app.use('/webhooks', express.raw({ type: 'application/json' }));

// Body parsing for all other routes
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// General rate limiter
app.use(generalLimiter);

// Request logging with request ID
app.use((req, res, next) => {
  req.requestId = uuidv4();
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('request', {
      requestId: req.requestId,
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration: `${duration}ms`,
      userId: req.user?.id || 'anonymous',
      ip: req.ip
    });
  });
  next();
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    env: process.env.NODE_ENV
  });
});

// Mount API routes
app.use('/api/v1', require('./routes/index'));

// Mount webhook routes
app.use('/webhooks', require('./routes/webhook.routes'));

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found`
  });
});

// Global error handler
app.use(errorHandler);

module.exports = app;
