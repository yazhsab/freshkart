const multer = require('multer');

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  if (ALLOWED_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`File type ${file.mimetype} not allowed. Allowed: ${ALLOWED_TYPES.join(', ')}`), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_FILE_SIZE }
});

const uploadSingle = (fieldName = 'file') => upload.single(fieldName);

const uploadMultiple = (fieldName = 'files', maxCount = 5) => upload.array(fieldName, maxCount);

const uploadFields = (fields) => upload.fields(fields);

module.exports = { uploadSingle, uploadMultiple, uploadFields };
