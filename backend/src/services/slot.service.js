const { supabaseAdmin } = require('../config/supabase');
const { redis } = require('../config/redis');
const logger = require('../utils/logger');

const SLOT_LOCK_TTL = 600; // 10 minutes

const getAvailableSlots = async (workerId, date, serviceDurationMins = 60) => {
  const { data, error } = await supabaseAdmin
    .from('worker_slots')
    .select('*')
    .eq('worker_id', workerId)
    .eq('slot_date', date)
    .eq('is_booked', false)
    .order('slot_start', { ascending: true });

  if (error) {
    logger.error('Failed to fetch available slots', { error, workerId, date });
    return [];
  }

  // Filter out past slots if date is today
  const now = new Date();
  const today = now.toISOString().split('T')[0];

  if (date === today) {
    const currentHour = now.getUTCHours() + 5;
    const currentMin = now.getUTCMinutes() + 30;
    const currentTimeStr = `${String(currentHour % 24).padStart(2, '0')}:${String(currentMin % 60).padStart(2, '0')}`;

    return (data || []).filter((slot) => slot.slot_start > currentTimeStr);
  }

  return data || [];
};

const lockSlotRedis = async (workerId, slotDate, slotStart, bookingId) => {
  const key = `slot:${workerId}:${slotDate}:${slotStart}`;
  const result = await redis.set(key, bookingId, 'EX', SLOT_LOCK_TTL, 'NX');

  if (result !== 'OK') {
    const existingBooking = await redis.get(key);
    logger.warn('Slot already locked', { workerId, slotDate, slotStart, lockedBy: existingBooking });
    return false;
  }

  logger.info('Slot locked in Redis', { workerId, slotDate, slotStart, bookingId });
  return true;
};

const releaseSlotRedis = async (workerId, slotDate, slotStart) => {
  const key = `slot:${workerId}:${slotDate}:${slotStart}`;
  await redis.del(key);
  logger.info('Slot lock released', { workerId, slotDate, slotStart });
};

const confirmSlotBooking = async (workerId, slotDate, slotStart, bookingId) => {
  const { data, error } = await supabaseAdmin
    .from('worker_slots')
    .update({ is_booked: true, booking_id: bookingId })
    .eq('worker_id', workerId)
    .eq('slot_date', slotDate)
    .eq('slot_start', slotStart)
    .select()
    .single();

  if (error) {
    logger.error('Failed to confirm slot booking', { error, workerId, slotDate, slotStart });
    return { data: null, error };
  }

  // Remove Redis lock
  await releaseSlotRedis(workerId, slotDate, slotStart);
  logger.info('Slot booking confirmed', { workerId, slotDate, slotStart, bookingId });
  return { data, error: null };
};

const checkSlotAvailability = async (workerId, slotDate, slotStart) => {
  // Fast path: check Redis lock
  const key = `slot:${workerId}:${slotDate}:${slotStart}`;
  const lockedBy = await redis.get(key);

  if (lockedBy) {
    return { available: false, lockedBy };
  }

  // Slow path: check DB
  const { data, error } = await supabaseAdmin
    .from('worker_slots')
    .select('is_booked, booking_id')
    .eq('worker_id', workerId)
    .eq('slot_date', slotDate)
    .eq('slot_start', slotStart)
    .single();

  if (error || !data) {
    return { available: false, lockedBy: null };
  }

  return { available: !data.is_booked, lockedBy: data.booking_id };
};

const generateDefaultSlots = async (workerId, startDate, days = 30) => {
  const slots = [];
  const timeSlots = ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00'];
  const slotDuration = '01:00';

  for (let d = 0; d < days; d++) {
    const date = new Date(startDate);
    date.setDate(date.getDate() + d);
    const dateStr = date.toISOString().split('T')[0];

    for (const time of timeSlots) {
      const [h, m] = time.split(':').map(Number);
      const endH = h + 1;
      const slotEnd = `${String(endH).padStart(2, '0')}:${String(m).padStart(2, '0')}`;

      slots.push({
        worker_id: workerId,
        slot_date: dateStr,
        slot_start: time,
        slot_end: slotEnd,
        is_booked: false
      });
    }
  }

  // Bulk upsert, skip conflicts
  const { data, error } = await supabaseAdmin
    .from('worker_slots')
    .upsert(slots, {
      onConflict: 'worker_id,slot_date,slot_start',
      ignoreDuplicates: true
    });

  if (error) {
    logger.error('Failed to generate default slots', { error, workerId });
  } else {
    logger.info('Default slots generated', { workerId, count: slots.length });
  }

  return { count: slots.length, error };
};

module.exports = {
  getAvailableSlots,
  lockSlotRedis,
  releaseSlotRedis,
  confirmSlotBooking,
  checkSlotAvailability,
  generateDefaultSlots
};
