const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/service.controller');

router.get('/categories', controller.getCategories);
router.get('/categories/:id', controller.getCategoryById);
router.get('/categories/:id/workers', controller.getWorkersByCategory);
router.get('/categories/:id/vendors', controller.getWorkersByCategory);

module.exports = router;
