const router = require('express').Router();
const auth = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');
const validate = require('../middleware/validateRequest');
const { uploadSingle } = require('../middleware/upload');
const { sendOTPSchema, verifyOTPSchema, updateProfileSchema } = require('../validators/auth.validator');
const controller = require('../controllers/auth.controller');

router.post('/send-otp', authLimiter, validate(sendOTPSchema), controller.sendOTP);
router.post('/verify-otp', authLimiter, validate(verifyOTPSchema), controller.verifyOTP);
router.post('/refresh-token', controller.refreshToken);
router.post('/logout', auth, controller.logout);
router.get('/profile', auth, controller.getProfile);
router.put('/profile', auth, validate(updateProfileSchema), controller.updateProfile);
router.post('/profile/avatar', auth, uploadSingle('avatar'), controller.uploadAvatar);
router.post('/fcm-token', auth, controller.saveFcmToken);
router.post('/google', controller.googleSignIn);
router.post('/apple', controller.appleSignIn);
router.post('/firebase-phone', authLimiter, controller.firebasePhoneAuth);

module.exports = router;
