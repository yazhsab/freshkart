const { supabaseAdmin } = require('../config/supabase');
const r2Service = require('../services/r2.service');
const { orderQueue } = require('../queues/order.queue');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const verifyVendorOwnership = async (userId, productId) => {
  const { data: vendor } = await supabaseAdmin
    .from('vendors')
    .select('id')
    .eq('owner_id', userId)
    .single();

  if (!vendor) return { vendor: null, product: null, error: 'Vendor not found' };

  const { data: product } = await supabaseAdmin
    .from('products')
    .select('*')
    .eq('id', productId)
    .eq('vendor_id', vendor.id)
    .single();

  if (!product) return { vendor, product: null, error: 'Product not found or not owned by you' };

  return { vendor, product, error: null };
};

const getFeaturedProducts = async (req, res, next) => {
  try {
    // Return a curated mix of products: best sellers / highest rated / newest
    const { data, error } = await supabaseAdmin
      .from('products')
      .select('*, vendors!inner(shop_name, is_open)')
      .eq('is_available', true)
      .eq('vendors.is_approved', true)
      .eq('vendors.is_active', true)
      .order('created_at', { ascending: false })
      .limit(20);

    if (error) {
      return errorResponse(res, 'Failed to fetch featured products', 400);
    }

    return successResponse(res, data || []);
  } catch (err) {
    next(err);
  }
};

const search = async (req, res, next) => {
  try {
    const { q, lat, lng, page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('products')
      .select('*, vendors!inner(id, shop_name, lat, lng, is_open)', { count: 'exact' })
      .eq('is_available', true)
      .eq('vendors.is_approved', true)
      .eq('vendors.is_active', true)
      .textSearch('name', q, { type: 'websearch' })
      .range(from, to);

    const { data, error, count } = await query;

    if (error) {
      // Fallback to ilike search if full-text search fails
      const { data: fallbackData, error: fallbackError, count: fallbackCount } = await supabaseAdmin
        .from('products')
        .select('*, vendors!inner(id, shop_name, lat, lng, is_open)', { count: 'exact' })
        .eq('is_available', true)
        .eq('vendors.is_approved', true)
        .eq('vendors.is_active', true)
        .ilike('name', `%${q}%`)
        .range(from, to);

      if (fallbackError) {
        return errorResponse(res, 'Search failed', 400);
      }

      return paginatedResponse(res, fallbackData || [], fallbackCount || 0, Number(page), Number(limit));
    }

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getProducts = async (req, res, next) => {
  try {
    const { vendor_id, category_id, page = 1, limit = 20 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('products')
      .select('*, vendors!inner(shop_name, is_open)', { count: 'exact' })
      .eq('is_available', true)
      .eq('vendors.is_approved', true)
      .eq('vendors.is_active', true)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (vendor_id) query = query.eq('vendor_id', vendor_id);
    if (category_id) query = query.eq('category_id', category_id);

    const { data, error, count } = await query;

    if (error) {
      return errorResponse(res, 'Failed to fetch products', 400);
    }

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getProductById = async (req, res, next) => {
  try {
    const { data: product, error } = await supabaseAdmin
      .from('products')
      .select('*, vendors!inner(shop_name, is_open)')
      .eq('id', req.params.id)
      .eq('vendors.is_approved', true)
      .eq('vendors.is_active', true)
      .single();

    if (error || !product) {
      return errorResponse(res, 'Product not found', 404);
    }

    return successResponse(res, product);
  } catch (err) {
    next(err);
  }
};

const createProduct = async (req, res, next) => {
  try {
    const { data: vendor } = await supabaseAdmin
      .from('vendors')
      .select('id, is_approved')
      .eq('owner_id', req.user.id)
      .single();

    if (!vendor) {
      return errorResponse(res, 'Vendor not found', 404);
    }

    if (!vendor.is_approved) {
      return errorResponse(res, 'Vendor not yet approved', 403);
    }

    const productData = {
      vendor_id: vendor.id,
      name: req.body.name,
      description: req.body.description,
      category_id: req.body.category_id,
      category_name: req.body.category_name,
      price: req.body.price,
      mrp: req.body.mrp,
      unit: req.body.unit,
      unit_value: req.body.unit_value,
      stock_quantity: req.body.stock_quantity,
      low_stock_threshold: req.body.low_stock_threshold,
      is_available: req.body.is_available,
      tags: req.body.tags
    };

    const { data: product, error } = await supabaseAdmin
      .from('products')
      .insert(productData)
      .select()
      .single();

    if (error) {
      logger.error('Product creation failed', { error, vendorId: vendor.id });
      return errorResponse(res, 'Failed to create product', 400);
    }

    return successResponse(res, product, 201, 'Product created');
  } catch (err) {
    next(err);
  }
};

const updateProduct = async (req, res, next) => {
  try {
    const { vendor, product, error: ownerError } = await verifyVendorOwnership(req.user.id, req.params.id);
    if (ownerError) return errorResponse(res, ownerError, 404);

    const { data: updated, error } = await supabaseAdmin
      .from('products')
      .update(req.body)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) {
      return errorResponse(res, 'Failed to update product', 400);
    }

    return successResponse(res, updated, 200, 'Product updated');
  } catch (err) {
    next(err);
  }
};

const updateStock = async (req, res, next) => {
  try {
    const { vendor, product, error: ownerError } = await verifyVendorOwnership(req.user.id, req.params.id);
    if (ownerError) return errorResponse(res, ownerError, 404);

    const { stock_quantity } = req.body;

    const updates = { stock_quantity };
    if (stock_quantity === 0) {
      updates.is_available = false;
    }

    const { data: updated, error } = await supabaseAdmin
      .from('products')
      .update(updates)
      .eq('id', req.params.id)
      .select('id, stock_quantity, is_available, low_stock_threshold')
      .single();

    if (error) {
      return errorResponse(res, 'Failed to update stock', 400);
    }

    // Queue low stock alert if needed
    if (updated.stock_quantity <= updated.low_stock_threshold && updated.stock_quantity > 0) {
      await orderQueue.add('low-stock-alert', { productId: updated.id });
    }

    return successResponse(res, updated);
  } catch (err) {
    next(err);
  }
};

const toggleAvailability = async (req, res, next) => {
  try {
    const { vendor, product, error: ownerError } = await verifyVendorOwnership(req.user.id, req.params.id);
    if (ownerError) return errorResponse(res, ownerError, 404);

    const { data: updated, error } = await supabaseAdmin
      .from('products')
      .update({ is_available: !product.is_available })
      .eq('id', req.params.id)
      .select('id, is_available')
      .single();

    if (error) {
      return errorResponse(res, 'Failed to toggle availability', 400);
    }

    return successResponse(res, updated);
  } catch (err) {
    next(err);
  }
};

const deleteProduct = async (req, res, next) => {
  try {
    const { vendor, product, error: ownerError } = await verifyVendorOwnership(req.user.id, req.params.id);
    if (ownerError) return errorResponse(res, ownerError, 404);

    const { error } = await supabaseAdmin
      .from('products')
      .delete()
      .eq('id', req.params.id);

    if (error) {
      return errorResponse(res, 'Failed to delete product', 400);
    }

    return successResponse(res, null, 200, 'Product deleted');
  } catch (err) {
    next(err);
  }
};

const uploadImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return errorResponse(res, 'No image file provided', 400);
    }

    const { vendor, product, error: ownerError } = await verifyVendorOwnership(req.user.id, req.params.id);
    if (ownerError) return errorResponse(res, ownerError, 404);

    const imageUrl = await r2Service.uploadProductImage(
      req.file.buffer, vendor.id, req.file.originalname
    );

    await supabaseAdmin
      .from('products')
      .update({ image_url: imageUrl })
      .eq('id', req.params.id);

    return successResponse(res, { image_url: imageUrl }, 200, 'Image uploaded');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getFeaturedProducts,
  search,
  getProducts,
  getProductById,
  createProduct,
  updateProduct,
  updateStock,
  toggleAvailability,
  deleteProduct,
  uploadImage
};
