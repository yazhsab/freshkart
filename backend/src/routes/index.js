const router = require('express').Router();

router.use('/auth', require('./auth.routes'));
router.use('/categories', require('./category.routes'));
router.use('/vendors', require('./vendor.routes'));
router.use('/products', require('./product.routes'));
router.use('/orders', require('./order.routes'));
router.use('/payments', require('./payment.routes'));
router.use('/delivery', require('./delivery.routes'));
router.use('/bookings', require('./booking.routes'));
router.use('/workers', require('./worker.routes'));
router.use('/services', require('./service.routes'));
router.use('/reviews', require('./review.routes'));
router.use('/notifications', require('./notification.routes'));
router.use('/admin', require('./admin.routes'));
router.use('/chat', require('./chat.routes'));
router.use('/coupons', require('./coupon.routes'));
router.use('/wallet', require('./wallet.routes'));
router.use('/loyalty', require('./loyalty.routes'));
router.use('/referral', require('./referral.routes'));

module.exports = router;
