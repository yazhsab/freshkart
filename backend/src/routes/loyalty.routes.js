const router = require('express').Router();
const auth = require('../middleware/auth');
const loyaltyController = require('../controllers/loyalty.controller');

router.get('/', auth, loyaltyController.getLoyalty);
router.get('/transactions', auth, loyaltyController.getTransactions);
router.post('/redeem', auth, loyaltyController.redeemPoints);

module.exports = router;
