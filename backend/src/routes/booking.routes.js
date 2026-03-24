const router = require('express').Router();
const auth = require('../middleware/auth');
const validate = require('../middleware/validateRequest');
const { createBookingSchema, updateBookingStatusSchema, checkinSchema, checkoutSchema, addSlotsSchema } = require('../validators/booking.validator');
const controller = require('../controllers/booking.controller');

router.post('/', auth, validate(createBookingSchema), controller.createBooking);
router.get('/', auth, controller.getCustomerBookings);
router.get('/worker/list', auth, controller.getWorkerBookings);
router.get('/worker/slots', auth, controller.getWorkerSlots);
router.post('/worker/slots', auth, validate(addSlotsSchema), controller.addWorkerSlots);
router.delete('/worker/slots/:slotId', auth, controller.deleteWorkerSlot);
router.get('/:id', auth, controller.getBookingById);
router.patch('/:id/status', auth, validate(updateBookingStatusSchema), controller.updateBookingStatus);
router.post('/:id/cancel', auth, controller.cancelBooking);
router.post('/:id/checkin', auth, validate(checkinSchema), controller.workerCheckin);
router.post('/:id/checkout', auth, validate(checkoutSchema), controller.workerCheckout);

module.exports = router;
