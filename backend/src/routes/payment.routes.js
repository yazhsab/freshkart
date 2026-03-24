const router = require('express').Router();
const auth = require('../middleware/auth');
const { paymentLimiter } = require('../middleware/rateLimiter');
const validate = require('../middleware/validateRequest');
const { razorpayCreateOrderSchema, razorpayVerifySchema, phonePeInitiateSchema, refundSchema } = require('../validators/payment.validator');
const controller = require('../controllers/payment.controller');

router.post('/razorpay/create-order', auth, paymentLimiter, validate(razorpayCreateOrderSchema), controller.razorpayCreateOrder);
router.post('/razorpay/verify', auth, validate(razorpayVerifySchema), controller.razorpayVerify);
router.post('/phonepe/initiate', auth, paymentLimiter, validate(phonePeInitiateSchema), controller.phonePeInitiate);
router.get('/phonepe/status/:transactionId', auth, controller.phonePeStatus);
router.post('/refund', auth, validate(refundSchema), controller.initiateRefund);

module.exports = router;
