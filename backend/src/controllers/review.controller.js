const { supabaseAdmin } = require('../config/supabase');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const createReview = async (req, res, next) => {
  try {
    const { ref_type, ref_id, rating, comment } = req.body;

    if (!ref_type || !ref_id || !rating) {
      return errorResponse(res, 'ref_type, ref_id, and rating are required', 400);
    }

    if (rating < 1 || rating > 5) {
      return errorResponse(res, 'Rating must be between 1 and 5', 400);
    }

    // Verify the user actually has this order/booking
    const table = ref_type === 'order' ? 'orders' : 'bookings';
    const { data: record } = await supabaseAdmin
      .from(table)
      .select('id, customer_id, vendor_id, worker_id, status')
      .eq('id', ref_id)
      .eq('customer_id', req.user.id)
      .single();

    if (!record) return errorResponse(res, 'Record not found', 404);

    const completedStatuses = ref_type === 'order' ? ['delivered'] : ['completed'];
    if (!completedStatuses.includes(record.status)) {
      return errorResponse(res, 'Can only review completed orders/bookings', 400);
    }

    // Check if already reviewed
    const { data: existingReview } = await supabaseAdmin
      .from('reviews')
      .select('id')
      .eq('ref_type', ref_type)
      .eq('ref_id', ref_id)
      .eq('reviewer_id', req.user.id)
      .single();

    if (existingReview) {
      return errorResponse(res, 'You have already reviewed this', 409);
    }

    const reviewData = {
      reviewer_id: req.user.id,
      ref_type,
      ref_id,
      rating,
      comment,
      vendor_id: record.vendor_id || null,
      worker_id: record.worker_id || null
    };

    const { data: review, error } = await supabaseAdmin
      .from('reviews')
      .insert(reviewData)
      .select()
      .single();

    if (error) {
      logger.error('Review creation failed', { error });
      return errorResponse(res, 'Failed to create review', 400);
    }

    // Update average rating for vendor or worker
    if (record.vendor_id) {
      const { data: avgData } = await supabaseAdmin
        .from('reviews')
        .select('rating')
        .eq('vendor_id', record.vendor_id);

      if (avgData?.length) {
        const avgRating = avgData.reduce((s, r) => s + r.rating, 0) / avgData.length;
        await supabaseAdmin
          .from('vendors')
          .update({ rating: Math.round(avgRating * 10) / 10 })
          .eq('id', record.vendor_id);
      }
    }

    if (record.worker_id) {
      const { data: avgData } = await supabaseAdmin
        .from('reviews')
        .select('rating')
        .eq('worker_id', record.worker_id);

      if (avgData?.length) {
        const avgRating = avgData.reduce((s, r) => s + r.rating, 0) / avgData.length;
        await supabaseAdmin
          .from('workers')
          .update({ rating: Math.round(avgRating * 10) / 10 })
          .eq('id', record.worker_id);
      }
    }

    return successResponse(res, review, 201, 'Review submitted');
  } catch (err) {
    next(err);
  }
};

const getOrderReviews = async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('reviews')
      .select('*, profiles!reviewer_id(full_name, avatar_url)')
      .eq('ref_type', 'order')
      .eq('ref_id', req.params.orderId)
      .order('created_at', { ascending: false });

    if (error) return errorResponse(res, 'Failed to fetch reviews', 400);

    return successResponse(res, data || []);
  } catch (err) {
    next(err);
  }
};

const getBookingReviews = async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('reviews')
      .select('*, profiles!reviewer_id(full_name, avatar_url)')
      .eq('ref_type', 'booking')
      .eq('ref_id', req.params.bookingId)
      .order('created_at', { ascending: false });

    if (error) return errorResponse(res, 'Failed to fetch reviews', 400);

    return successResponse(res, data || []);
  } catch (err) {
    next(err);
  }
};

const getVendorReviews = async (req, res, next) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    const { data, error, count } = await supabaseAdmin
      .from('reviews')
      .select('*, profiles!reviewer_id(full_name, avatar_url)', { count: 'exact' })
      .eq('vendor_id', req.params.vendorId)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) return errorResponse(res, 'Failed to fetch reviews', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const getWorkerReviews = async (req, res, next) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    const { data, error, count } = await supabaseAdmin
      .from('reviews')
      .select('*, profiles!reviewer_id(full_name, avatar_url)', { count: 'exact' })
      .eq('worker_id', req.params.workerId)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) return errorResponse(res, 'Failed to fetch reviews', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createReview,
  getOrderReviews,
  getBookingReviews,
  getVendorReviews,
  getWorkerReviews
};
