const { PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { r2Client } = require('../config/r2');
const sharp = require('sharp');
const logger = require('../utils/logger');

const BUCKET = process.env.CLOUDFLARE_R2_BUCKET_NAME;
const PUBLIC_URL = process.env.CLOUDFLARE_R2_PUBLIC_URL;

const uploadFile = async (buffer, key, contentType) => {
  try {
    await r2Client.send(new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: buffer,
      ContentType: contentType
    }));

    const url = `${PUBLIC_URL}/${key}`;
    logger.info('R2 file uploaded', { key, contentType });
    return url;
  } catch (err) {
    logger.error('R2 upload failed', { error: err.message, key });
    throw err;
  }
};

const uploadProductImage = async (buffer, vendorId, filename) => {
  const processed = await sharp(buffer)
    .resize(800, 800, { fit: 'inside', withoutEnlargement: true })
    .webp({ quality: 85 })
    .toBuffer();

  const safeName = filename.replace(/[^a-zA-Z0-9.-]/g, '_');
  const key = `products/${vendorId}/${Date.now()}-${safeName}.webp`;
  return uploadFile(processed, key, 'image/webp');
};

const uploadVendorDoc = async (buffer, vendorId, docType, filename) => {
  const safeName = filename.replace(/[^a-zA-Z0-9.-]/g, '_');
  const key = `docs/vendors/${vendorId}/${docType}/${safeName}`;
  const contentType = filename.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg';
  return uploadFile(buffer, key, contentType);
};

const uploadWorkerDoc = async (buffer, workerId, docType, filename) => {
  const safeName = filename.replace(/[^a-zA-Z0-9.-]/g, '_');
  const key = `docs/workers/${workerId}/${docType}/${safeName}`;
  const contentType = filename.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg';
  return uploadFile(buffer, key, contentType);
};

const uploadAvatarImage = async (buffer, userId) => {
  const processed = await sharp(buffer)
    .resize(200, 200, { fit: 'cover' })
    .webp({ quality: 85 })
    .toBuffer();

  const key = `avatars/${userId}.webp`;
  return uploadFile(processed, key, 'image/webp');
};

const deleteFile = async (key) => {
  try {
    await r2Client.send(new DeleteObjectCommand({
      Bucket: BUCKET,
      Key: key
    }));
    logger.info('R2 file deleted', { key });
  } catch (err) {
    logger.error('R2 delete failed', { error: err.message, key });
    throw err;
  }
};

module.exports = {
  uploadFile,
  uploadProductImage,
  uploadVendorDoc,
  uploadWorkerDoc,
  uploadAvatarImage,
  deleteFile
};
