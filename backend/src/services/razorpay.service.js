const { razorpay } = require('../config/razorpay');
const { verifyRazorpaySignature } = require('../utils/crypto.util');
const { toPaise } = require('../utils/currency.util');
const logger = require('../utils/logger');

const createOrder = async ({ amount, currency = 'INR', receipt, notes = {} }) => {
  try {
    const order = await razorpay.orders.create({
      amount: toPaise(amount),
      currency,
      receipt,
      notes
    });

    logger.info('Razorpay order created', { orderId: order.id, amount, receipt });
    return { id: order.id, amount: order.amount, currency: order.currency, receipt: order.receipt };
  } catch (err) {
    logger.error('Razorpay order creation failed', { error: err.message, amount, receipt });
    throw err;
  }
};

const verifyPayment = ({ orderId, paymentId, signature }) => {
  const valid = verifyRazorpaySignature(orderId, paymentId, signature);
  return { valid };
};

const createRefund = async (paymentId, amount, notes = {}) => {
  try {
    const refund = await razorpay.payments.refund(paymentId, {
      amount: toPaise(amount),
      notes
    });

    logger.info('Razorpay refund created', { refundId: refund.id, paymentId, amount });
    return { id: refund.id, amount: refund.amount, status: refund.status };
  } catch (err) {
    logger.error('Razorpay refund failed', { error: err.message, paymentId, amount });
    throw err;
  }
};

const fetchPayment = async (paymentId) => {
  try {
    return await razorpay.payments.fetch(paymentId);
  } catch (err) {
    logger.error('Razorpay fetch payment failed', { error: err.message, paymentId });
    throw err;
  }
};

const createLinkedAccount = async (vendorData) => {
  try {
    const account = await razorpay.accounts.create({
      email: vendorData.email,
      phone: vendorData.phone,
      legal_business_name: vendorData.shopName,
      business_type: 'individual',
      legal_info: { pan: vendorData.pan, gst: vendorData.gstin }
    });

    logger.info('Razorpay linked account created', { accountId: account.id });
    return account;
  } catch (err) {
    logger.error('Razorpay linked account creation failed', { error: err.message });
    throw err;
  }
};

const createTransfer = async (linkedAccountId, amount, notes = {}) => {
  try {
    const transfer = await razorpay.payments.transfer({
      transfers: [{
        account: linkedAccountId,
        amount: toPaise(amount),
        currency: 'INR',
        notes
      }]
    });

    logger.info('Razorpay transfer created', { linkedAccountId, amount });
    return transfer;
  } catch (err) {
    logger.error('Razorpay transfer failed', { error: err.message, linkedAccountId, amount });
    throw err;
  }
};

module.exports = {
  createOrder,
  verifyPayment,
  createRefund,
  fetchPayment,
  createLinkedAccount,
  createTransfer
};
