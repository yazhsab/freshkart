const { supabase } = require('../config/supabase');
const { supabaseAdmin } = require('../config/supabase');
const r2Service = require('../services/r2.service');
const smsService = require('../services/sms.service');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

// In-memory OTP store for development (use Redis in production)
const otpStore = new Map();

const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const sendOTP = async (req, res, next) => {
  try {
    let { phone } = req.body;
    // Strip +91 if the client sends it
    phone = phone.replace(/^\+91/, '');
    const formattedPhone = `+91${phone}`;

    const otp = generateOTP();

    // Store OTP with 5-minute expiry
    otpStore.set(phone, { otp, expires: Date.now() + 5 * 60 * 1000 });

    const shouldSendExternalSms =
      Boolean(process.env.MSG91_AUTH_KEY) &&
      (process.env.NODE_ENV === 'production' || process.env.ENABLE_SMS_IN_DEV === 'true');

    let smsResult = { success: true, message: 'OTP generated' };

    if (shouldSendExternalSms) {
      smsResult = await smsService.sendOTP(phone, otp);
      if (!smsResult.success) {
        logger.warn('OTP delivery rejected by SMS provider', {
          phone: phone.slice(-4),
          error: smsResult.error,
          statusCode: smsResult.statusCode
        });
        return errorResponse(res, smsResult.error || 'Failed to send OTP', smsResult.statusCode || 502);
      }
    } else {
      logger.info('Skipping external OTP SMS', {
        phone: phone.slice(-4),
        nodeEnv: process.env.NODE_ENV
      });
    }

    logger.info('OTP sent', { phone: phone.slice(-4), otp: process.env.NODE_ENV === 'development' ? otp : '***' });

    const responseData = {
      message: smsResult.message || 'OTP sent successfully',
      requestId: smsResult.requestId || null
    };

    if (process.env.NODE_ENV === 'development') {
      responseData.dev_otp = otp;
    }

    return successResponse(res, responseData, 200, 'OTP sent successfully');
  } catch (err) {
    next(err);
  }
};

const verifyOTP = async (req, res, next) => {
  try {
    let { phone, otp, role, referral_code } = req.body;
    // Strip +91 if the client sends it
    phone = phone.replace(/^\+91/, '');
    const formattedPhone = `+91${phone}`;

    // Verify OTP from store
    const stored = otpStore.get(phone);
    if (!stored || stored.otp !== otp || Date.now() > stored.expires) {
      logger.warn('OTP verification failed', { phone: phone.slice(-4) });
      return errorResponse(res, 'Invalid or expired OTP', 400);
    }

    // OTP is valid, remove from store
    otpStore.delete(phone);

    // Check if user exists by phone in profiles
    const { data: existingProfile } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('phone', formattedPhone)
      .single();

    let userId;
    const tempEmail = `${phone}@phone.freshkart.com`;
    const tempPassword = `FK_${phone}_secure_pwd`;

    if (existingProfile) {
      userId = existingProfile.id;
      // Update password for sign-in
      const { error: updateErr } = await supabaseAdmin.auth.admin.updateUserById(userId, {
        password: tempPassword
      });
      if (updateErr) {
        logger.error('Password update failed', { error: updateErr.message });
      }
    } else {
      // Check if user already exists in auth by phone
      const { data: userList } = await supabaseAdmin.auth.admin.listUsers();
      let existingAuthUser = userList?.users?.find(
        u => u.phone === formattedPhone || u.email === tempEmail
      );

      if (existingAuthUser) {
        userId = existingAuthUser.id;
        // Update password for sign-in
        await supabaseAdmin.auth.admin.updateUserById(userId, {
          password: tempPassword,
          email: tempEmail,
          email_confirm: true,
        });
        // Ensure profile exists
        const { data: prof } = await supabaseAdmin.from('profiles').select('id').eq('id', userId).single();
        if (!prof) {
          await supabaseAdmin.from('profiles').insert({
            id: userId,
            phone: formattedPhone,
            role: role || 'customer'
          });
        }
      } else {
        // Create new user via admin API with email (for password sign-in)
        const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
          email: tempEmail,
          password: tempPassword,
          email_confirm: true,
          phone: formattedPhone,
          phone_confirm: true,
          user_metadata: { full_name: '', role: role || 'customer' }
        });

        if (createError) {
          logger.error('User creation failed', { error: createError.message, detail: JSON.stringify(createError) });
          return errorResponse(res, 'Failed to create user', 500);
        }
        userId = newUser.user.id;

        // Update profile with correct role and phone
        await supabaseAdmin.from('profiles')
          .update({ phone: formattedPhone, role: role || 'customer' })
          .eq('id', userId);
      }
    }

    // Apply referral code if provided (for new users)
    if (!existingProfile && referral_code) {
      try {
        const referralService = require('../services/referral.service');
        await referralService.applyReferralCode(userId, referral_code);
      } catch (e) {
        logger.warn('Referral code application failed', { error: e.message });
      }
    }

    // Ensure wallet exists for user
    const walletService = require('../services/wallet.service');
    await walletService.getOrCreateWallet(userId);

    // Sign in to get a real Supabase session
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: tempEmail,
      password: tempPassword,
    });

    if (signInError) {
      logger.error('Sign-in failed', { error: signInError.message });
      return errorResponse(res, 'Authentication failed', 500);
    }

    // Fetch full profile
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('*, addresses(*)')
      .eq('id', userId)
      .single();

    logger.info('OTP verified', { userId, phone: phone.slice(-4) });

    return successResponse(res, {
      user: profile,
      session: {
        access_token: signInData.session.access_token,
        refresh_token: signInData.session.refresh_token,
        expires_at: signInData.session.expires_at
      }
    }, 200, 'OTP verified successfully');
  } catch (err) {
    next(err);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;

    if (!refresh_token) {
      return errorResponse(res, 'Refresh token is required', 400);
    }

    const { data, error } = await supabase.auth.refreshSession({ refresh_token });

    if (error) {
      return errorResponse(res, 'Invalid refresh token', 401);
    }

    return successResponse(res, {
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_at: data.session.expires_at
    });
  } catch (err) {
    next(err);
  }
};

const logout = async (req, res, next) => {
  try {
    // Clear FCM token on logout
    await supabaseAdmin
      .from('profiles')
      .update({ fcm_token: null })
      .eq('id', req.user.id);

    return successResponse(res, null, 200, 'Logged out successfully');
  } catch (err) {
    next(err);
  }
};

const getProfile = async (req, res, next) => {
  try {
    const { data: profile, error } = await supabaseAdmin
      .from('profiles')
      .select('*, addresses(*)')
      .eq('id', req.user.id)
      .single();

    if (error || !profile) {
      return errorResponse(res, 'Profile not found', 404);
    }

    return successResponse(res, profile);
  } catch (err) {
    next(err);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const { full_name, email, fcm_token } = req.body;
    const updates = {};

    if (full_name !== undefined) updates.full_name = full_name;
    if (email !== undefined) updates.email = email;
    if (fcm_token !== undefined) updates.fcm_token = fcm_token;

    const { data: profile, error } = await supabaseAdmin
      .from('profiles')
      .update(updates)
      .eq('id', req.user.id)
      .select()
      .single();

    if (error) {
      return errorResponse(res, 'Failed to update profile', 400);
    }

    return successResponse(res, profile, 200, 'Profile updated');
  } catch (err) {
    next(err);
  }
};

const uploadAvatar = async (req, res, next) => {
  try {
    if (!req.file) {
      return errorResponse(res, 'No image file provided', 400);
    }

    const avatarUrl = await r2Service.uploadAvatarImage(req.file.buffer, req.user.id);

    await supabaseAdmin
      .from('profiles')
      .update({ avatar_url: avatarUrl })
      .eq('id', req.user.id);

    return successResponse(res, { avatar_url: avatarUrl }, 200, 'Avatar uploaded');
  } catch (err) {
    next(err);
  }
};

const saveFcmToken = async (req, res, next) => {
  try {
    const { fcm_token, platform } = req.body;

    if (!fcm_token) {
      return errorResponse(res, 'FCM token is required', 400);
    }

    await supabaseAdmin
      .from('profiles')
      .update({ fcm_token, device_platform: platform || 'android' })
      .eq('id', req.user.id);

    return successResponse(res, null, 200, 'FCM token saved');
  } catch (err) {
    next(err);
  }
};

const googleSignIn = async (req, res, next) => {
  try {
    const { id_token, referral_code } = req.body;

    logger.info('Google sign-in attempt', { hasToken: !!id_token, bodyKeys: Object.keys(req.body || {}) });

    if (!id_token) {
      logger.warn('Google sign-in: no id_token in request body');
      return errorResponse(res, 'Google ID token is required', 400);
    }

    // Verify Google ID token via Firebase Admin
    const { admin } = require('../config/firebase');
    if (!admin.apps.length) {
      logger.error('Google sign-in: Firebase not initialized');
      return errorResponse(res, 'Firebase is not configured', 500);
    }

    logger.info('Google sign-in: verifying Firebase token...');
    const decodedToken = await admin.auth().verifyIdToken(id_token);
    logger.info('Google sign-in: token verified', { email: decodedToken.email, uid: decodedToken.uid });
    const email = decodedToken.email;
    const fullName = decodedToken.name || decodedToken.displayName || '';

    if (!email) {
      return errorResponse(res, 'Email not found in Google token', 400);
    }

    // Check if user exists by email in profiles
    const { data: existingProfile } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('email', email)
      .single();

    let userId;
    const tempPassword = `FK_google_${decodedToken.uid.slice(0, 12)}_pwd`;

    if (existingProfile) {
      userId = existingProfile.id;
      await supabaseAdmin.auth.admin.updateUserById(userId, { password: tempPassword });
    } else {
      // Check auth by email
      const { data: userList } = await supabaseAdmin.auth.admin.listUsers();
      let existingAuthUser = userList?.users?.find(u => u.email === email);

      if (existingAuthUser) {
        userId = existingAuthUser.id;
        await supabaseAdmin.auth.admin.updateUserById(userId, {
          password: tempPassword,
          email_confirm: true,
        });
        const { data: prof } = await supabaseAdmin.from('profiles').select('id').eq('id', userId).single();
        if (!prof) {
          await supabaseAdmin.from('profiles').insert({
            id: userId,
            full_name: fullName,
            email: email,
            role: 'customer'
          });
        }
      } else {
        const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
          email: email,
          password: tempPassword,
          email_confirm: true,
          user_metadata: { full_name: fullName, role: 'customer' }
        });

        if (createError) {
          logger.error('Google sign-in user creation failed', { error: createError.message });
          return errorResponse(res, 'Failed to create user', 500);
        }
        userId = newUser.user.id;

        await supabaseAdmin.from('profiles')
          .update({ full_name: fullName, email: email, role: 'customer' })
          .eq('id', userId);
      }
    }

    // Apply referral code for new users
    if (!existingProfile && referral_code) {
      try {
        const referralService = require('../services/referral.service');
        await referralService.applyReferralCode(userId, referral_code);
      } catch (e) {
        logger.warn('Referral code failed', { error: e.message });
      }
    }

    const walletService = require('../services/wallet.service');
    await walletService.getOrCreateWallet(userId);

    // Sign in to get Supabase session
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: email,
      password: tempPassword,
    });

    if (signInError) {
      logger.error('Google sign-in Supabase session failed', { error: signInError.message });
      return errorResponse(res, 'Authentication failed', 500);
    }

    const { data: fullProfile } = await supabaseAdmin
      .from('profiles')
      .select('*, addresses(*)')
      .eq('id', userId)
      .single();

    logger.info('Google sign-in success', { userId, email });

    return successResponse(res, {
      user: fullProfile,
      session: {
        access_token: signInData.session.access_token,
        refresh_token: signInData.session.refresh_token,
        expires_at: signInData.session.expires_at
      }
    }, 200, 'Google sign-in successful');
  } catch (err) {
    if (err.code === 'auth/id-token-expired') {
      return errorResponse(res, 'Google token expired, please try again', 401);
    }
    if (err.code === 'auth/argument-error') {
      return errorResponse(res, 'Invalid Google token', 400);
    }
    next(err);
  }
};

const appleSignIn = async (req, res, next) => {
  try {
    const { id_token, referral_code } = req.body;

    const { data, error } = await supabase.auth.signInWithIdToken({
      provider: 'apple',
      token: id_token
    });

    if (error) {
      logger.error('Apple sign-in failed', { error: error.message });
      return errorResponse(res, 'Apple sign-in failed', 400);
    }

    const userId = data.user.id;

    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (!profile) {
      await supabaseAdmin.from('profiles').insert({
        id: userId,
        full_name: data.user.user_metadata?.full_name || '',
        email: data.user.email,
        phone: data.user.phone || '',
        role: 'customer'
      });
    }

    if (referral_code) {
      const referralService = require('../services/referral.service');
      await referralService.applyReferralCode(userId, referral_code);
    }

    const walletService = require('../services/wallet.service');
    await walletService.getOrCreateWallet(userId);

    const { data: fullProfile } = await supabaseAdmin
      .from('profiles')
      .select('*, addresses(*)')
      .eq('id', userId)
      .single();

    return successResponse(res, {
      user: fullProfile,
      session: {
        access_token: data.session.access_token,
        refresh_token: data.session.refresh_token,
        expires_at: data.session.expires_at
      }
    }, 200, 'Apple sign-in successful');
  } catch (err) {
    next(err);
  }
};

/**
 * Firebase Phone Auth — verifies the Firebase ID token from client-side
 * phone auth and creates/returns a Supabase session.
 */
const firebasePhoneAuth = async (req, res, next) => {
  try {
    const { id_token, referral_code } = req.body;

    if (!id_token) {
      return errorResponse(res, 'Firebase ID token is required', 400);
    }

    const { admin } = require('../config/firebase');
    if (!admin.apps.length) {
      return errorResponse(res, 'Firebase is not configured', 500);
    }

    // Verify the Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(id_token);
    const firebaseUid = decodedToken.uid;
    const phoneNumber = decodedToken.phone_number; // e.g. "+919739711141"
    const email = decodedToken.email;
    const fullName = decodedToken.name || decodedToken.displayName || '';

    if (!phoneNumber && !email) {
      return errorResponse(res, 'No phone or email found in Firebase token', 400);
    }

    // Determine lookup strategy: phone-based or email-based
    const isPhoneAuth = !!phoneNumber;
    const phone = isPhoneAuth ? phoneNumber.replace(/^\+91/, '') : null;
    const formattedPhone = phone ? `+91${phone}` : null;
    const lookupEmail = isPhoneAuth ? `${phone}@phone.freshkart.com` : email;
    const tempEmail = lookupEmail;
    const tempPassword = `FK_${firebaseUid}_pwd`;

    // Check if user exists in profiles
    let existingProfile = null;
    if (isPhoneAuth && formattedPhone) {
      const { data } = await supabaseAdmin
        .from('profiles')
        .select('*')
        .eq('phone', formattedPhone)
        .single();
      existingProfile = data;
    }
    if (!existingProfile && email) {
      const { data } = await supabaseAdmin
        .from('profiles')
        .select('*')
        .eq('email', email)
        .single();
      existingProfile = data;
    }

    let userId;

    if (existingProfile) {
      userId = existingProfile.id;
      await supabaseAdmin.auth.admin.updateUserById(userId, {
        email: tempEmail,
        email_confirm: true,
        password: tempPassword
      });
    } else {
      // Check auth by email
      const { data: userList } = await supabaseAdmin.auth.admin.listUsers();
      let existingAuthUser = userList?.users?.find(
        u => (formattedPhone && u.phone === formattedPhone) || u.email === tempEmail
      );

      if (existingAuthUser) {
        userId = existingAuthUser.id;
        await supabaseAdmin.auth.admin.updateUserById(userId, {
          password: tempPassword,
          email: tempEmail,
          email_confirm: true,
        });
        const { data: prof } = await supabaseAdmin.from('profiles').select('id').eq('id', userId).single();
        if (!prof) {
          await supabaseAdmin.from('profiles').insert({
            id: userId,
            full_name: fullName,
            email: email || null,
            phone: formattedPhone || '',
            role: 'customer'
          });
        }
      } else {
        const createData = {
          email: tempEmail,
          password: tempPassword,
          email_confirm: true,
          user_metadata: { full_name: fullName, role: 'customer' }
        };
        if (formattedPhone) {
          createData.phone = formattedPhone;
          createData.phone_confirm = true;
        }

        const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser(createData);

        if (createError) {
          logger.error('User creation failed', { error: createError.message });
          return errorResponse(res, 'Failed to create user', 500);
        }
        userId = newUser.user.id;

        await supabaseAdmin.from('profiles')
          .update({ full_name: fullName, email: email || null, phone: formattedPhone || '', role: 'customer' })
          .eq('id', userId);
      }
    }

    // Apply referral code for new users
    if (!existingProfile && referral_code) {
      try {
        const referralService = require('../services/referral.service');
        await referralService.applyReferralCode(userId, referral_code);
      } catch (e) {
        logger.warn('Referral code failed', { error: e.message });
      }
    }

    // Ensure wallet exists
    const walletService = require('../services/wallet.service');
    await walletService.getOrCreateWallet(userId);

    // Sign in to get a Supabase session
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: tempEmail,
      password: tempPassword,
    });

    if (signInError) {
      logger.error('Supabase sign-in failed', { error: signInError.message });
      return errorResponse(res, 'Authentication failed', 500);
    }

    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('*, addresses(*)')
      .eq('id', userId)
      .single();

    logger.info('Firebase phone auth success', { userId, phone: phone ? phone.slice(-4) : null, email: email || null });

    return successResponse(res, {
      user: profile,
      session: {
        access_token: signInData.session.access_token,
        refresh_token: signInData.session.refresh_token,
        expires_at: signInData.session.expires_at
      }
    }, 200, 'Phone authentication successful');
  } catch (err) {
    if (err.code === 'auth/id-token-expired') {
      return errorResponse(res, 'Firebase token expired, please try again', 401);
    }
    if (err.code === 'auth/argument-error') {
      return errorResponse(res, 'Invalid Firebase token', 400);
    }
    next(err);
  }
};

module.exports = {
  sendOTP,
  verifyOTP,
  refreshToken,
  logout,
  getProfile,
  updateProfile,
  uploadAvatar,
  saveFcmToken,
  googleSignIn,
  appleSignIn,
  firebasePhoneAuth
};
