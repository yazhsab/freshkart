const router = require('express').Router();
const controller = require('../controllers/webhook.controller');

// No auth middleware — webhook signature verification instead
// Raw body parsing is applied at app level for /webhooks
router.post('/razorpay', controller.razorpayWebhook);
router.post('/phonepe', controller.phonePeWebhook);

module.exports = router;
