const { redis } = require('../config/redis');

const redisUrl = new URL(process.env.UPSTASH_REDIS_URL);

const connection = {
  host: redisUrl.hostname,
  port: Number(redisUrl.port) || 6379,
  password: process.env.UPSTASH_REDIS_TOKEN || redisUrl.password || undefined,
  tls: redisUrl.protocol === 'rediss:' ? { rejectUnauthorized: false } : undefined,
  maxRetriesPerRequest: null,
  enableReadyCheck: false
};

const defaultJobOptions = {
  removeOnComplete: { age: 86400, count: 1000 },
  removeOnFail: { age: 604800, count: 5000 },
  attempts: 3,
  backoff: { type: 'exponential', delay: 2000 }
};

module.exports = { connection, defaultJobOptions };
