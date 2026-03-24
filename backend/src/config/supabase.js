const { createClient } = require('@supabase/supabase-js');

// Public client — respects RLS, used only for auth operations
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Admin client — bypasses RLS, used for all server-side operations
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

module.exports = { supabase, supabaseAdmin };
