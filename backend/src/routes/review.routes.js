const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/review.controller');

router.post('/', auth, controller.createReview);
router.get('/order/:orderId', controller.getOrderReviews);
router.get('/booking/:bookingId', controller.getBookingReviews);
router.get('/vendor/:vendorId', controller.getVendorReviews);
router.get('/worker/:workerId', controller.getWorkerReviews);

module.exports = router;
