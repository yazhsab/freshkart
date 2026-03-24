const { supabaseAdmin } = require('../config/supabase');
const { notificationQueue } = require('../queues/notification.queue');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const createOrGetRoom = async (req, res, next) => {
  try {
    const { order_id, booking_id, other_party_id, other_party_type } = req.body;

    // Check if room already exists
    let query = supabaseAdmin.from('chat_rooms').select('*');
    if (order_id) query = query.eq('order_id', order_id);
    if (booking_id) query = query.eq('booking_id', booking_id);
    query = query.eq('customer_id', req.user.id).eq('other_party_id', other_party_id);

    const { data: existing } = await query.single();
    if (existing) return successResponse(res, existing);

    // Create new room
    const { data: room, error } = await supabaseAdmin
      .from('chat_rooms')
      .insert({
        order_id: order_id || null,
        booking_id: booking_id || null,
        customer_id: req.user.id,
        other_party_id,
        other_party_type
      })
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to create chat room', 400);
    return successResponse(res, room, 201, 'Chat room created');
  } catch (err) {
    next(err);
  }
};

const getRooms = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { data: rooms, error } = await supabaseAdmin
      .from('chat_rooms')
      .select('*, profiles!customer_id(full_name, avatar_url), profiles!other_party_id(full_name, avatar_url)')
      .or(`customer_id.eq.${userId},other_party_id.eq.${userId}`)
      .eq('status', 'active')
      .order('last_message_at', { ascending: false });

    if (error) return errorResponse(res, 'Failed to fetch rooms', 400);
    return successResponse(res, rooms || []);
  } catch (err) {
    next(err);
  }
};

const getMessages = async (req, res, next) => {
  try {
    const { roomId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const from = (page - 1) * limit;
    const to = from + Number(limit) - 1;

    // Verify user is participant
    const { data: room } = await supabaseAdmin
      .from('chat_rooms')
      .select('customer_id, other_party_id')
      .eq('id', roomId)
      .single();

    if (!room || (room.customer_id !== req.user.id && room.other_party_id !== req.user.id)) {
      return errorResponse(res, 'Access denied', 403);
    }

    const { data: messages, error, count } = await supabaseAdmin
      .from('chat_messages')
      .select('*, profiles!sender_id(full_name, avatar_url)', { count: 'exact' })
      .eq('room_id', roomId)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) return errorResponse(res, 'Failed to fetch messages', 400);
    return paginatedResponse(res, messages || [], count || 0, Number(page), Number(limit));
  } catch (err) {
    next(err);
  }
};

const sendMessage = async (req, res, next) => {
  try {
    const { roomId } = req.params;
    const { message, message_type, image_url } = req.body;

    // Verify participant
    const { data: room } = await supabaseAdmin
      .from('chat_rooms')
      .select('*')
      .eq('id', roomId)
      .single();

    if (!room || (room.customer_id !== req.user.id && room.other_party_id !== req.user.id)) {
      return errorResponse(res, 'Access denied', 403);
    }

    const { data: msg, error } = await supabaseAdmin
      .from('chat_messages')
      .insert({
        room_id: roomId,
        sender_id: req.user.id,
        message,
        message_type: message_type || 'text',
        image_url: image_url || null
      })
      .select('*, profiles!sender_id(full_name, avatar_url)')
      .single();

    if (error) return errorResponse(res, 'Failed to send message', 400);

    // Update room last_message_at
    await supabaseAdmin
      .from('chat_rooms')
      .update({ last_message_at: new Date().toISOString() })
      .eq('id', roomId);

    // Send push notification to other party
    const recipientId = room.customer_id === req.user.id ? room.other_party_id : room.customer_id;
    const { data: sender } = await supabaseAdmin
      .from('profiles')
      .select('full_name')
      .eq('id', req.user.id)
      .single();

    await notificationQueue.add('chat-message', {
      recipientId,
      senderName: sender?.full_name || 'Someone',
      message: message.substring(0, 100),
      roomId
    });

    return successResponse(res, msg, 201, 'Message sent');
  } catch (err) {
    next(err);
  }
};

const markRead = async (req, res, next) => {
  try {
    const { roomId } = req.params;
    await supabaseAdmin
      .from('chat_messages')
      .update({ is_read: true })
      .eq('room_id', roomId)
      .neq('sender_id', req.user.id)
      .eq('is_read', false);

    return successResponse(res, null, 200, 'Messages marked as read');
  } catch (err) {
    next(err);
  }
};

module.exports = { createOrGetRoom, getRooms, getMessages, sendMessage, markRead };
