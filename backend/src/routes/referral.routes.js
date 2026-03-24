const router = require('express').Router();
const auth = require('../middleware/auth');
const referralController = require('../controllers/referral.controller');

router.get('/code', auth, referralController.getReferralCode);
router.post('/apply', auth, referralController.applyReferral);
router.get('/stats', auth, referralController.getStats);

module.exports = router;
