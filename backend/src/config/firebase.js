const admin = require('firebase-admin');
const { readFileSync } = require('fs');
const logger = require('../utils/logger');

try {
  const serviceAccount = JSON.parse(
    readFileSync(process.env.FIREBASE_SERVICE_ACCOUNT_PATH, 'utf8')
  );

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  }
} catch (err) {
  logger.warn('Firebase initialization failed — FCM notifications will be disabled', {
    error: err.message
  });
}

const fcm = admin.apps.length ? admin.messaging() : null;

module.exports = { fcm, admin };
