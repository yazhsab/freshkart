const router = require('express').Router();
const adminAuth = require('../middleware/adminAuth');
const { adminLimiter } = require('../middleware/rateLimiter');
const controller = require('../controllers/admin.controller');

router.use(adminAuth);
router.use(adminLimiter);

// Dashboard
router.get('/dashboard/stats', controller.getDashboardStats);
router.get('/dashboard/activity-feed', controller.getActivityFeed);

// Vendors
router.get('/vendors', controller.getVendors);
router.post('/vendors/:id/approve', controller.approveVendor);
router.post('/vendors/:id/suspend', controller.suspendVendor);

// Orders
router.get('/orders', controller.getOrders);
router.patch('/orders/:id/status', controller.updateOrderStatus);
router.patch('/orders/:id/assign-agent', controller.assignAgentToOrder);

// Workers
router.get('/workers', controller.getWorkers);
router.patch('/workers/:id/bgv', controller.updateBGV);
router.post('/workers/:id/approve', controller.approveWorker);
router.post('/workers/:id/suspend', controller.suspendWorker);

// Bookings
router.get('/bookings', controller.getBookings);
router.post('/bookings/:id/assign-worker', controller.assignWorkerToBooking);
router.patch('/bookings/:id/status', controller.updateBookingStatus);

// Customers
router.get('/customers', controller.getCustomers);
router.patch('/customers/:id/ban', controller.banCustomer);

// Payouts
router.get('/payouts/vendors', controller.getVendorPayouts);
router.get('/payouts/workers', controller.getWorkerPayouts);
router.post('/payouts/vendors/:id/mark-paid', controller.markVendorPayoutPaid);
router.post('/payouts/workers/:id/mark-paid', controller.markWorkerPayoutPaid);

// Analytics
router.get('/analytics', controller.getAnalytics);

// Notifications
router.post('/notifications/send', controller.sendBulkNotification);

// Config
router.get('/config', controller.getConfig);
router.put('/config', controller.updateConfig);

// Zones
router.get('/zones', controller.getZones);
router.post('/zones', controller.createZone);
router.put('/zones/:id', controller.updateZone);
router.patch('/zones/:id/toggle', controller.toggleZone);

module.exports = router;
