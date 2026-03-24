const { format, addMinutes, startOfDay: fnsStartOfDay, endOfDay: fnsEndOfDay, startOfMonth: fnsStartOfMonth, isAfter, isBefore, parseISO } = require('date-fns');

const IST_OFFSET_MINUTES = 330; // +5:30

const toIST = (utcDate) => {
  const date = typeof utcDate === 'string' ? new Date(utcDate) : utcDate;
  return addMinutes(date, IST_OFFSET_MINUTES);
};

const formatDate = (date) => {
  const istDate = toIST(date);
  return format(istDate, 'd MMM yyyy');
};

const formatDateTime = (date) => {
  const istDate = toIST(date);
  return format(istDate, 'd MMM yyyy, hh:mm a') + ' IST';
};

const startOfDay = (date) => {
  const d = typeof date === 'string' ? new Date(date) : date;
  const ist = toIST(d);
  const start = fnsStartOfDay(ist);
  return addMinutes(start, -IST_OFFSET_MINUTES);
};

const endOfDay = (date) => {
  const d = typeof date === 'string' ? new Date(date) : date;
  const ist = toIST(d);
  const end = fnsEndOfDay(ist);
  return addMinutes(end, -IST_OFFSET_MINUTES);
};

const startOfMonth = (date) => {
  const d = typeof date === 'string' ? new Date(date) : date;
  const ist = toIST(d);
  const start = fnsStartOfMonth(ist);
  return addMinutes(start, -IST_OFFSET_MINUTES);
};

const isSlotAvailable = (slotDate, slotStart, slotEnd) => {
  const now = new Date();
  const [startH, startM] = slotStart.split(':').map(Number);
  const slotDateTime = new Date(slotDate);
  slotDateTime.setUTCHours(startH - 5, startM - 30, 0, 0); // Convert IST to UTC

  return isAfter(slotDateTime, now);
};

module.exports = {
  toIST,
  formatDate,
  formatDateTime,
  startOfDay,
  endOfDay,
  startOfMonth,
  isSlotAvailable
};
