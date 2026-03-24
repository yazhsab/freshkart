const router = require('express').Router();
const auth = require('../middleware/auth');
const validate = require('../middleware/validateRequest');
const { uploadFields } = require('../middleware/upload');
const { registerVendorSchema, updateVendorSchema } = require('../validators/vendor.validator');
const controller = require('../controllers/vendor.controller');
const reviewController = require('../controllers/review.controller');

router.post('/register', auth, validate(registerVendorSchema), controller.register);
router.get('/me', auth, controller.getMyVendor);
router.put('/me', auth, validate(updateVendorSchema), controller.updateVendor);
router.patch('/me/toggle-open', auth, controller.toggleOpen);
router.post('/me/docs', auth, uploadFields([
  { name: 'fssai_doc', maxCount: 1 },
  { name: 'gstin_doc', maxCount: 1 }
]), controller.uploadDocs);
router.get('/nearby', controller.getNearbyVendors);
router.get('/:id/reviews', reviewController.getVendorReviews);
router.get('/:id', controller.getVendorById);
router.get('/:id/products', controller.getVendorProducts);

module.exports = router;
