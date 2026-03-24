const router = require('express').Router();
const controller = require('../controllers/category.controller');

router.get('/', controller.getCategories);
router.get('/:id', controller.getCategoryById);
router.get('/:id/products', controller.getCategoryProducts);

module.exports = router;
