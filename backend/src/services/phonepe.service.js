const axios = require('axios');
const crypto = require('crypto');
const logger = require('../utils/logger');
const { toPaise } = require('../utils/currency.util');

const BASE_URL = process.env.PHONEPE_BASE_URL || 'https://api-preprod.phonepe.com/apis/pg-sandbox';

const generateChecksum = (base64Payload, endpoint) => {
  const string = base64Payload + endpoint + process.env.PHONEPE_SALT_KEY;
  const sha256Hash = crypto.createHash('sha256').update(string).digest('hex');
  return sha256Hash + '###' + process.env.PHONEPE_SALT_INDEX;
};

const initiatePayment = async ({ orderId, amount, customerPhone, redirectUrl, callbackUrl }) => {
  try {
    const payload = {
      merchantId: process.env.PHONEPE_MERCHANT_ID,
      merchantTransactionId: orderId,
      amount: toPaise(amount),
      redirectUrl,
      callbackUrl,
      mobileNumber: customerPhone.replace(/\D/g, '').slice(-10),
      paymentInstrument: { type: 'PAY_PAGE' }
    };

    const base64Payload = Buffer.from(JSON.stringify(payload)).toString('base64');
    const checksum = generateChecksum(base64Payload, '/pg/v1/pay');

    const response = await axios.post(`${BASE_URL}/pg/v1/pay`, {
      request: base64Payload
    }, {
      headers: {
        'Content-Type': 'application/json',
        'X-VERIFY': checksum
      }
    });

    const data = response.data;
    logger.info('PhonePe payment initiated', { orderId, merchantTransactionId: orderId });

    return {
      success: data.success,
      redirectUrl: data.data?.instrumentResponse?.redirectInfo?.url,
      transactionId: orderId
    };
  } catch (err) {
    logger.error('PhonePe initiation failed', { error: err.response?.data || err.message, orderId });
    throw err;
  }
};

const verifyPayment = async (merchantTransactionId) => {
  try {
    const endpoint = `/pg/v1/status/${process.env.PHONEPE_MERCHANT_ID}/${merchantTransactionId}`;
    const checksum = generateChecksum('', endpoint);

    const response = await axios.get(`${BASE_URL}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        'X-VERIFY': checksum,
        'X-MERCHANT-ID': process.env.PHONEPE_MERCHANT_ID
      }
    });

    const data = response.data;
    logger.info('PhonePe payment status checked', { merchantTransactionId, code: data.code });

    return {
      success: data.code === 'PAYMENT_SUCCESS',
      transactionId: merchantTransactionId,
      amount: data.data?.amount ? data.data.amount / 100 : 0,
      status: data.code
    };
  } catch (err) {
    logger.error('PhonePe verify failed', { error: err.response?.data || err.message });
    throw err;
  }
};

const verifyCallback = (xVerifyHeader, responseBody) => {
  try {
    const base64Response = Buffer.from(JSON.stringify(responseBody)).toString('base64');
    const expectedChecksum = generateChecksum(base64Response, '/pg/v1/pay');
    return xVerifyHeader === expectedChecksum;
  } catch (err) {
    logger.error('PhonePe callback verification failed', { error: err.message });
    return false;
  }
};

module.exports = {
  initiatePayment,
  verifyPayment,
  verifyCallback
};
