const router = require('express').Router();
const auth = require('../middleware/auth');
const validate = require('../middleware/validateRequest');
const { uploadFields } = require('../middleware/upload');
const { registerWorkerSchema, updateWorkerSchema } = require('../validators/worker.validator');
const controller = require('../controllers/worker.controller');

router.post('/register', auth, validate(registerWorkerSchema), controller.register);
router.get('/me', auth, controller.getMyWorker);
router.put('/me', auth, validate(updateWorkerSchema), controller.updateWorker);
router.post('/me/docs', auth, uploadFields([
  { name: 'aadhaar_doc', maxCount: 1 },
  { name: 'police_verification', maxCount: 1 },
  { name: 'skill_certificates', maxCount: 5 }
]), controller.uploadDocs);
router.patch('/me/availability', auth, controller.toggleAvailability);
router.get('/available', auth, controller.getAvailableWorkers);

module.exports = router;
