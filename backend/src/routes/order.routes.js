const router = require('express').Router();
const auth = require('../middleware/auth');
const validate = require('../middleware/validateRequest');
const { createOrderSchema, updateOrderStatusSchema, cancelOrderSchema } = require('../validators/order.validator');
const controller = require('../controllers/order.controller');

router.post('/', auth, validate(createOrderSchema), controller.createOrder);
router.get('/', auth, controller.getCustomerOrders);
router.get('/vendor/list', auth, controller.getVendorOrders);
router.get('/agent/list', auth, controller.getAgentOrders);
router.get('/:id', auth, controller.getOrderById);
router.patch('/:id/status', auth, validate(updateOrderStatusSchema), controller.updateOrderStatus);
router.post('/:id/cancel', auth, validate(cancelOrderSchema), controller.cancelOrder);
router.patch('/:id/assign-agent', auth, controller.assignAgent);

module.exports = router;
