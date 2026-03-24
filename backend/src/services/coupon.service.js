const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

const validateCoupon = async (code, userId, subtotal, vendorId) => {
  // Fetch coupon
  const { data: coupon, error } = await supabaseAdmin
    .from('coupons')
    .select('*')
    .eq('code', code.toUpperCase())
    .eq('is_active', true)
    .single();

  if (error || !coupon) {
    return { valid: false, reason: 'Invalid coupon code' };
  }

  // Check validity period
  const now = new Date();
  if (coupon.valid_from && new Date(coupon.valid_from) > now) {
    return { valid: false, reason: 'Coupon is not yet active' };
  }
  if (coupon.valid_until && new Date(coupon.valid_until) < now) {
    return { valid: false, reason: 'Coupon has expired' };
  }

  // Check usage limit
  if (coupon.usage_limit && coupon.used_count >= coupon.usage_limit) {
    return { valid: false, reason: 'Coupon usage limit reached' };
  }

  // Check per-user limit
  const { count: userUsage } = await supabaseAdmin
    .from('coupon_usage')
    .select('id', { count: 'exact', head: true })
    .eq('coupon_id', coupon.id)
    .eq('user_id', userId);

  if (coupon.per_user_limit && userUsage >= coupon.per_user_limit) {
    return { valid: false, reason: 'You have already used this coupon' };
  }

  // Check vendor-specific
  if (coupon.vendor_id && coupon.vendor_id !== vendorId) {
    return { valid: false, reason: 'Coupon is not valid for this vendor' };
  }

  // Check minimum order amount
  if (subtotal < coupon.min_order_amount) {
    return { valid: false, reason: `Minimum order of ₹${coupon.min_order_amount} required` };
  }

  // Calculate discount
  let discountAmount;
  if (coupon.discount_type === 'percentage') {
    discountAmount = (subtotal * coupon.discount_value) / 100;
    if (coupon.max_discount) {
      discountAmount = Math.min(discountAmount, coupon.max_discount);
    }
  } else {
    discountAmount = Math.min(coupon.discount_value, subtotal);
  }

  discountAmount = Math.round(discountAmount * 100) / 100;

  return {
    valid: true,
    coupon,
    discount_amount: discountAmount,
    discount_type: coupon.discount_type,
    discount_value: coupon.discount_value,
  };
};

const recordUsage = async (couponId, userId, orderId, discountApplied) => {
  await supabaseAdmin.from('coupon_usage').insert({
    coupon_id: couponId,
    user_id: userId,
    order_id: orderId,
    discount_applied: discountApplied,
  });

  // Increment used_count
  const { data: coupon } = await supabaseAdmin
    .from('coupons')
    .select('used_count')
    .eq('id', couponId)
    .single();

  await supabaseAdmin
    .from('coupons')
    .update({ used_count: (coupon?.used_count || 0) + 1 })
    .eq('id', couponId);
};

module.exports = { validateCoupon, recordUsage };
