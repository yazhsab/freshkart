const auth = require('./auth');

const adminAuth = (req, res, next) => {
  // First run normal auth
  auth(req, res, (err) => {
    if (err) return next(err);
    if (res.headersSent) return;

    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Admin access required'
      });
    }

    next();
  });
};

module.exports = adminAuth;
