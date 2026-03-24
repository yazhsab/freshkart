const { olaApi } = require('../config/olamaps');
const { supabaseAdmin } = require('../config/supabase');
const logger = require('../utils/logger');

const geocode = async (address) => {
  try {
    const response = await olaApi.get('/places/v1/geocode', {
      params: { address }
    });

    const result = response.data?.geocodingResults?.[0];
    if (!result) return null;

    return {
      lat: result.geometry.location.lat,
      lng: result.geometry.location.lng,
      formattedAddress: result.formatted_address
    };
  } catch (err) {
    logger.error('Ola Maps geocode failed', { error: err.message, address });
    return null;
  }
};

const reverseGeocode = async (lat, lng) => {
  try {
    const response = await olaApi.get('/places/v1/reverse-geocode', {
      params: { latlng: `${lat},${lng}` }
    });

    const result = response.data?.results?.[0];
    if (!result) return null;

    const pincodeComponent = result.address_components?.find(
      (c) => c.types?.includes('postal_code')
    );

    const cityComponent = result.address_components?.find(
      (c) => c.types?.includes('locality')
    );

    return {
      address: result.formatted_address,
      pincode: pincodeComponent?.long_name || null,
      city: cityComponent?.long_name || null
    };
  } catch (err) {
    logger.error('Ola Maps reverse geocode failed', { error: err.message, lat, lng });
    return null;
  }
};

const getDirections = async (originLat, originLng, destLat, destLng) => {
  try {
    const response = await olaApi.get('/routing/v1/directions', {
      params: {
        origin: `${originLat},${originLng}`,
        destination: `${destLat},${destLng}`
      }
    });

    const route = response.data?.routes?.[0];
    if (!route) return null;

    return {
      distanceMeters: route.legs?.[0]?.distance?.value || 0,
      durationSeconds: route.legs?.[0]?.duration?.value || 0,
      polyline: route.overview_polyline?.points || ''
    };
  } catch (err) {
    logger.error('Ola Maps directions failed', { error: err.message });
    return null;
  }
};

const searchNearbyVendors = async (lat, lng, radiusKm = 5) => {
  try {
    const { data, error } = await supabaseAdmin.rpc('search_nearby_vendors', {
      p_lat: lat,
      p_lng: lng,
      p_radius_meters: radiusKm * 1000
    });

    if (error) {
      logger.error('Nearby vendors query failed', { error });
      return [];
    }

    return data || [];
  } catch (err) {
    logger.error('searchNearbyVendors failed', { error: err.message });
    return [];
  }
};

const estimateDeliveryTime = async (vendorLat, vendorLng, customerLat, customerLng) => {
  const directions = await getDirections(vendorLat, vendorLng, customerLat, customerLng);
  if (!directions) return 30; // Default 30 mins

  const travelMinutes = Math.ceil(directions.durationSeconds / 60);
  const prepBuffer = 10;
  return travelMinutes + prepBuffer;
};

module.exports = {
  geocode,
  reverseGeocode,
  getDirections,
  searchNearbyVendors,
  estimateDeliveryTime
};
