-- ================================================================
-- FreshKart: Supabase SQL Schema
-- Grocery Delivery + Blue Collar Service Bookings Platform
-- ================================================================

-- ================================================================
-- PART 1: CORE SHARED TABLES
-- ================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. PROFILES (extends auth.users)
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  phone text unique not null,
  email text,
  avatar_url text,
  role text not null default 'customer'
    check (role in ('customer','vendor','delivery_agent','worker','admin')),
  fcm_token text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. ADDRESSES (reused by both verticals)
create table addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles on delete cascade,
  label text default 'Home',
  flat_no text,
  area text,
  city text default 'Chennai',
  state text default 'Tamil Nadu',
  pincode text,
  lat float8,
  lng float8,
  is_default boolean default false,
  created_at timestamptz default now()
);

-- 3. PLATFORM CONFIG (admin controlled)
create table platform_config (
  key text primary key,
  value text not null,
  description text,
  updated_at timestamptz default now()
);

-- Seed platform config
insert into platform_config values
  ('grocery_commission_pct', '10', 'Platform commission on grocery orders'),
  ('service_commission_pct', '20', 'Platform commission on service bookings'),
  ('grocery_delivery_fee', '30', 'Default delivery fee in INR'),
  ('service_booking_fee', '99', 'Booking confirmation fee in INR'),
  ('grocery_free_delivery_above', '299', 'Free delivery threshold'),
  ('auto_confirm_seconds', '60', 'Seconds before auto-confirming vendor'),
  ('max_delivery_radius_km', '10', 'Max grocery delivery radius'),
  ('supported_pincodes', '600001,600002,600003', 'Active Tamil Nadu pincodes');

-- ================================================================
-- PART 2: GROCERY VERTICAL TABLES
-- ================================================================

-- 4. VENDORS
create table vendors (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references profiles on delete cascade,
  shop_name text not null,
  shop_name_tamil text,
  description text,
  address text,
  pincode text,
  city text default 'Chennai',
  state text default 'Tamil Nadu',
  lat float8,
  lng float8,
  fssai_number text,
  fssai_doc_url text,
  gstin text,
  gstin_doc_url text,
  bank_account_number text,
  bank_ifsc text,
  razorpay_linked_account_id text,
  delivery_radius_km float8 default 5,
  opening_time time default '09:00',
  closing_time time default '21:00',
  working_days text[] default '{Mon,Tue,Wed,Thu,Fri,Sat,Sun}',
  is_open boolean default false,
  is_approved boolean default false,
  is_active boolean default true,
  rating float4 default 0,
  total_ratings int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 5. GROCERY CATEGORIES
create table grocery_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_tamil text,
  icon_url text,
  sort_order int default 0,
  is_active boolean default true
);

-- Seed grocery categories
insert into grocery_categories (name, name_tamil, sort_order) values
  ('Vegetables', 'காய்கறிகள்', 1),
  ('Fruits', 'பழங்கள்', 2),
  ('Dairy & Eggs', 'பால் பொருட்கள்', 3),
  ('Rice & Grains', 'அரிசி & தானியங்கள்', 4),
  ('Snacks', 'தின்பண்டங்கள்', 5),
  ('Beverages', 'பானங்கள்', 6),
  ('Cleaning', 'சுத்தப்படுத்துதல்', 7),
  ('Personal Care', 'தனிப்பட்ட பராமரிப்பு', 8);

-- 6. PRODUCTS
create table products (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid references vendors on delete cascade,
  category_id uuid references grocery_categories,
  name text not null,
  name_tamil text,
  description text,
  image_url text,
  price numeric(10,2) not null,
  mrp numeric(10,2),
  unit text not null default '1 kg',
  stock_quantity int default 0,
  low_stock_threshold int default 5,
  is_available boolean default true,
  sort_order int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 7. ORDERS
create table orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique,
  customer_id uuid references profiles,
  vendor_id uuid references vendors,
  delivery_agent_id uuid references profiles,
  status text not null default 'pending'
    check (status in (
      'pending','confirmed','packing','ready',
      'picked_up','delivered','cancelled','refunded'
    )),
  total_amount numeric(10,2) not null,
  delivery_fee numeric(10,2) default 30,
  discount_amount numeric(10,2) default 0,
  final_amount numeric(10,2) not null,
  payment_method text check (payment_method in ('upi','card','cod','wallet')),
  payment_status text default 'pending'
    check (payment_status in ('pending','paid','failed','refunded')),
  razorpay_order_id text,
  razorpay_payment_id text,
  phonepe_transaction_id text,
  delivery_address jsonb,
  delivery_otp text,
  special_instructions text,
  cancelled_by text,
  cancel_reason text,
  vendor_confirmed_at timestamptz,
  packed_at timestamptz,
  picked_up_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Auto-generate order number
create sequence order_number_seq start 10001;

create or replace function set_order_number()
returns trigger as $$
begin
  new.order_number := 'FK' || nextval('order_number_seq')::text;
  return new;
end;
$$ language plpgsql;

create trigger order_number_trigger
  before insert on orders
  for each row execute function set_order_number();

-- 8. ORDER ITEMS
create table order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders on delete cascade,
  product_id uuid references products,
  product_name text not null,
  product_image_url text,
  unit text,
  quantity int not null,
  unit_price numeric(10,2) not null,
  total_price numeric(10,2) not null
);

-- 9. DELIVERY LOCATIONS (real-time rider tracking)
create table delivery_locations (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid references profiles,
  order_id uuid references orders,
  lat float8 not null,
  lng float8 not null,
  updated_at timestamptz default now()
);

-- ================================================================
-- PART 3: BLUE COLLAR SERVICE VERTICAL
-- ================================================================

-- 10. SERVICE CATEGORIES
create table service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_tamil text,
  icon_url text,
  description text,
  base_price numeric(10,2),
  price_type text default 'fixed'
    check (price_type in ('fixed','variable','on_inspection')),
  estimated_duration_mins int default 60,
  is_active boolean default true,
  sort_order int default 0
);

-- Seed service categories
insert into service_categories
  (name, name_tamil, base_price, price_type, estimated_duration_mins, sort_order)
values
  ('Plumbing', 'குழாய் பணி', 299, 'variable', 60, 1),
  ('Electrical', 'மின்சார பணி', 249, 'variable', 60, 2),
  ('House Cleaning', 'வீடு சுத்தம்', 499, 'fixed', 180, 3),
  ('AC Service', 'AC சர்வீஸ்', 399, 'fixed', 90, 4),
  ('Carpentry', 'தச்சு வேலை', 349, 'variable', 120, 5),
  ('Painting', 'வர்ணம் பூசுதல்', 999, 'on_inspection', 480, 6),
  ('Pest Control', 'பூச்சி கட்டுப்பாடு', 799, 'fixed', 120, 7),
  ('Appliance Repair', 'சாதன பழுது', 199, 'variable', 60, 8),
  ('Maid Service', 'வீட்டு வேலை', 399, 'fixed', 240, 9),
  ('Driver', 'டிரைவர்', 499, 'fixed', 480, 10);

-- 11. WORKERS (blue collar professionals)
create table workers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles on delete cascade unique,
  bio text,
  aadhaar_number text,
  aadhaar_doc_url text,
  police_verification_url text,
  skill_certificate_urls text[],
  service_category_ids uuid[],
  experience_years int default 0,
  city text default 'Chennai',
  state text default 'Tamil Nadu',
  service_pincodes text[],
  bank_account_number text,
  bank_ifsc text,
  is_available boolean default false,
  is_approved boolean default false,
  bgv_status text default 'pending'
    check (bgv_status in ('pending','in_progress','approved','rejected')),
  bgv_notes text,
  rating float4 default 0,
  total_ratings int default 0,
  total_jobs_completed int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 12. WORKER SLOTS (availability calendar)
create table worker_slots (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid references workers on delete cascade,
  slot_date date not null,
  slot_start time not null,
  slot_end time not null,
  is_booked boolean default false,
  booking_id uuid,
  created_at timestamptz default now(),
  unique(worker_id, slot_date, slot_start)
);

-- 13. BOOKINGS
create table bookings (
  id uuid primary key default gen_random_uuid(),
  booking_number text unique,
  customer_id uuid references profiles,
  worker_id uuid references workers,
  service_category_id uuid references service_categories,
  status text not null default 'pending'
    check (status in (
      'pending','assigned','confirmed','worker_on_way',
      'in_progress','completed','cancelled','disputed'
    )),
  slot_date date not null,
  slot_start time not null,
  slot_end time not null,
  quoted_price numeric(10,2),
  final_price numeric(10,2),
  booking_fee numeric(10,2) default 99,
  platform_commission numeric(10,2),
  payment_method text check (payment_method in ('upi','card','cod','wallet')),
  payment_status text default 'pending'
    check (payment_status in ('pending','partial','paid','refunded')),
  razorpay_order_id text,
  razorpay_payment_id text,
  service_address jsonb,
  customer_notes text,
  worker_notes text,
  checkin_otp text,
  checkin_at timestamptz,
  checkout_at timestamptz,
  cancelled_by text,
  cancel_reason text,
  dispute_reason text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Auto-generate booking number
create sequence booking_number_seq start 20001;

create or replace function set_booking_number()
returns trigger as $$
begin
  new.booking_number := 'SV' || nextval('booking_number_seq')::text;
  return new;
end;
$$ language plpgsql;

create trigger booking_number_trigger
  before insert on bookings
  for each row execute function set_booking_number();

-- ================================================================
-- PART 4: SHARED TABLES (BOTH VERTICALS)
-- ================================================================

-- 14. PAYMENTS (unified log for both orders and bookings)
create table payments (
  id uuid primary key default gen_random_uuid(),
  ref_type text not null check (ref_type in ('order','booking')),
  ref_id uuid not null,
  customer_id uuid references profiles,
  gateway text check (gateway in ('razorpay','phonepe','cod','wallet')),
  gateway_order_id text,
  gateway_payment_id text,
  amount numeric(10,2) not null,
  currency text default 'INR',
  status text check (status in ('pending','success','failed','refunded')),
  failure_reason text,
  refund_id text,
  refund_amount numeric(10,2),
  created_at timestamptz default now()
);

-- 15. REVIEWS (unified for vendors and workers)
create table reviews (
  id uuid primary key default gen_random_uuid(),
  ref_type text not null check (ref_type in ('vendor','worker')),
  ref_id uuid not null,
  customer_id uuid references profiles,
  order_or_booking_id uuid,
  rating int not null check (rating between 1 and 5),
  comment text,
  is_visible boolean default true,
  created_at timestamptz default now()
);

-- 16. PAYOUTS (to vendors and workers)
create table payouts (
  id uuid primary key default gen_random_uuid(),
  payee_type text check (payee_type in ('vendor','worker')),
  payee_id uuid not null,
  period_start date,
  period_end date,
  gross_amount numeric(10,2),
  commission_amount numeric(10,2),
  net_amount numeric(10,2),
  status text default 'pending'
    check (status in ('pending','processing','paid','failed')),
  payment_reference text,
  paid_at timestamptz,
  notes text,
  created_at timestamptz default now()
);

-- 17. NOTIFICATIONS LOG
create table notifications_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles,
  ref_type text,
  ref_id uuid,
  title text not null,
  body text,
  type text,
  is_read boolean default false,
  sent_at timestamptz default now()
);

-- ================================================================
-- PART 5: INDEXES
-- ================================================================

create index idx_products_vendor on products(vendor_id);
create index idx_products_category on products(category_id);
create index idx_orders_customer on orders(customer_id);
create index idx_orders_vendor on orders(vendor_id);
create index idx_orders_agent on orders(delivery_agent_id);
create index idx_orders_status on orders(status);
create index idx_orders_created on orders(created_at desc);
create index idx_bookings_customer on bookings(customer_id);
create index idx_bookings_worker on bookings(worker_id);
create index idx_bookings_status on bookings(status);
create index idx_bookings_slot on bookings(slot_date, slot_start);
create index idx_worker_slots_worker on worker_slots(worker_id, slot_date);
create index idx_delivery_locations_order on delivery_locations(order_id);
create index idx_reviews_ref on reviews(ref_type, ref_id);
create index idx_payouts_payee on payouts(payee_type, payee_id);

-- ================================================================
-- PART 6: TRIGGERS
-- ================================================================

-- Auto-update updated_at
create or replace function update_updated_at()
returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

create trigger trg_profiles_updated
  before update on profiles
  for each row execute function update_updated_at();

create trigger trg_vendors_updated
  before update on vendors
  for each row execute function update_updated_at();

create trigger trg_products_updated
  before update on products
  for each row execute function update_updated_at();

create trigger trg_orders_updated
  before update on orders
  for each row execute function update_updated_at();

create trigger trg_bookings_updated
  before update on bookings
  for each row execute function update_updated_at();

create trigger trg_workers_updated
  before update on workers
  for each row execute function update_updated_at();

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, phone, full_name, role)
  values (
    new.id,
    new.phone,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'customer')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Update vendor/worker rating on new review
create or replace function update_rating()
returns trigger as $$
begin
  if new.ref_type = 'vendor' then
    update vendors set
      rating = (select avg(rating) from reviews
                where ref_type='vendor' and ref_id=new.ref_id and is_visible=true),
      total_ratings = (select count(*) from reviews
                       where ref_type='vendor' and ref_id=new.ref_id and is_visible=true)
    where id = new.ref_id;
  elsif new.ref_type = 'worker' then
    update workers set
      rating = (select avg(rating) from reviews
                where ref_type='worker' and ref_id=new.ref_id and is_visible=true),
      total_ratings = (select count(*) from reviews
                       where ref_type='worker' and ref_id=new.ref_id and is_visible=true)
    where id = new.ref_id;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trg_update_rating
  after insert on reviews
  for each row execute function update_rating();

-- ================================================================
-- PART 7: ROW LEVEL SECURITY
-- ================================================================

alter table profiles enable row level security;
alter table addresses enable row level security;
alter table vendors enable row level security;
alter table products enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table bookings enable row level security;
alter table workers enable row level security;
alter table worker_slots enable row level security;
alter table reviews enable row level security;
alter table notifications_log enable row level security;
alter table delivery_locations enable row level security;

-- profiles: users see own, admins see all
create policy "profiles_own" on profiles
  for all using (auth.uid() = id);

-- addresses: own only
create policy "addresses_own" on addresses
  for all using (auth.uid() = user_id);

-- vendors: public read, owner write
create policy "vendors_public_read" on vendors
  for select using (is_approved = true and is_active = true);

create policy "vendors_owner_write" on vendors
  for all using (auth.uid() = owner_id);

-- products: public read, vendor owner write
create policy "products_public_read" on products
  for select using (is_available = true);

create policy "products_vendor_write" on products
  for all using (
    auth.uid() = (select owner_id from vendors where id = vendor_id)
  );

-- orders: customer own, vendor own, delivery agent own
create policy "orders_customer" on orders
  for all using (auth.uid() = customer_id);

create policy "orders_vendor" on orders
  for select using (
    auth.uid() = (select owner_id from vendors where id = vendor_id)
  );

create policy "orders_agent" on orders
  for select using (auth.uid() = delivery_agent_id);

-- order_items: accessible if user can access the parent order
create policy "order_items_customer" on order_items
  for all using (
    auth.uid() = (select customer_id from orders where id = order_id)
  );

create policy "order_items_vendor" on order_items
  for select using (
    auth.uid() in (
      select v.owner_id from orders o
      join vendors v on v.id = o.vendor_id
      where o.id = order_id
    )
  );

-- bookings: customer own, worker own
create policy "bookings_customer" on bookings
  for all using (auth.uid() = customer_id);

create policy "bookings_worker" on bookings
  for select using (
    auth.uid() = (select profile_id from workers where id = worker_id)
  );

-- workers: public read approved, own write
create policy "workers_public_read" on workers
  for select using (is_approved = true);

create policy "workers_own_write" on workers
  for all using (auth.uid() = profile_id);

-- worker_slots: public read, worker own write
create policy "slots_public_read" on worker_slots for select using (true);

create policy "slots_worker_write" on worker_slots
  for all using (
    auth.uid() = (select profile_id from workers where id = worker_id)
  );

-- reviews: public read, customer own write
create policy "reviews_public_read" on reviews
  for select using (is_visible = true);

create policy "reviews_customer_write" on reviews
  for insert with check (auth.uid() = customer_id);

-- notifications: own only
create policy "notifs_own" on notifications_log
  for all using (auth.uid() = user_id);

-- delivery_locations: agent own write, public read for tracking
create policy "dloc_agent_write" on delivery_locations
  for all using (auth.uid() = agent_id);

create policy "dloc_public_read" on delivery_locations
  for select using (true);

-- ================================================================
-- PART 8: REALTIME
-- ================================================================

-- Enable Realtime on key tables
alter publication supabase_realtime add table orders;
alter publication supabase_realtime add table bookings;
alter publication supabase_realtime add table delivery_locations;
alter publication supabase_realtime add table notifications_log;

-- ================================================================
-- PART 9: NEW FEATURE TABLES (Coupons, Wallet, Loyalty, Referrals, Chat, Zones)
-- ================================================================

-- Enable PostGIS for zone polygon queries
create extension if not exists postgis;

-- ----------------------------------------------------------------
-- 18. COUPONS
-- ----------------------------------------------------------------
create table coupons (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  title text not null,
  title_tamil text,
  description text,
  description_tamil text,
  discount_type text not null check (discount_type in ('percentage', 'flat')),
  discount_value numeric(10,2) not null,
  max_discount numeric(10,2),
  min_order_amount numeric(10,2) default 0,
  usage_limit int,
  per_user_limit int default 1,
  used_count int default 0,
  vendor_id uuid references vendors,
  category_id uuid references grocery_categories,
  valid_from timestamptz default now(),
  valid_until timestamptz,
  is_active boolean default true,
  created_by uuid references profiles,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 19. COUPON USAGE
create table coupon_usage (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid references coupons on delete cascade,
  user_id uuid references profiles,
  order_id uuid references orders,
  discount_applied numeric(10,2),
  used_at timestamptz default now(),
  unique(coupon_id, order_id)
);

-- ----------------------------------------------------------------
-- 20. WALLETS
-- ----------------------------------------------------------------
create table wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles on delete cascade unique,
  balance numeric(10,2) default 0 check (balance >= 0),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 21. WALLET TRANSACTIONS
create table wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid references wallets on delete cascade,
  user_id uuid references profiles,
  type text not null check (type in ('credit', 'debit')),
  amount numeric(10,2) not null check (amount > 0),
  balance_after numeric(10,2) not null,
  reference_type text check (reference_type in (
    'order_refund', 'admin_credit', 'referral_bonus',
    'loyalty_redeem', 'order_payment', 'cashback', 'topup'
  )),
  reference_id uuid,
  description text,
  created_at timestamptz default now()
);

-- ----------------------------------------------------------------
-- 22. LOYALTY POINTS
-- ----------------------------------------------------------------
create table loyalty_points (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles on delete cascade unique,
  total_earned int default 0,
  total_redeemed int default 0,
  current_balance int default 0 check (current_balance >= 0),
  updated_at timestamptz default now()
);

-- 23. LOYALTY TRANSACTIONS
create table loyalty_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles,
  type text not null check (type in ('earn', 'redeem', 'expire', 'bonus')),
  points int not null,
  balance_after int not null,
  reference_type text,
  reference_id uuid,
  description text,
  expires_at timestamptz,
  created_at timestamptz default now()
);

-- ----------------------------------------------------------------
-- 24. REFERRAL CODES
-- ----------------------------------------------------------------
create table referral_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles on delete cascade unique,
  code text unique not null,
  total_referrals int default 0,
  total_earned numeric(10,2) default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- 25. REFERRALS
create table referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid references profiles,
  referee_id uuid references profiles,
  referral_code_id uuid references referral_codes,
  status text default 'pending' check (status in ('pending', 'completed', 'rewarded')),
  referee_first_order_id uuid references orders,
  referrer_reward numeric(10,2),
  referee_reward numeric(10,2),
  completed_at timestamptz,
  created_at timestamptz default now()
);

-- ----------------------------------------------------------------
-- 26. CHAT ROOMS
-- ----------------------------------------------------------------
create table chat_rooms (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders,
  booking_id uuid references bookings,
  customer_id uuid references profiles,
  other_party_id uuid references profiles,
  other_party_type text check (other_party_type in ('vendor', 'delivery_agent', 'worker', 'support')),
  status text default 'active' check (status in ('active', 'closed')),
  last_message_at timestamptz default now(),
  created_at timestamptz default now(),
  closed_at timestamptz
);

-- 27. CHAT MESSAGES
create table chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references chat_rooms on delete cascade,
  sender_id uuid references profiles,
  message text not null,
  message_type text default 'text' check (message_type in ('text', 'image', 'location', 'system')),
  image_url text,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- ----------------------------------------------------------------
-- 28. ZONES (Tamil Nadu districts / delivery areas)
-- ----------------------------------------------------------------
create table zones (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_tamil text,
  district text,
  city text,
  state text default 'Tamil Nadu',
  pincodes text[],
  polygon jsonb,
  geom geometry(Polygon, 4326),
  delivery_fee_override numeric(10,2),
  min_order_amount numeric(10,2),
  max_cod_amount numeric(10,2) default 5000,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ================================================================
-- PART 10: ALTER EXISTING TABLES FOR NEW FEATURES
-- ================================================================

-- Add coupon, wallet, loyalty, scheduling fields to orders
alter table orders add column coupon_id uuid references coupons;
alter table orders add column coupon_code text;
alter table orders add column coupon_discount numeric(10,2) default 0;
alter table orders add column wallet_amount_used numeric(10,2) default 0;
alter table orders add column loyalty_points_used int default 0;
alter table orders add column loyalty_discount numeric(10,2) default 0;
alter table orders add column scheduled_at timestamptz;
alter table orders add column is_scheduled boolean default false;

-- Update orders status check to include pending_scheduled
alter table orders drop constraint if exists orders_status_check;
alter table orders add constraint orders_status_check
  check (status in (
    'pending', 'pending_scheduled', 'confirmed', 'packing', 'ready',
    'picked_up', 'delivered', 'cancelled', 'refunded'
  ));

-- Update orders payment_method to include wallet
alter table orders drop constraint if exists orders_payment_method_check;
alter table orders add constraint orders_payment_method_check
  check (payment_method in ('upi', 'card', 'cod', 'wallet', 'wallet_upi', 'wallet_card'));

-- Add locale preference to profiles
alter table profiles add column preferred_locale text default 'en';
alter table profiles add column referral_code_id uuid references referral_codes;

-- ================================================================
-- PART 11: NEW INDEXES
-- ================================================================

create index idx_coupons_code on coupons(code);
create index idx_coupons_vendor on coupons(vendor_id);
create index idx_coupons_active on coupons(is_active, valid_from, valid_until);
create index idx_coupon_usage_user on coupon_usage(user_id, coupon_id);
create index idx_wallets_user on wallets(user_id);
create index idx_wallet_txns_wallet on wallet_transactions(wallet_id);
create index idx_wallet_txns_user on wallet_transactions(user_id);
create index idx_loyalty_user on loyalty_points(user_id);
create index idx_loyalty_txns_user on loyalty_transactions(user_id);
create index idx_referral_codes_user on referral_codes(user_id);
create index idx_referral_codes_code on referral_codes(code);
create index idx_referrals_referrer on referrals(referrer_id);
create index idx_referrals_referee on referrals(referee_id);
create index idx_chat_rooms_customer on chat_rooms(customer_id);
create index idx_chat_rooms_other on chat_rooms(other_party_id);
create index idx_chat_rooms_order on chat_rooms(order_id);
create index idx_chat_messages_room on chat_messages(room_id, created_at);
create index idx_zones_active on zones(is_active);
create index idx_zones_district on zones(district);
create index idx_zones_geom on zones using gist(geom);
create index idx_orders_scheduled on orders(is_scheduled, scheduled_at) where is_scheduled = true;

-- ================================================================
-- PART 12: NEW TRIGGERS
-- ================================================================

create trigger trg_coupons_updated
  before update on coupons
  for each row execute function update_updated_at();

create trigger trg_wallets_updated
  before update on wallets
  for each row execute function update_updated_at();

create trigger trg_zones_updated
  before update on zones
  for each row execute function update_updated_at();

-- ================================================================
-- PART 13: RPC FUNCTIONS (Wallet atomic operations)
-- ================================================================

-- Wallet credit (atomic)
create or replace function wallet_credit(
  p_user_id uuid,
  p_amount numeric,
  p_reference_type text,
  p_reference_id uuid default null,
  p_description text default null
) returns numeric as $$
declare
  v_wallet_id uuid;
  v_new_balance numeric;
begin
  -- Get or create wallet
  insert into wallets (user_id, balance)
  values (p_user_id, 0)
  on conflict (user_id) do nothing;

  -- Credit balance
  update wallets set balance = balance + p_amount
  where user_id = p_user_id
  returning id, balance into v_wallet_id, v_new_balance;

  -- Insert transaction
  insert into wallet_transactions (wallet_id, user_id, type, amount, balance_after, reference_type, reference_id, description)
  values (v_wallet_id, p_user_id, 'credit', p_amount, v_new_balance, p_reference_type, p_reference_id, p_description);

  return v_new_balance;
end;
$$ language plpgsql;

-- Wallet debit (atomic with balance check)
create or replace function wallet_debit(
  p_user_id uuid,
  p_amount numeric,
  p_reference_type text,
  p_reference_id uuid default null,
  p_description text default null
) returns numeric as $$
declare
  v_wallet_id uuid;
  v_current_balance numeric;
  v_new_balance numeric;
begin
  -- Get wallet
  select id, balance into v_wallet_id, v_current_balance
  from wallets where user_id = p_user_id for update;

  if v_wallet_id is null then
    raise exception 'Wallet not found for user %', p_user_id;
  end if;

  if v_current_balance < p_amount then
    raise exception 'Insufficient wallet balance. Available: %, Required: %', v_current_balance, p_amount;
  end if;

  -- Debit balance
  v_new_balance := v_current_balance - p_amount;
  update wallets set balance = v_new_balance where id = v_wallet_id;

  -- Insert transaction
  insert into wallet_transactions (wallet_id, user_id, type, amount, balance_after, reference_type, reference_id, description)
  values (v_wallet_id, p_user_id, 'debit', p_amount, v_new_balance, p_reference_type, p_reference_id, p_description);

  return v_new_balance;
end;
$$ language plpgsql;

-- Loyalty points earn
create or replace function loyalty_earn(
  p_user_id uuid,
  p_order_amount numeric,
  p_order_id uuid
) returns int as $$
declare
  v_points_per_100 int;
  v_points int;
  v_new_balance int;
begin
  -- Get config: 1 point per Rs.100
  select coalesce(value::int, 1) into v_points_per_100
  from platform_config where key = 'loyalty_points_per_100rs';

  v_points := floor(p_order_amount / 100) * v_points_per_100;

  if v_points <= 0 then return 0; end if;

  -- Upsert loyalty record
  insert into loyalty_points (user_id, total_earned, current_balance)
  values (p_user_id, v_points, v_points)
  on conflict (user_id)
  do update set
    total_earned = loyalty_points.total_earned + v_points,
    current_balance = loyalty_points.current_balance + v_points,
    updated_at = now();

  select current_balance into v_new_balance from loyalty_points where user_id = p_user_id;

  insert into loyalty_transactions (user_id, type, points, balance_after, reference_type, reference_id, description)
  values (p_user_id, 'earn', v_points, v_new_balance, 'order', p_order_id,
          'Earned ' || v_points || ' points for order');

  return v_points;
end;
$$ language plpgsql;

-- Loyalty points redeem
create or replace function loyalty_redeem(
  p_user_id uuid,
  p_points int,
  p_order_id uuid
) returns numeric as $$
declare
  v_point_value numeric;
  v_current int;
  v_discount numeric;
  v_new_balance int;
begin
  select coalesce(value::numeric, 1) into v_point_value
  from platform_config where key = 'loyalty_point_value_inr';

  select current_balance into v_current from loyalty_points where user_id = p_user_id;

  if v_current is null or v_current < p_points then
    raise exception 'Insufficient loyalty points. Available: %, Required: %', coalesce(v_current, 0), p_points;
  end if;

  v_discount := p_points * v_point_value;
  v_new_balance := v_current - p_points;

  update loyalty_points set
    total_redeemed = total_redeemed + p_points,
    current_balance = v_new_balance,
    updated_at = now()
  where user_id = p_user_id;

  insert into loyalty_transactions (user_id, type, points, balance_after, reference_type, reference_id, description)
  values (p_user_id, 'redeem', p_points, v_new_balance, 'order', p_order_id,
          'Redeemed ' || p_points || ' points for ₹' || v_discount || ' discount');

  return v_discount;
end;
$$ language plpgsql;

-- ================================================================
-- PART 14: RLS FOR NEW TABLES
-- ================================================================

alter table coupons enable row level security;
alter table coupon_usage enable row level security;
alter table wallets enable row level security;
alter table wallet_transactions enable row level security;
alter table loyalty_points enable row level security;
alter table loyalty_transactions enable row level security;
alter table referral_codes enable row level security;
alter table referrals enable row level security;
alter table chat_rooms enable row level security;
alter table chat_messages enable row level security;
alter table zones enable row level security;

-- Coupons: public read active, vendor/admin write
create policy "coupons_public_read" on coupons
  for select using (is_active = true);

create policy "coupons_vendor_write" on coupons
  for all using (auth.uid() = created_by);

-- Coupon usage: own only
create policy "coupon_usage_own" on coupon_usage
  for all using (auth.uid() = user_id);

-- Wallets: own only
create policy "wallets_own" on wallets
  for all using (auth.uid() = user_id);

-- Wallet transactions: own only
create policy "wallet_txns_own" on wallet_transactions
  for all using (auth.uid() = user_id);

-- Loyalty: own only
create policy "loyalty_own" on loyalty_points
  for all using (auth.uid() = user_id);

create policy "loyalty_txns_own" on loyalty_transactions
  for all using (auth.uid() = user_id);

-- Referral codes: own write, public read
create policy "referral_codes_own" on referral_codes
  for all using (auth.uid() = user_id);

create policy "referral_codes_public_read" on referral_codes
  for select using (is_active = true);

-- Referrals: own read
create policy "referrals_own" on referrals
  for select using (auth.uid() = referrer_id or auth.uid() = referee_id);

-- Chat rooms: participants only
create policy "chat_rooms_participant" on chat_rooms
  for all using (auth.uid() = customer_id or auth.uid() = other_party_id);

-- Chat messages: room participants
create policy "chat_messages_participant" on chat_messages
  for all using (
    auth.uid() in (
      select customer_id from chat_rooms where id = room_id
      union
      select other_party_id from chat_rooms where id = room_id
    )
  );

-- Zones: public read
create policy "zones_public_read" on zones
  for select using (is_active = true);

-- ================================================================
-- PART 15: REALTIME FOR NEW TABLES
-- ================================================================

alter publication supabase_realtime add table chat_messages;

-- ================================================================
-- PART 16: SEED NEW PLATFORM CONFIG
-- ================================================================

insert into platform_config (key, value, description) values
  ('loyalty_points_per_100rs', '1', 'Points earned per Rs.100 spent'),
  ('loyalty_point_value_inr', '1', 'Value of 1 loyalty point in INR'),
  ('loyalty_min_redeem_points', '50', 'Minimum points to redeem'),
  ('wallet_max_balance', '10000', 'Maximum wallet balance in INR'),
  ('referral_referrer_reward', '50', 'Wallet credit for referrer in INR'),
  ('referral_referee_reward', '25', 'Wallet credit for new user in INR'),
  ('supported_locales', 'en,ta', 'Supported app languages'),
  ('default_locale', 'en', 'Default app language');

-- Seed additional TN-specific grocery categories
insert into grocery_categories (name, name_tamil, sort_order) values
  ('Millets', 'சிறுதானியங்கள்', 9),
  ('Spices', 'மசாலா பொருட்கள்', 10),
  ('Oil & Ghee', 'எண்ணெய் & நெய்', 11),
  ('Pickles & Chutneys', 'ஊறுகாய்', 12),
  ('Flowers & Pooja', 'பூ & பூஜை பொருட்கள்', 13),
  ('Ready to Cook', 'சமைக்க தயார்', 14);

-- Seed Tamil Nadu zone districts
insert into zones (name, name_tamil, district, city, state, pincodes, is_active) values
  ('Chennai', 'சென்னை', 'Chennai', 'Chennai', 'Tamil Nadu', '{600001,600002,600003,600004,600005,600006,600007,600008,600009,600010,600011,600012,600014,600015,600017,600018,600020}', true),
  ('Coimbatore', 'கோயம்புத்தூர்', 'Coimbatore', 'Coimbatore', 'Tamil Nadu', '{641001,641002,641003,641004,641005,641006}', false),
  ('Madurai', 'மதுரை', 'Madurai', 'Madurai', 'Tamil Nadu', '{625001,625002,625003,625004,625005,625006}', false),
  ('Tiruchirappalli', 'திருச்சிராப்பள்ளி', 'Tiruchirappalli', 'Trichy', 'Tamil Nadu', '{620001,620002,620003,620004,620005}', false),
  ('Salem', 'சேலம்', 'Salem', 'Salem', 'Tamil Nadu', '{636001,636002,636003,636004,636005}', false),
  ('Tirunelveli', 'திருநெல்வேலி', 'Tirunelveli', 'Tirunelveli', 'Tamil Nadu', '{627001,627002,627003,627004}', false),
  ('Erode', 'ஈரோடு', 'Erode', 'Erode', 'Tamil Nadu', '{638001,638002,638003,638004}', false),
  ('Vellore', 'வேலூர்', 'Vellore', 'Vellore', 'Tamil Nadu', '{632001,632002,632003,632004}', false),
  ('Thanjavur', 'தஞ்சாவூர்', 'Thanjavur', 'Thanjavur', 'Tamil Nadu', '{613001,613002,613003}', false),
  ('Dindigul', 'திண்டுக்கல்', 'Dindigul', 'Dindigul', 'Tamil Nadu', '{624001,624002,624003}', false);

-- ================================================================
-- VERIFICATION: List all created objects
-- ================================================================

-- Show all tables with row counts
select
  schemaname,
  relname as table_name,
  n_live_tup as row_count
from pg_stat_user_tables
where schemaname = 'public'
order by relname;
