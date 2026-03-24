const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

const findZoneForLocation = async (lat, lng) => {
  // First try PostGIS spatial query
  const { data: spatialZone } = await supabaseAdmin.rpc('find_zone_for_point', {
    p_lat: lat,
    p_lng: lng
  });

  if (spatialZone) return spatialZone;

  // Fallback: check pincode-based zones
  return null;
};

const findZoneByPincode = async (pincode) => {
  const { data: zones } = await supabaseAdmin
    .from('zones')
    .select('*')
    .eq('is_active', true)
    .contains('pincodes', [pincode]);

  return zones?.[0] || null;
};

const isLocationServiceable = async (lat, lng, pincode) => {
  // Check by pincode first (faster)
  if (pincode) {
    const zone = await findZoneByPincode(pincode);
    if (zone) return { serviceable: true, zone };
  }

  // Then try spatial
  const zone = await findZoneForLocation(lat, lng);
  if (zone) return { serviceable: true, zone };

  return { serviceable: false, zone: null };
};

const getActiveZones = async () => {
  const { data } = await supabaseAdmin
    .from('zones')
    .select('*')
    .eq('is_active', true)
    .order('name');

  return data || [];
};

const getDeliveryFeeForZone = async (lat, lng, pincode, defaultFee = 30) => {
  const result = await isLocationServiceable(lat, lng, pincode);
  if (result.serviceable && result.zone?.delivery_fee_override != null) {
    return result.zone.delivery_fee_override;
  }
  return defaultFee;
};

module.exports = { findZoneForLocation, findZoneByPincode, isLocationServiceable, getActiveZones, getDeliveryFeeForZone };
