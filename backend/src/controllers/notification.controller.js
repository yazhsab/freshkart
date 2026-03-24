const { supabaseAdmin } = require('../config/supabase');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');

const getNotifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, unread_only } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    let query = supabaseAdmin
      .from('notifications_log')
      .select('*', { count: 'exact' })
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (unread_only === 'true') {
      query = query.eq('is_read', false);
    }

    const { data, error, count } = await query;

    if (error) return errorResponse(res, 'Failed to fetch notifications', 400);

    return paginatedResponse(res, data || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const markAsRead = async (req, res, next) => {
  try {
    const { error } = await supabaseAdmin
      .from('notifications_log')
      .update({ is_read: true })
      .eq('id', req.params.id)
      .eq('user_id', req.user.id);

    if (error) return errorResponse(res, 'Failed to mark as read', 400);

    return successResponse(res, null, 200, 'Marked as read');
  } catch (err) {
    next(err);
  }
};

const markAllAsRead = async (req, res, next) => {
  try {
    const { error } = await supabaseAdmin
      .from('notifications_log')
      .update({ is_read: true })
      .eq('user_id', req.user.id)
      .eq('is_read', false);

    if (error) return errorResponse(res, 'Failed to mark all as read', 400);

    return successResponse(res, null, 200, 'All notifications marked as read');
  } catch (err) {
    next(err);
  }
};

const getUnreadCount = async (req, res, next) => {
  try {
    const { count, error } = await supabaseAdmin
      .from('notifications_log')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', req.user.id)
      .eq('is_read', false);

    if (error) return errorResponse(res, 'Failed to get count', 400);

    return successResponse(res, { unread_count: count || 0 });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  getUnreadCount
};
