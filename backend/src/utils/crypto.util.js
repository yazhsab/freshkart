const crypto = require('crypto');

const generateOTP = (length = 6) => {
  const digits = '0123456789';
  let otp = '';
  const bytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    otp += digits[bytes[i] % 10];
  }
  return otp;
};

const generateDeliveryOTP = () => {
  return generateOTP(4);
};

const verifyRazorpaySignature = (orderId, paymentId, signature) => {
  const body = orderId + '|' + paymentId;
  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(body)
    .digest('hex');
  return expectedSignature === signature;
};

const verifyRazorpayWebhookSignature = (rawBody, signature) => {
  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(rawBody)
    .digest('hex');
  return expectedSignature === signature;
};

const generatePhonePeChecksum = (base64Payload, endpoint) => {
  const string = base64Payload + endpoint + process.env.PHONEPE_SALT_KEY;
  const sha256Hash = crypto.createHash('sha256').update(string).digest('hex');
  return sha256Hash + '###' + process.env.PHONEPE_SALT_INDEX;
};

const maskPhone = (phone) => {
  if (!phone) return '';
  const cleaned = phone.replace(/\D/g, '');
  const last4 = cleaned.slice(-4);
  return '+91XXXXXX' + last4;
};

const maskAccount = (account) => {
  if (!account) return '';
  const last4 = account.slice(-4);
  return 'XXXX' + last4;
};

module.exports = {
  generateOTP,
  generateDeliveryOTP,
  verifyRazorpaySignature,
  verifyRazorpayWebhookSignature,
  generatePhonePeChecksum,
  maskPhone,
  maskAccount
};
