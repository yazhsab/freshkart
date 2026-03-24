const router = require('express').Router();
const auth = require('../middleware/auth');
const chatController = require('../controllers/chat.controller');

router.post('/rooms', auth, chatController.createOrGetRoom);
router.get('/rooms', auth, chatController.getRooms);
router.get('/rooms/:roomId/messages', auth, chatController.getMessages);
router.post('/rooms/:roomId/messages', auth, chatController.sendMessage);
router.patch('/rooms/:roomId/read', auth, chatController.markRead);

module.exports = router;
