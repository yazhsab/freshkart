const { supabaseAdmin } = require('../config/supabase');
const r2Service = require('../services/r2.service');
const slotService = require('../services/slot.service');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/response');
const logger = require('../utils/logger');

const register = async (req, res, next) => {
  try {
    // Check no existing worker
    const { data: existing } = await supabaseAdmin
      .from('workers')
      .select('id')
      .eq('user_id', req.user.id)
      .single();

    if (existing) {
      return errorResponse(res, 'You already have a worker registration', 409);
    }

    const workerData = {
      user_id: req.user.id,
      full_name: req.body.full_name,
      phone: `+91${req.body.phone}`,
      service_category_ids: req.body.service_category_ids,
      service_pincodes: req.body.service_pincodes,
      experience_years: req.body.experience_years,
      languages: req.body.languages,
      address: req.body.address,
      aadhaar_number: req.body.aadhaar_number,
      is_approved: false,
      is_available: false,
      bgv_status: 'pending'
    };

    const { data: worker, error } = await supabaseAdmin
      .from('workers')
      .insert(workerData)
      .select()
      .single();

    if (error) {
      logger.error('Worker registration failed', { error, userId: req.user.id });
      return errorResponse(res, 'Failed to register worker', 400);
    }

    // Update profile role
    await supabaseAdmin
      .from('profiles')
      .update({ role: 'worker' })
      .eq('id', req.user.id);

    // Generate default slots for next 30 days
    await slotService.generateDefaultSlots(worker.id, new Date(), 30);

    return successResponse(res, { worker }, 201, 'Registration submitted. Pending BGV review.');
  } catch (err) {
    next(err);
  }
};

const getMyWorker = async (req, res, next) => {
  try {
    const { data: worker, error } = await supabaseAdmin
      .from('workers')
      .select('*, profiles!user_id(full_name, email, phone, avatar_url)')
      .eq('user_id', req.user.id)
      .single();

    if (error || !worker) {
      return errorResponse(res, 'Worker profile not found', 404);
    }

    // Get upcoming bookings count
    const { count: upcomingBookings } = await supabaseAdmin
      .from('bookings')
      .select('*', { count: 'exact', head: true })
      .eq('worker_id', worker.id)
      .in('status', ['assigned', 'confirmed'])
      .gte('slot_date', new Date().toISOString().split('T')[0]);

    return successResponse(res, {
      ...worker,
      upcoming_bookings: upcomingBookings || 0
    });
  } catch (err) {
    next(err);
  }
};

const updateWorker = async (req, res, next) => {
  try {
    const { data: worker } = await supabaseAdmin
      .from('workers')
      .select('id')
      .eq('user_id', req.user.id)
      .single();

    if (!worker) return errorResponse(res, 'Worker not found', 404);

    const { data: updated, error } = await supabaseAdmin
      .from('workers')
      .update(req.body)
      .eq('id', worker.id)
      .select()
      .single();

    if (error) return errorResponse(res, 'Failed to update', 400);

    return successResponse(res, updated, 200, 'Worker profile updated');
  } catch (err) {
    next(err);
  }
};

const uploadDocs = async (req, res, next) => {
  try {
    const { data: worker } = await supabaseAdmin
      .from('workers')
      .select('id')
      .eq('user_id', req.user.id)
      .single();

    if (!worker) return errorResponse(res, 'Worker not found', 404);

    const updates = {};
    const uploadedDocs = {};

    if (req.files?.aadhaar_doc?.[0]) {
      const url = await r2Service.uploadWorkerDoc(
        req.files.aadhaar_doc[0].buffer, worker.id, 'aadhaar', req.files.aadhaar_doc[0].originalname
      );
      updates.aadhaar_doc_url = url;
      uploadedDocs.aadhaar_doc = url;
    }

    if (req.files?.police_verification?.[0]) {
      const url = await r2Service.uploadWorkerDoc(
        req.files.police_verification[0].buffer, worker.id, 'police_verification', req.files.police_verification[0].originalname
      );
      updates.police_verification_url = url;
      uploadedDocs.police_verification = url;
    }

    if (req.files?.skill_certificates?.length) {
      const urls = [];
      for (const file of req.files.skill_certificates) {
        const url = await r2Service.uploadWorkerDoc(
          file.buffer, worker.id, 'certificates', file.originalname
        );
        urls.push(url);
      }
      updates.skill_certificate_urls = urls;
      uploadedDocs.skill_certificates = urls;
    }

    if (Object.keys(updates).length === 0) {
      return errorResponse(res, 'No documents uploaded', 400);
    }

    updates.bgv_status = 'in_progress';

    await supabaseAdmin
      .from('workers')
      .update(updates)
      .eq('id', worker.id);

    // Notify admin
    await supabaseAdmin.from('notifications_log').insert({
      user_id: req.user.id,
      type: 'worker_docs_uploaded',
      title: 'Worker Documents Uploaded',
      body: `Worker ${worker.id} uploaded documents for BGV review`,
      ref_type: 'worker',
      ref_id: worker.id
    });

    return successResponse(res, { uploaded_docs: uploadedDocs }, 200, 'Documents uploaded');
  } catch (err) {
    next(err);
  }
};

const toggleAvailability = async (req, res, next) => {
  try {
    const { data: worker } = await supabaseAdmin
      .from('workers')
      .select('id, is_available, is_approved')
      .eq('user_id', req.user.id)
      .single();

    if (!worker) return errorResponse(res, 'Worker not found', 404);
    if (!worker.is_approved) return errorResponse(res, 'Worker not yet approved', 403);

    const { data: updated, error } = await supabaseAdmin
      .from('workers')
      .update({ is_available: !worker.is_available })
      .eq('id', worker.id)
      .select('is_available')
      .single();

    if (error) return errorResponse(res, 'Failed to toggle availability', 400);

    return successResponse(res, { is_available: updated.is_available });
  } catch (err) {
    next(err);
  }
};

const getAvailableWorkers = async (req, res, next) => {
  try {
    const { service_category_id, pincode, date, time } = req.query;

    if (!service_category_id) {
      return errorResponse(res, 'service_category_id is required', 400);
    }

    let query = supabaseAdmin
      .from('workers')
      .select('*, profiles!user_id(full_name, avatar_url)')
      .eq('is_approved', true)
      .eq('is_available', true)
      .contains('service_category_ids', [service_category_id]);

    if (pincode) {
      query = query.contains('service_pincodes', [pincode]);
    }

    const { data: workers, error } = await query;

    if (error) return errorResponse(res, 'Failed to fetch workers', 400);

    // If date and time provided, filter by slot availability
    let available = workers || [];
    if (date && time) {
      const workerIds = available.map((w) => w.id);
      const { data: slots } = await supabaseAdmin
        .from('worker_slots')
        .select('worker_id')
        .in('worker_id', workerIds)
        .eq('slot_date', date)
        .eq('slot_start', time)
        .eq('is_booked', false);

      const availableWorkerIds = new Set((slots || []).map((s) => s.worker_id));
      available = available.filter((w) => availableWorkerIds.has(w.id));
    }

    return successResponse(res, available);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  register,
  getMyWorker,
  updateWorker,
  uploadDocs,
  toggleAvailability,
  getAvailableWorkers
};
