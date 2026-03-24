const router = require('express').Router();
const auth = require('../middleware/auth');
const validate = require('../middleware/validateRequest');
const couponValidator = require('../validators/coupon.validator');
const couponController = require('../controllers/coupon.controller');

router.post('/', auth, validate(couponValidator.createCoupon), couponController.createCoupon);
router.get('/', auth, couponController.getCoupons);
router.get('/:id', auth, couponController.getCouponById);
router.put('/:id', auth, validate(couponValidator.updateCoupon), couponController.updateCoupon);
router.delete('/:id', auth, couponController.deleteCoupon);
router.post('/apply', auth, validate(couponValidator.applyCoupon), couponController.applyCoupon);
router.post('/remove', auth, couponController.removeCoupon);

module.exports = router;
