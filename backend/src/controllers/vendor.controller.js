const { supabaseAdmin } = require('../config/supabase');
const r2Service = require('../services/r2.service');
const olamapsService = require('../services/olamaps.service');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const register = async (req, res, next) => {
  try {
    // Check no existing vendor for this owner
    const { data: existing } = await supabaseAdmin
      .from('vendors')
      .select('id')
      .eq('owner_id', req.user.id)
      .single();

    if (existing) {
      return errorResponse(res, 'You already have a registered vendor', 409);
    }

    const vendorData = {
      owner_id: req.user.id,
      shop_name: req.body.shop_name,
      description: req.body.description,
      category: req.body.category,
      address: req.body.address,
      phone: `+91${req.body.phone}`,
      lat: req.body.address.lat,
      lng: req.body.address.lng,
      fssai_number: req.body.fssai_number,
      gstin: req.body.gstin,
      opening_time: req.body.opening_time,
      closing_time: req.body.closing_time,
      working_days: req.body.working_days,
      delivery_radius_km: req.body.delivery_radius_km,
      min_order_amount: req.body.min_order_amount,
      free_delivery_above: req.body.free_delivery_above,
      is_approved: false,
      is_active: false,
      is_open: false
    };

    const { data: vendor, error } = await supabaseAdmin
      .from('vendors')
      .insert(vendorData)
      .select()
      .single();

    if (error) {
      logger.error('Vendor registration failed', { error, userId: req.user.id });
      return errorResponse(res, 'Failed to register vendor', 400);
    }

    // Update profile role
    await supabaseAdmin
      .from('profiles')
      .update({ role: 'vendor' })
      .eq('id', req.user.id);

    return successResponse(res, { vendor }, 201, 'Registration submitted. Pending approval.');
  } catch (err) {
    next(err);
  }
};

const getMyVendor = async (req, res, next) => {
  try {
    const { data: vendor, error } = await supabaseAdmin
      .from('vendors')
      .select('*')
      .eq('owner_id', req.user.id)
      .single();

    if (error || !vendor) {
      return errorResponse(res, 'Vendor not found', 404);
    }

    // Get today's stats
    const today = new Date().toISOString().split('T')[0];
    const { count: orderCount } = await supabaseAdmin
      .from('orders')
      .select('*', { count: 'exact', head: true })
      .eq('vendor_id', vendor.id)
      .gte('created_at', `${today}T00:00:00`)
      .lte('created_at', `${today}T23:59:59`);

    const { data: revenueData } = await supabaseAdmin
      .from('orders')
      .select('final_amount')
      .eq('vendor_id', vendor.id)
      .eq('status', 'delivered')
      .gte('created_at', `${today}T00:00:00`);

    const todayRevenue = (revenueData || []).reduce((sum, o) => sum + Number(o.final_amount), 0);

    return successResponse(res, {
      ...vendor,
      today_order_count: orderCount || 0,
      today_revenue: todayRevenue
    });
  } catch (err) {
    next(err);
  }
};

const updateVendor = async (req, res, next) => {
  try {
    const { data: vendor } = await supabaseAdmin
      .from('vendors')
      .select('id')
      .eq('owner_id', req.user.id)
      .single();

    if (!vendor) {
      return errorResponse(res, 'Vendor not found', 404);
    }

    const updates = {};
    const allowed = ['shop_name', 'description', 'address', 'opening_time', 'closing_time', 'working_days', 'delivery_radius_km', 'min_order_amount', 'free_delivery_above'];
    for (const key of allowed) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }

    if (updates.address) {
      updates.lat = updates.address.lat;
      updates.lng = updates.address.lng;
    }

    const { data: updated, error } = await supabaseAdmin
      .from('vendors')
      .update(updates)
      .eq('id', vendor.id)
      .select()
      .single();

    if (error) {
      return errorResponse(res, 'Failed to update vendor', 400);
    }

    return successResponse(res, updated, 200, 'Vendor updated');
  } catch (err) {
    next(err);
  }
};

const toggleOpen = async (req, res, next) => {
  try {
    const { data: vendor } = await supabaseAdmin
      .from('vendors')
      .select('id, is_open, is_approved')
      .eq('owner_id', req.user.id)
      .single();

    if (!vendor) {
      return errorResponse(res, 'Vendor not found', 404);
    }

    if (!vendor.is_approved) {
      return errorResponse(res, 'Vendor not yet approved', 403);
    }

    const { data: updated, error } = await supabaseAdmin
      .from('vendors')
      .update({ is_open: !vendor.is_open })
      .eq('id', vendor.id)
      .select('is_open')
      .single();

    if (error) {
      return errorResponse(res, 'Failed to toggle status', 400);
    }

    return successResponse(res, { is_open: updated.is_open });
  } catch (err) {
    next(err);
  }
};

const uploadDocs = async (req, res, next) => {
  try {
    const { data: vendor } = await supabaseAdmin
      .from('vendors')
      .select('id')
      .eq('owner_id', req.user.id)
      .single();

    if (!vendor) {
      return errorResponse(res, 'Vendor not found', 404);
    }

    const updates = {};

    if (req.files?.fssai_doc?.[0]) {
      updates.fssai_doc_url = await r2Service.uploadVendorDoc(
        req.files.fssai_doc[0].buffer, vendor.id, 'fssai', req.files.fssai_doc[0].originalname
      );
    }

    if (req.files?.gstin_doc?.[0]) {
      updates.gstin_doc_url = await r2Service.uploadVendorDoc(
        req.files.gstin_doc[0].buffer, vendor.id, 'gstin', req.files.gstin_doc[0].originalname
      );
    }

    if (Object.keys(updates).length === 0) {
      return errorResponse(res, 'No documents uploaded', 400);
    }

    await supabaseAdmin
      .from('vendors')
      .update(updates)
      .eq('id', vendor.id);

    return successResponse(res, updates, 200, 'Documents uploaded');
  } catch (err) {
    next(err);
  }
};

const getNearbyVendors = async (req, res, next) => {
  try {
    const { lat, lng, radius = 10, page = 1, limit = 20 } = req.query;

    if (!lat || !lng) {
      return errorResponse(res, 'lat and lng are required', 400);
    }

    const parsedRadius = Math.min(Number(radius), 50);
    const userLat = Number(lat);
    const userLng = Number(lng);

    // Try RPC first, fallback to simple query
    let vendors = await olamapsService.searchNearbyVendors(userLat, userLng, parsedRadius);

    // Fallback: fetch all active vendors and filter by distance
    if (!vendors || vendors.length === 0) {
      const { data: allVendors, error } = await supabaseAdmin
        .from('vendors')
        .select('id, shop_name, shop_name_tamil, description, address, city, lat, lng, opening_time, closing_time, delivery_radius_km, is_open, rating, total_ratings')
        .eq('is_approved', true)
        .eq('is_active', true);

      if (!error && allVendors) {
        vendors = allVendors
          .map(v => {
            // Haversine distance calculation
            const R = 6371; // km
            const dLat = (v.lat - userLat) * Math.PI / 180;
            const dLng = (v.lng - userLng) * Math.PI / 180;
            const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                      Math.cos(userLat * Math.PI / 180) * Math.cos(v.lat * Math.PI / 180) *
                      Math.sin(dLng/2) * Math.sin(dLng/2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            const distance = R * c;
            return { ...v, distance_km: Math.round(distance * 10) / 10 };
          })
          .filter(v => v.distance_km <= parsedRadius)
          .sort((a, b) => a.distance_km - b.distance_km);
      }
    }

    return successResponse(res, vendors || []);
  } catch (err) {
    next(err);
  }
};

const getVendorById = async (req, res, next) => {
  try {
    const { data: vendor, error } = await supabaseAdmin
      .from('vendors')
      .select('id, shop_name, shop_name_tamil, description, address, city, pincode, lat, lng, opening_time, closing_time, working_days, delivery_radius_km, is_open, rating, total_ratings, created_at')
      .eq('id', req.params.id)
      .eq('is_approved', true)
      .eq('is_active', true)
      .single();

    if (error) {
      logger.error('Failed to fetch vendor detail', {
        vendorId: req.params.id,
        error
      });
      return errorResponse(res, 'Failed to load vendor', 500);
    }

    if (!vendor) {
      return errorResponse(res, 'Vendor not found', 404);
    }

    return successResponse(res, vendor);
  } catch (err) {
    next(err);
  }
};

const getVendorProducts = async (req, res, next) => {
  try {
    const { data: products, error } = await supabaseAdmin
      .from('products')
      .select('*')
      .eq('vendor_id', req.params.id)
      .eq('is_available', true)
      .order('sort_order', { ascending: true })
      .order('name', { ascending: true });

    if (error) {
      return errorResponse(res, 'Failed to fetch products', 400);
    }

    return successResponse(res, products || []);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  register,
  getMyVendor,
  updateVendor,
  toggleOpen,
  uploadDocs,
  getNearbyVendors,
  getVendorById,
  getVendorProducts
};
