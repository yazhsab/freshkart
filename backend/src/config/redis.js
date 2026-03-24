const Redis = require('ioredis');
const logger = require('../utils/logger');

const redisUrl = new URL(process.env.UPSTASH_REDIS_URL);

const redis = new Redis(process.env.UPSTASH_REDIS_URL, {
  password: process.env.UPSTASH_REDIS_TOKEN || redisUrl.password || undefined,
  tls: redisUrl.protocol === 'rediss:' ? { rejectUnauthorized: false } : undefined,
  maxRetriesPerRequest: null,
  enableReadyCheck: false
});

redis.on('error', (err) => {
  logger.error('Redis connection error', { error: err.message });
});

redis.on('connect', () => {
  logger.info('Redis connected');
});

module.exports = { redis };
