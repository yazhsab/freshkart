const axios = require('axios');
const logger = require('../utils/logger');

const MSG91_BASE = 'https://api.msg91.com/api/v5';

const formatPhone = (phone) => {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.startsWith('91') && cleaned.length === 12) return cleaned;
  if (cleaned.length === 10) return '91' + cleaned;
  return cleaned;
};

const sendOTP = async (phone, otp) => {
  try {
    const response = await axios.post(`${MSG91_BASE}/otp`, null, {
      params: {
        authkey: process.env.MSG91_AUTH_KEY,
        template_id: process.env.MSG91_OTP_TEMPLATE_ID,
        mobile: formatPhone(phone),
        otp
      },
      headers: { 'Content-Type': 'application/json' }
    });

    logger.info('OTP sent via MSG91', {
      phone: formatPhone(phone).slice(-4),
      response: response.data
    });
    return {
      success: true,
      message: response.data?.message || 'OTP sent',
      requestId: response.data?.request_id || response.data?.requestId || null
    };
  } catch (err) {
    logger.error('MSG91 OTP failed', {
      status: err.response?.status,
      error: err.response?.data || err.message
    });
    return {
      success: false,
      statusCode: err.response?.status || 502,
      error: err.response?.data?.message || err.response?.data?.type || err.message
    };
  }
};

const sendFlowSMS = async (phone, templateId, templateVars) => {
  try {
    const response = await axios.post(
      `${MSG91_BASE}/flow/`,
      {
        flow_id: templateId,
        sender: process.env.MSG91_SENDER_ID,
        mobiles: formatPhone(phone),
        ...templateVars
      },
      {
        headers: {
          authkey: process.env.MSG91_AUTH_KEY,
          'Content-Type': 'application/json'
        }
      }
    );

    logger.info('Flow SMS sent', { phone: formatPhone(phone).slice(-4), templateId });
    return { success: true, message: response.data?.message || 'SMS sent' };
  } catch (err) {
    logger.error('MSG91 Flow SMS failed', { error: err.response?.data || err.message, templateId });
    return { success: false, error: err.response?.data?.message || err.message };
  }
};

const sendOrderSMS = async (phone, templateVars) => {
  return sendFlowSMS(phone, process.env.MSG91_ORDER_TEMPLATE_ID, {
    customer_name: templateVars.customerName,
    order_number: templateVars.orderNumber,
    status: templateVars.status,
    vendor_name: templateVars.vendorName
  });
};

const sendBookingSMS = async (phone, templateVars) => {
  return sendFlowSMS(phone, process.env.MSG91_BOOKING_TEMPLATE_ID, {
    customer_name: templateVars.customerName,
    booking_number: templateVars.bookingNumber,
    service_name: templateVars.serviceName,
    slot_date: templateVars.slotDate,
    worker_name: templateVars.workerName
  });
};

const sendWorkerApprovalSMS = async (phone, workerName) => {
  return sendFlowSMS(phone, process.env.MSG91_BOOKING_TEMPLATE_ID, {
    customer_name: workerName,
    status: 'Your profile has been verified! You can now receive bookings on FreshKart.'
  });
};

const sendVendorApprovalSMS = async (phone, shopName) => {
  return sendFlowSMS(phone, process.env.MSG91_ORDER_TEMPLATE_ID, {
    customer_name: shopName,
    status: 'Your shop has been approved! Start adding products on FreshKart.'
  });
};

module.exports = {
  sendOTP,
  sendOrderSMS,
  sendBookingSMS,
  sendWorkerApprovalSMS,
  sendVendorApprovalSMS
};
