const router = require('express').Router();
const auth = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');
const validate = require('../middleware/validateRequest');
const walletValidator = require('../validators/wallet.validator');
const walletController = require('../controllers/wallet.controller');

router.get('/', auth, walletController.getWallet);
router.get('/transactions', auth, walletController.getTransactions);
router.post('/topup', auth, validate(walletValidator.topup), walletController.topupWallet);
router.post('/topup/verify', auth, validate(walletValidator.verifyTopup), walletController.verifyTopup);

module.exports = router;
