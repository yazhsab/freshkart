const admin = require('firebase-admin');
const { readFileSync } = require('fs');
const logger = require('../utils/logger');

try {
  let serviceAccount;
  if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    serviceAccount = JSON.parse(
      Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf8')
    );
  } else {
    serviceAccount = JSON.parse(
      readFileSync(process.env.FIREBASE_SERVICE_ACCOUNT_PATH, 'utf8')
    );
  }

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
