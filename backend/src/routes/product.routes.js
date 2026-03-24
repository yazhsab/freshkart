const router = require('express').Router();
const auth = require('../middleware/auth');
const validate = require('../middleware/validateRequest');
const { uploadSingle } = require('../middleware/upload');
const { uploadLimiter } = require('../middleware/rateLimiter');
const { createProductSchema, updateProductSchema, updateStockSchema, searchProductsSchema } = require('../validators/product.validator');
const controller = require('../controllers/product.controller');

router.get('/search', validate(searchProductsSchema, 'query'), controller.search);
router.get('/featured', controller.getFeaturedProducts);
router.get('/', controller.getProducts);
router.get('/:id', controller.getProductById);
router.post('/', auth, validate(createProductSchema), controller.createProduct);
router.put('/:id', auth, validate(updateProductSchema), controller.updateProduct);
router.patch('/:id/stock', auth, validate(updateStockSchema), controller.updateStock);
router.patch('/:id/availability', auth, controller.toggleAvailability);
router.delete('/:id', auth, controller.deleteProduct);
router.post('/:id/image', auth, uploadLimiter, uploadSingle('image'), controller.uploadImage);

module.exports = router;
