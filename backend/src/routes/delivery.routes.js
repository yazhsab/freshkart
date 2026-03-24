const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/delivery.controller');

router.patch('/location', auth, controller.updateLocation);
router.get('/location/:orderId', auth, controller.trackOrder);
router.get('/available-orders', auth, controller.getAvailableOrders);
router.patch('/:orderId/accept', auth, controller.acceptOrder);
router.patch('/:orderId/pickup-confirm', auth, controller.confirmPickup);
router.post('/:orderId/delivery-confirm', auth, controller.confirmDelivery);
router.get('/earnings', auth, controller.getEarnings);

module.exports = router;
