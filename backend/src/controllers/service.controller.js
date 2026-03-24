const { supabaseAdmin } = require('../config/supabase');
const { successResponse, errorResponse } = require('../utils/response');

const getCategories = async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('service_categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true });

    if (error) return errorResponse(res, 'Failed to fetch categories', 400);

    return successResponse(res, data || []);
  } catch (err) {
    next(err);
  }
};

const getCategoryById = async (req, res, next) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('service_categories')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error || !data) return errorResponse(res, 'Category not found', 404);

    return successResponse(res, data);
  } catch (err) {
    next(err);
  }
};

const getWorkersByCategory = async (req, res, next) => {
  try {
    const { pincode, date, time } = req.query;

    let query = supabaseAdmin
      .from('workers')
      .select('id, full_name, experience_years, rating, total_jobs_completed, languages, profiles!user_id(full_name, avatar_url)')
      .eq('is_approved', true)
      .eq('is_available', true)
      .contains('service_category_ids', [req.params.id]);

    if (pincode) {
      query = query.contains('service_pincodes', [pincode]);
    }

    const { data: workers, error } = await query;

    if (error) return errorResponse(res, 'Failed to fetch workers', 400);

    let available = workers || [];

    if (date && time) {
      const workerIds = available.map((w) => w.id);
      if (workerIds.length > 0) {
        const { data: slots } = await supabaseAdmin
          .from('worker_slots')
          .select('worker_id')
          .in('worker_id', workerIds)
          .eq('slot_date', date)
          .eq('slot_start', time)
          .eq('is_booked', false);

        const availableIds = new Set((slots || []).map((s) => s.worker_id));
        available = available.filter((w) => availableIds.has(w.id));
      }
    }

    return successResponse(res, available);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getCategories,
  getCategoryById,
  getWorkersByCategory
};
