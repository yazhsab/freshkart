const { supabaseAdmin } = require('../config/supabase');
const couponService = require('../services/coupon.service');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const createCoupon = async (req, res, next) => {
  try {
    const couponData = {
      ...req.body,
      code: req.body.code.toUpperCase(),
      created_by: req.user.id,
    };

    // If vendor, set vendor_id to their vendor
    if (req.user.role === 'vendor') {
      const { data: vendor } = await supabaseAdmin
        .from('vendors')
        .select('id')
        .eq('owner_id', req.user.id)
        .single();
      if (!vendor) return errorResponse(res, 'Vendor not found', 404);
      couponData.vendor_id = vendor.id;
    }

    const { data: coupon, error } = await supabaseAdmin
      .from('coupons')
      .insert(couponData)
      .select()
      .single();

    if (error) {
      if (error.code === '23505') return errorResponse(res, 'Coupon code already exists', 409);
      return errorResponse(res, 'Failed to create coupon', 400);
    }

    logger.info('Coupon created', { couponId: coupon.id, code: coupon.code });
    return successResponse(res, coupon, 201, 'Coupon created');
  } catch (err) {
    next(err);
  }
};

const getCoupons = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, vendor_id } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('coupons')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to);

    // Customers see only active valid coupons
    if (req.user.role === 'customer') {
      query = query
        .eq('is_active', true)
        .lte('valid_from', new Date().toISOString())
        .or(`valid_until.is.null,valid_until.gte.${new Date().toISOString()}`);
      if (vendor_id) query = query.or(`vendor_id.is.null,vendor_id.eq.${vendor_id}`);
    }

    // Vendors see only their coupons
    if (req.user.role === 'vendor') {
      const { data: vendor } = await supabaseAdmin
        .from('vendors')
        .select('id')
        .eq('owner_id', req.user.id)
        .single();
      if (vendor) query = query.eq('vendor_id', vendor.id);
    }

    const { data, error, count } = await query;
    if (error) return errorResponse(res, 'Failed to fetch coupons', 400);
    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getCouponById = async (req, res, next) => {
  try {
    const { data: coupon, error } = await supabaseAdmin
      .from('coupons')
      .select('*')
      .eq('id', req.params.id)
      .single();
    if (error || !coupon) return errorResponse(res, 'Coupon not found', 404);
    return successResponse(res, coupon);
  } catch (err) {
    next(err);
  }
};

const updateCoupon = async (req, res, next) => {
  try {
    const { data: coupon, error } = await supabaseAdmin
      .from('coupons')
      .update(req.body)
      .eq('id', req.params.id)
      .select()
      .single();
    if (error) return errorResponse(res, 'Failed to update coupon', 400);
    return successResponse(res, coupon, 200, 'Coupon updated');
  } catch (err) {
    next(err);
  }
};

const deleteCoupon = async (req, res, next) => {
  try {
    await supabaseAdmin
      .from('coupons')
      .update({ is_active: false })
      .eq('id', req.params.id);
    return successResponse(res, null, 200, 'Coupon deactivated');
  } catch (err) {
    next(err);
  }
};

const applyCoupon = async (req, res, next) => {
  try {
    const { code, subtotal, vendor_id } = req.body;
    const result = await couponService.validateCoupon(code, req.user.id, subtotal, vendor_id);
    if (!result.valid) return errorResponse(res, result.reason, 400);

    return successResponse(res, {
      coupon_id: result.coupon.id,
      code: result.coupon.code,
      title: result.coupon.title,
      title_tamil: result.coupon.title_tamil,
      discount_type: result.discount_type,
      discount_value: result.discount_value,
      discount_amount: result.discount_amount,
    }, 200, 'Coupon applied');
  } catch (err) {
    next(err);
  }
};

const removeCoupon = async (req, res, next) => {
  try {
    return successResponse(res, null, 200, 'Coupon removed');
  } catch (err) {
    next(err);
  }
};

module.exports = { createCoupon, getCoupons, getCouponById, updateCoupon, deleteCoupon, applyCoupon, removeCoupon };
