const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/notification.controller');

router.get('/', auth, controller.getNotifications);
router.patch('/:id/read', auth, controller.markAsRead);
router.patch('/read-all', auth, controller.markAllAsRead);
router.get('/unread-count', auth, controller.getUnreadCount);

module.exports = router;
