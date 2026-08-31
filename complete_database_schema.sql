-- =============================================================================
-- La Pirogue HMS — Complete Database Schema
-- =============================================================================
-- Consolidated, generated directly from the live Supabase project
-- "lapiroguehotel" (project ref: txalwdljaxltchcrauhp) on 2026-07-20.
--
-- This single file is the source of truth for everything both apps use:
--   - NEW APPS/Hotel            (Next.js staff/admin web app)
--   - NEW APPS/lapirogue_hotel  (Flutter guest mobile app)
--
-- It supersedes the old fragmented migration files (supabase_fix*.sql,
-- laprogue_v2_migration.sql, cleanup_complete.sql, etc.) which were already
-- deleted from git history and did not reflect the actual live schema.
-- Local migrations 011/012 in NEW APPS/lapirogue_hotel/supabase/migrations/
-- are already applied and their contents are folded in below.
--
-- Requires the pgcrypto extension for gen_random_uuid()/gen_random_bytes()
-- (already enabled by default on Supabase projects, in the "extensions" schema).
--
-- Order: extensions note -> enum types -> sequences -> tables -> constraints
--        -> indexes -> functions -> triggers -> row level security
-- =============================================================================


-- =============================================================================
-- 1. ENUM TYPES
-- =============================================================================

CREATE TYPE public.activity_status AS ENUM ('ACTIVE', 'INACTIVE', 'FULL');
CREATE TYPE public.eco_tx_status AS ENUM ('COMPLETED', 'PENDING', 'FAILED');
CREATE TYPE public.eco_tx_type AS ENUM ('EARN', 'SPEND', 'ADJUST');
CREATE TYPE public.guest_account_status AS ENUM ('PENDING', 'ACTIVE', 'FROZEN', 'BANNED');
CREATE TYPE public.guest_status AS ENUM ('RESERVED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED');
CREATE TYPE public.order_origin AS ENUM ('MOBILE_APP', 'RECEPTION_DESK', 'MANAGER_PORTAL');
CREATE TYPE public.order_status AS ENUM ('PENDING', 'PREPARING', 'SERVED', 'CANCELLED');
CREATE TYPE public.payment_method AS ENUM ('CASH', 'CARD', 'BANK_TRANSFER', 'ONLINE');
CREATE TYPE public.payment_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED', 'PAID', 'PARTIALLY_PAID');
CREATE TYPE public.reservation_status AS ENUM ('CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED', 'NO_SHOW', 'RESERVED');
CREATE TYPE public.room_status AS ENUM ('AVAILABLE', 'OCCUPIED', 'CLEANING', 'MAINTENANCE');
CREATE TYPE public.room_type AS ENUM ('STANDARD', 'DELUXE', 'SUITE', 'VILLA');
CREATE TYPE public.user_role AS ENUM ('MAIN_RECEPTIONIST', 'RECEPTIONIST', 'GUEST', 'ADMIN', 'MANAGER');

-- Note: eco_tx_status / eco_tx_type exist as types but their owning tables
-- (eco_points_tx, eco_points_balance) are not present in the live schema —
-- see the "Known issues" note near the bottom of this file.


-- =============================================================================
-- 2. SEQUENCES (back human-readable IDs like G0001, R0001, REC-2026-0001)
-- =============================================================================

CREATE SEQUENCE public.food_order_seq START WITH 1001 INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807;
CREATE SEQUENCE public.guest_seq START WITH 1001 INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807;
CREATE SEQUENCE public.manager_seq START WITH 1001 INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807;
CREATE SEQUENCE public.payment_seq START WITH 1001 INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807;
CREATE SEQUENCE public.receptionist_seq START WITH 1001 INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807;
CREATE SEQUENCE public.reservation_seq START WITH 1001 INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807;


-- =============================================================================
-- 3. TABLES (26 tables, all in the public schema)
-- =============================================================================

CREATE TABLE public.activities (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  category text NOT NULL,
  description text,
  price numeric(10,2) DEFAULT 0 NOT NULL,
  duration integer DEFAULT 60 NOT NULL,
  capacity integer DEFAULT 10 NOT NULL,
  status activity_status DEFAULT 'ACTIVE'::activity_status,
  image_path text,
  meeting_point text,
  default_time time without time zone DEFAULT '09:00:00'::time without time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid
);

CREATE TABLE public.activity_bookings (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  activity_id uuid NOT NULL,
  guest_id uuid NOT NULL,
  booking_date date NOT NULL,
  booking_time time without time zone,
  participants integer DEFAULT 1 NOT NULL,
  status text DEFAULT 'CONFIRMED'::text,
  pickup_point text,
  notes text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid,
  origin order_origin DEFAULT 'RECEPTION_DESK'::order_origin,
  created_by_name text DEFAULT 'self'::text,
  reservation_id uuid
);

CREATE TABLE public.audit_logs (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  table_name text NOT NULL,
  record_id uuid,
  action text NOT NULL,
  actor_id uuid,
  previous_data jsonb,
  new_data jsonb,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.departments (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid
);

CREATE TABLE public.eco_tiers (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  min_points integer DEFAULT 0 NOT NULL,
  sort_order integer DEFAULT 0 NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.food_orders (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  order_id text DEFAULT ('FO'::text || lpad((nextval('food_order_seq'::regclass))::text, 4, '0'::text)) NOT NULL,
  guest_id uuid,
  room_id uuid,
  items jsonb DEFAULT '[]'::jsonb NOT NULL,
  subtotal numeric(10,2) DEFAULT 0 NOT NULL,
  service_charge numeric(10,2) DEFAULT 0,
  tax_amount numeric(10,2) DEFAULT 0,
  total numeric(10,2) DEFAULT 0 NOT NULL,
  status order_status DEFAULT 'PENDING'::order_status,
  notes text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid,
  origin order_origin DEFAULT 'RECEPTION_DESK'::order_origin,
  created_by_name text DEFAULT 'self'::text,
  scheduled_date date,
  scheduled_time time without time zone,
  reservation_id uuid
);

CREATE TABLE public.guest_eco_point_events (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  guest_id uuid NOT NULL,
  activity_id uuid,
  source_type text DEFAULT 'MANUAL'::text NOT NULL,
  source_record_id text DEFAULT ''::text NOT NULL,
  source_label text,
  points integer DEFAULT 0 NOT NULL,
  carbon_offset_kg numeric DEFAULT 0,
  metadata jsonb DEFAULT '{}'::jsonb,
  status text DEFAULT 'COMPLETED'::text,
  earned_at timestamp with time zone DEFAULT now() NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.guest_feedback (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  guest_id uuid NOT NULL,
  rating integer NOT NULL,
  category text NOT NULL,
  comment text,
  staff_response text,
  responded_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.guest_schedule_items (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  guest_id uuid NOT NULL,
  title text NOT NULL,
  item_type text DEFAULT 'ACTIVITY'::text NOT NULL,
  start_at timestamp with time zone NOT NULL,
  end_at timestamp with time zone NOT NULL,
  location text,
  description text,
  status text DEFAULT 'SCHEDULED'::text,
  color text DEFAULT '#3B82F6'::text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid,
  source_module text,
  source_record_id uuid,
  notes text,
  event_time timestamp with time zone,
  completed_at timestamp with time zone,
  eco_points_awarded boolean DEFAULT false,
  created_by_name text DEFAULT 'self'::text
);

CREATE TABLE public.guests (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  auth_id uuid,
  guest_id text DEFAULT ('G'::text || lpad((nextval('guest_seq'::regclass))::text, 4, '0'::text)) NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text,
  phone text,
  nationality text,
  passport text,
  date_of_birth date,
  vip boolean DEFAULT false,
  status guest_status DEFAULT 'RESERVED'::guest_status,
  notes text,
  image_path text,
  fcm_token text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid,
  invite_token text,
  invite_expires_at timestamp with time zone,
  auth_user_id uuid,
  account_status guest_account_status DEFAULT 'ACTIVE'::guest_account_status,
  home_address text,
  created_by_name text DEFAULT 'self'::text,
  gender text,
  failed_login_attempts integer DEFAULT 0 NOT NULL,
  locked_until timestamp with time zone
);

CREATE TABLE public.hotel_service_categories (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  description text,
  icon_name text,
  color_hex text,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.hotel_services (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  category_id uuid,
  name text NOT NULL,
  description text,
  subtitle text,
  phone_number text,
  email text,
  hours_text text,
  location text,
  image_url text,
  sort_order integer DEFAULT 0 NOT NULL,
  is_available boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid
);

CREATE TABLE public.managers (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  manager_id text DEFAULT ('MGR-2026-'::text || lpad((nextval('manager_seq'::regclass))::text, 4, '0'::text)) NOT NULL,
  auth_id uuid,
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text NOT NULL,
  phone text,
  home_address text,
  department_id uuid,
  date_of_joining date DEFAULT CURRENT_DATE,
  is_active boolean DEFAULT true,
  image_path text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid
);

CREATE TABLE public.menu_items (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  category text NOT NULL,
  description text,
  price numeric(10,2) NOT NULL,
  preparation_minutes integer DEFAULT 15,
  is_available boolean DEFAULT true,
  image_path text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid
);

CREATE TABLE public.messages (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  guest_id uuid NOT NULL,
  sender_type text DEFAULT 'staff'::text NOT NULL,
  content text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  file_url text,
  file_name text,
  file_type text,
  file_size integer,
  created_by_name text
);

CREATE TABLE public.notifications (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  guest_id uuid,
  title text NOT NULL,
  message text NOT NULL,
  category text DEFAULT 'General'::text,
  is_read boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.payment_extra_items (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  payment_id uuid,
  guest_id uuid,
  category text NOT NULL,
  label text NOT NULL,
  amount numeric(12,2) NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.payments (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  payment_id text DEFAULT ('P'::text || lpad((nextval('payment_seq'::regclass))::text, 4, '0'::text)) NOT NULL,
  guest_id uuid NOT NULL,
  reservation_id uuid,
  amount numeric(12,2) NOT NULL,
  method payment_method NOT NULL,
  status payment_status DEFAULT 'PENDING'::payment_status,
  reference text,
  notes text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid,
  created_by_name text DEFAULT 'self'::text
);

CREATE TABLE public.pending_reservations (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  email text NOT NULL,
  guest_id uuid NOT NULL,
  room_id uuid NOT NULL,
  check_in date NOT NULL,
  check_out date NOT NULL,
  adults integer NOT NULL,
  children integer NOT NULL,
  total_amount numeric(10,2) NOT NULL,
  origin text DEFAULT 'MOBILE_APP'::text,
  verification_token text,
  verified_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  expires_at timestamp with time zone DEFAULT (now() + '00:30:00'::interval),
  verification_code text,
  failed_attempts integer DEFAULT 0
);

CREATE TABLE public.profiles (
  auth_id uuid NOT NULL,
  full_name text NOT NULL,
  email text,
  role user_role DEFAULT 'RECEPTIONIST'::user_role NOT NULL,
  avatar_url text,
  phone text,
  is_active boolean DEFAULT true NOT NULL,
  fcm_token text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid,
  home_address text,
  failed_login_attempts integer DEFAULT 0 NOT NULL,
  locked_until timestamp with time zone
);

CREATE TABLE public.receptionists (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  employee_code text DEFAULT ('REC-2026-'::text || lpad((nextval('receptionist_seq'::regclass))::text, 4, '0'::text)) NOT NULL,
  auth_id uuid,
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text NOT NULL,
  phone text,
  home_address text,
  department_id uuid,
  manager_id uuid,
  date_of_joining date DEFAULT CURRENT_DATE,
  is_active boolean DEFAULT true,
  image_path text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid
);

CREATE TABLE public.reservations (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  reservation_id text DEFAULT ('R'::text || lpad((nextval('reservation_seq'::regclass))::text, 4, '0'::text)) NOT NULL,
  guest_id uuid NOT NULL,
  room_id uuid NOT NULL,
  check_in date NOT NULL,
  check_out date NOT NULL,
  adults integer DEFAULT 1 NOT NULL,
  children integer DEFAULT 0,
  status reservation_status DEFAULT 'RESERVED'::reservation_status NOT NULL,
  total_amount numeric(12,2) NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid,
  created_by_name text DEFAULT 'self'::text,
  confirmation_token text,
  confirmed_at timestamp with time zone,
  origin order_origin DEFAULT 'RECEPTION_DESK'::order_origin NOT NULL
);

CREATE TABLE public.roles (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  description text,
  permissions jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public.rooms (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  room_number text NOT NULL,
  type room_type NOT NULL,
  floor text,
  capacity integer DEFAULT 2 NOT NULL,
  price numeric(10,2) NOT NULL,
  status room_status DEFAULT 'AVAILABLE'::room_status NOT NULL,
  description text,
  amenities text[] DEFAULT '{}'::text[],
  image_path text,
  image_paths text[] DEFAULT '{}'::text[],
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  created_by uuid,
  updated_by uuid
);

CREATE TABLE public.site_content_pages (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  slug text NOT NULL,
  title text NOT NULL,
  body text,
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  subtitle text,
  highlights text[],
  metrics jsonb,
  image_path text,
  updated_by uuid,
  is_active boolean DEFAULT true NOT NULL
);

CREATE TABLE public.sustainability_activities (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  category text,
  default_points integer DEFAULT 10 NOT NULL,
  carbon_offset_kg numeric DEFAULT 0,
  color text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);


-- =============================================================================
-- 4. PRIMARY KEYS
-- =============================================================================

ALTER TABLE public.activities ADD CONSTRAINT activities_pkey PRIMARY KEY (id);
ALTER TABLE public.activity_bookings ADD CONSTRAINT activity_bookings_pkey PRIMARY KEY (id);
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);
ALTER TABLE public.departments ADD CONSTRAINT departments_pkey PRIMARY KEY (id);
ALTER TABLE public.eco_tiers ADD CONSTRAINT eco_tiers_pkey PRIMARY KEY (id);
ALTER TABLE public.food_orders ADD CONSTRAINT food_orders_pkey PRIMARY KEY (id);
ALTER TABLE public.guest_eco_point_events ADD CONSTRAINT guest_eco_point_events_pkey PRIMARY KEY (id);
ALTER TABLE public.guest_feedback ADD CONSTRAINT guest_feedback_pkey PRIMARY KEY (id);
ALTER TABLE public.guest_schedule_items ADD CONSTRAINT guest_schedule_items_pkey PRIMARY KEY (id);
ALTER TABLE public.guests ADD CONSTRAINT guests_pkey PRIMARY KEY (id);
ALTER TABLE public.hotel_service_categories ADD CONSTRAINT hotel_service_categories_pkey PRIMARY KEY (id);
ALTER TABLE public.hotel_services ADD CONSTRAINT hotel_services_pkey PRIMARY KEY (id);
ALTER TABLE public.managers ADD CONSTRAINT managers_pkey PRIMARY KEY (id);
ALTER TABLE public.menu_items ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);
ALTER TABLE public.messages ADD CONSTRAINT messages_pkey PRIMARY KEY (id);
ALTER TABLE public.notifications ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);
ALTER TABLE public.payment_extra_items ADD CONSTRAINT payment_extra_items_pkey PRIMARY KEY (id);
ALTER TABLE public.payments ADD CONSTRAINT payments_pkey PRIMARY KEY (id);
ALTER TABLE public.pending_reservations ADD CONSTRAINT pending_reservations_pkey PRIMARY KEY (id);
ALTER TABLE public.profiles ADD CONSTRAINT profiles_pkey PRIMARY KEY (auth_id);
ALTER TABLE public.receptionists ADD CONSTRAINT receptionists_pkey PRIMARY KEY (id);
ALTER TABLE public.reservations ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);
ALTER TABLE public.roles ADD CONSTRAINT roles_pkey PRIMARY KEY (id);
ALTER TABLE public.rooms ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);
ALTER TABLE public.site_content_pages ADD CONSTRAINT site_content_pages_pkey PRIMARY KEY (id);
ALTER TABLE public.sustainability_activities ADD CONSTRAINT sustainability_activities_pkey PRIMARY KEY (id);


-- =============================================================================
-- 5. UNIQUE CONSTRAINTS
-- =============================================================================

ALTER TABLE public.departments ADD CONSTRAINT departments_name_key UNIQUE (name);
ALTER TABLE public.food_orders ADD CONSTRAINT food_orders_order_id_key UNIQUE (order_id);
ALTER TABLE public.guest_eco_point_events ADD CONSTRAINT guest_eco_point_events_source_type_source_record_id_key UNIQUE (source_type, source_record_id);
ALTER TABLE public.guests ADD CONSTRAINT guests_auth_id_key UNIQUE (auth_id);
ALTER TABLE public.guests ADD CONSTRAINT guests_guest_id_key UNIQUE (guest_id);
ALTER TABLE public.managers ADD CONSTRAINT managers_auth_id_key UNIQUE (auth_id);
ALTER TABLE public.managers ADD CONSTRAINT managers_email_key UNIQUE (email);
ALTER TABLE public.managers ADD CONSTRAINT managers_manager_id_key UNIQUE (manager_id);
ALTER TABLE public.payments ADD CONSTRAINT payments_payment_id_key UNIQUE (payment_id);
ALTER TABLE public.pending_reservations ADD CONSTRAINT pending_reservations_verification_token_key UNIQUE (verification_token);
ALTER TABLE public.receptionists ADD CONSTRAINT receptionists_auth_id_key UNIQUE (auth_id);
ALTER TABLE public.receptionists ADD CONSTRAINT receptionists_email_key UNIQUE (email);
ALTER TABLE public.receptionists ADD CONSTRAINT receptionists_employee_code_key UNIQUE (employee_code);
ALTER TABLE public.reservations ADD CONSTRAINT reservations_reservation_id_key UNIQUE (reservation_id);
ALTER TABLE public.roles ADD CONSTRAINT roles_name_key UNIQUE (name);
ALTER TABLE public.rooms ADD CONSTRAINT rooms_room_number_key UNIQUE (room_number);
ALTER TABLE public.site_content_pages ADD CONSTRAINT site_content_pages_slug_key UNIQUE (slug);


-- =============================================================================
-- 6. FOREIGN KEYS
-- =============================================================================
-- Note: several FKs reference auth.users(id), Supabase's built-in auth schema.

ALTER TABLE public.activity_bookings ADD CONSTRAINT activity_bookings_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE;
ALTER TABLE public.activity_bookings ADD CONSTRAINT activity_bookings_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.activity_bookings ADD CONSTRAINT activity_bookings_reservation_id_fkey FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE CASCADE;
ALTER TABLE public.departments ADD CONSTRAINT departments_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE public.food_orders ADD CONSTRAINT food_orders_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.food_orders ADD CONSTRAINT food_orders_reservation_id_fkey FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE CASCADE;
ALTER TABLE public.food_orders ADD CONSTRAINT food_orders_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms(id);
ALTER TABLE public.guest_eco_point_events ADD CONSTRAINT guest_eco_point_events_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES sustainability_activities(id) ON DELETE SET NULL;
ALTER TABLE public.guest_eco_point_events ADD CONSTRAINT guest_eco_point_events_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.guest_feedback ADD CONSTRAINT guest_feedback_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.guest_schedule_items ADD CONSTRAINT guest_schedule_items_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.guests ADD CONSTRAINT guests_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.guests ADD CONSTRAINT guests_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id);
ALTER TABLE public.hotel_services ADD CONSTRAINT hotel_services_category_id_fkey FOREIGN KEY (category_id) REFERENCES hotel_service_categories(id) ON DELETE SET NULL;
ALTER TABLE public.managers ADD CONSTRAINT managers_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.managers ADD CONSTRAINT managers_auth_id_profiles_fkey FOREIGN KEY (auth_id) REFERENCES profiles(auth_id);
ALTER TABLE public.managers ADD CONSTRAINT managers_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE public.managers ADD CONSTRAINT managers_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(id);
ALTER TABLE public.messages ADD CONSTRAINT messages_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.payment_extra_items ADD CONSTRAINT payment_extra_items_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.payment_extra_items ADD CONSTRAINT payment_extra_items_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE;
ALTER TABLE public.payments ADD CONSTRAINT payments_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.payments ADD CONSTRAINT payments_reservation_id_fkey FOREIGN KEY (reservation_id) REFERENCES reservations(id);
ALTER TABLE public.pending_reservations ADD CONSTRAINT pending_reservations_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.pending_reservations ADD CONSTRAINT pending_reservations_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.receptionists ADD CONSTRAINT receptionists_auth_id_fkey FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.receptionists ADD CONSTRAINT receptionists_auth_id_profiles_fkey FOREIGN KEY (auth_id) REFERENCES profiles(auth_id);
ALTER TABLE public.receptionists ADD CONSTRAINT receptionists_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE public.receptionists ADD CONSTRAINT receptionists_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(id);
ALTER TABLE public.receptionists ADD CONSTRAINT receptionists_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES managers(id);
ALTER TABLE public.reservations ADD CONSTRAINT reservations_guest_id_fkey FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE;
ALTER TABLE public.reservations ADD CONSTRAINT reservations_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms(id);
ALTER TABLE public.site_content_pages ADD CONSTRAINT site_content_pages_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id) ON DELETE SET NULL;


-- =============================================================================
-- 7. CHECK CONSTRAINTS
-- =============================================================================

ALTER TABLE public.activities ADD CONSTRAINT activities_capacity_check CHECK ((capacity > 0));
ALTER TABLE public.activities ADD CONSTRAINT activities_duration_check CHECK ((duration > 0));
ALTER TABLE public.activities ADD CONSTRAINT activities_price_check CHECK ((price >= (0)::numeric));
ALTER TABLE public.activity_bookings ADD CONSTRAINT activity_bookings_participants_check CHECK ((participants > 0));
ALTER TABLE public.food_orders ADD CONSTRAINT food_orders_service_charge_check CHECK ((service_charge >= (0)::numeric));
ALTER TABLE public.food_orders ADD CONSTRAINT food_orders_subtotal_check CHECK ((subtotal >= (0)::numeric));
ALTER TABLE public.food_orders ADD CONSTRAINT food_orders_tax_amount_check CHECK ((tax_amount >= (0)::numeric));
ALTER TABLE public.food_orders ADD CONSTRAINT food_orders_total_check CHECK ((total >= (0)::numeric));
ALTER TABLE public.guest_feedback ADD CONSTRAINT guest_feedback_rating_check CHECK (((rating >= 1) AND (rating <= 5)));
ALTER TABLE public.menu_items ADD CONSTRAINT menu_items_price_check CHECK ((price >= (0)::numeric));
ALTER TABLE public.payment_extra_items ADD CONSTRAINT payment_extra_items_amount_check CHECK ((amount > (0)::numeric));
ALTER TABLE public.payments ADD CONSTRAINT payments_amount_check CHECK ((amount > (0)::numeric));
ALTER TABLE public.pending_reservations ADD CONSTRAINT valid_dates CHECK ((check_out > check_in));
ALTER TABLE public.reservations ADD CONSTRAINT reservations_adults_check CHECK ((adults > 0));
ALTER TABLE public.reservations ADD CONSTRAINT reservations_check CHECK ((check_out > check_in));
ALTER TABLE public.reservations ADD CONSTRAINT reservations_children_check CHECK ((children >= 0));
ALTER TABLE public.reservations ADD CONSTRAINT reservations_total_amount_check CHECK ((total_amount >= (0)::numeric));
ALTER TABLE public.rooms ADD CONSTRAINT rooms_capacity_check CHECK ((capacity > 0));
ALTER TABLE public.rooms ADD CONSTRAINT rooms_price_check CHECK ((price >= (0)::numeric));


-- =============================================================================
-- 8. INDEXES (excluding those already created implicitly by PK/UNIQUE above)
-- =============================================================================

CREATE INDEX idx_activity_bookings_activity_id ON public.activity_bookings USING btree (activity_id);
CREATE INDEX idx_activity_bookings_created_by_name ON public.activity_bookings USING btree (created_by_name);
CREATE INDEX idx_activity_bookings_guest_id ON public.activity_bookings USING btree (guest_id);
CREATE INDEX idx_activity_bookings_origin ON public.activity_bookings USING btree (origin);
CREATE INDEX idx_activity_bookings_reservation_id ON public.activity_bookings USING btree (reservation_id);
CREATE INDEX idx_departments_created_by ON public.departments USING btree (created_by);
CREATE INDEX idx_departments_name ON public.departments USING btree (name);
CREATE INDEX idx_eco_tiers_sort ON public.eco_tiers USING btree (sort_order);
CREATE INDEX idx_food_orders_created_by_name ON public.food_orders USING btree (created_by_name);
CREATE INDEX idx_food_orders_guest_id ON public.food_orders USING btree (guest_id);
CREATE INDEX idx_food_orders_origin ON public.food_orders USING btree (origin);
CREATE INDEX idx_food_orders_reservation_id ON public.food_orders USING btree (reservation_id);
CREATE INDEX idx_food_orders_room_id ON public.food_orders USING btree (room_id);
CREATE INDEX idx_food_orders_scheduled_date ON public.food_orders USING btree (scheduled_date);
CREATE INDEX idx_guest_eco_point_events_activity_id ON public.guest_eco_point_events USING btree (activity_id);
CREATE INDEX idx_guest_eco_point_events_earned_at ON public.guest_eco_point_events USING btree (earned_at);
CREATE INDEX idx_guest_eco_point_events_guest_id ON public.guest_eco_point_events USING btree (guest_id);
CREATE INDEX idx_guest_feedback_guest_id ON public.guest_feedback USING btree (guest_id);
CREATE INDEX idx_guest_schedule_items_guest_id ON public.guest_schedule_items USING btree (guest_id);
CREATE INDEX idx_guest_schedule_items_source_record ON public.guest_schedule_items USING btree (source_record_id);
CREATE INDEX idx_guests_account_status ON public.guests USING btree (account_status);
CREATE INDEX idx_guests_auth_id ON public.guests USING btree (auth_id);
CREATE INDEX idx_guests_auth_user_id ON public.guests USING btree (auth_user_id);
CREATE INDEX idx_guests_created_by_name ON public.guests USING btree (created_by_name);
CREATE INDEX idx_guests_email ON public.guests USING btree (email);
CREATE INDEX idx_hotel_services_category_id ON public.hotel_services USING btree (category_id);
CREATE INDEX idx_managers_auth_id ON public.managers USING btree (auth_id);
CREATE INDEX idx_managers_created_by ON public.managers USING btree (created_by);
CREATE INDEX idx_managers_department_id ON public.managers USING btree (department_id);
CREATE INDEX idx_messages_guest_id ON public.messages USING btree (guest_id);
CREATE INDEX idx_notifications_guest_id ON public.notifications USING btree (guest_id);
CREATE INDEX idx_payment_extra_items_guest_id ON public.payment_extra_items USING btree (guest_id);
CREATE INDEX idx_payment_extra_items_payment_id ON public.payment_extra_items USING btree (payment_id);
CREATE INDEX idx_payments_guest_id ON public.payments USING btree (guest_id);
CREATE INDEX idx_payments_reservation_id ON public.payments USING btree (reservation_id);
CREATE INDEX idx_pending_reservations_email ON public.pending_reservations USING btree (email);
CREATE INDEX idx_pending_reservations_expires ON public.pending_reservations USING btree (expires_at);
CREATE INDEX idx_pending_reservations_guest_id ON public.pending_reservations USING btree (guest_id);
CREATE INDEX idx_pending_reservations_room_id ON public.pending_reservations USING btree (room_id);
CREATE INDEX idx_pending_reservations_token ON public.pending_reservations USING btree (verification_token);
CREATE INDEX idx_receptionists_auth_id ON public.receptionists USING btree (auth_id);
CREATE INDEX idx_receptionists_created_by ON public.receptionists USING btree (created_by);
CREATE INDEX idx_receptionists_department_id ON public.receptionists USING btree (department_id);
CREATE INDEX idx_receptionists_manager_id ON public.receptionists USING btree (manager_id);
CREATE UNIQUE INDEX idx_reservations_confirmation_token ON public.reservations USING btree (confirmation_token) WHERE (confirmation_token IS NOT NULL);
CREATE INDEX idx_reservations_created_by_name ON public.reservations USING btree (created_by_name);
CREATE INDEX idx_reservations_guest_id ON public.reservations USING btree (guest_id);
CREATE INDEX idx_reservations_room_id ON public.reservations USING btree (room_id);
CREATE INDEX idx_site_content_pages_updated_by ON public.site_content_pages USING btree (updated_by);
CREATE INDEX idx_sustainability_activities_active ON public.sustainability_activities USING btree (is_active);


-- =============================================================================
-- 9. FUNCTIONS (53 total: RPCs called from the apps, and trigger handlers)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.auto_complete_schedule_items()
 RETURNS TABLE(item_id uuid, guest_id uuid, title text, points_awarded integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_item record;
BEGIN
  FOR v_item IN
    SELECT gsi.id, gsi.guest_id, gsi.title
    FROM public.guest_schedule_items gsi
    WHERE gsi.status != 'COMPLETED'
      AND gsi.status != 'CANCELLED'
      AND (gsi.end_at + INTERVAL '5 minutes') < now()
  LOOP
    UPDATE public.guest_schedule_items
    SET status = 'COMPLETED',
        completed_at = now(),
        eco_points_awarded = true
    WHERE id = v_item.id;

    INSERT INTO public.eco_points_tx (guest_id, tx_type, points, description, status)
    VALUES (
      v_item.guest_id,
      'EARN',
      25,
      'Completed scheduled activity: ' || v_item.title,
      'COMPLETED'
    );

    INSERT INTO public.eco_points_balance (guest_id, points, tier)
    VALUES (v_item.guest_id, 25, 'Bronze')
    ON CONFLICT (guest_id)
    DO UPDATE SET
        points = eco_points_balance.points + 25,
        tier = CASE
            WHEN (eco_points_balance.points + 25) >= 1000 THEN 'Platinum'
            WHEN (eco_points_balance.points + 25) >= 500 THEN 'Gold'
            WHEN (eco_points_balance.points + 25) >= 200 THEN 'Silver'
            ELSE 'Bronze'
        END;

    item_id := v_item.id;
    guest_id := v_item.guest_id;
    title := v_item.title;
    points_awarded := 25;
    RETURN NEXT;
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.auto_unfreeze_on_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NEW.status IN ('COMPLETED', 'PAID') THEN
        UPDATE public.guests
        SET account_status = 'ACTIVE'
        WHERE id = NEW.guest_id
        AND account_status = 'FROZEN';
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.book_activity(p_activity_id uuid, p_guest_id uuid, p_booking_date date, p_booking_time time without time zone, p_participants integer DEFAULT 1, p_pickup_point text DEFAULT ''::text, p_notes text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_booking_id uuid;
    is_checked_in boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.reservations
        WHERE guest_id = p_guest_id AND status = 'CHECKED_IN'
    ) INTO is_checked_in;

    IF NOT is_checked_in THEN
        RETURN jsonb_build_object('success', false, 'error', 'Guest must be checked in to book activities');
    END IF;

    INSERT INTO public.activity_bookings (
        activity_id, guest_id, booking_date, booking_time,
        participants, status, pickup_point, notes, origin, created_by_name
    ) VALUES (
        p_activity_id, p_guest_id, p_booking_date, p_booking_time,
        p_participants, 'CONFIRMED', p_pickup_point, p_notes, 'MOBILE_APP', 'self'
    )
    RETURNING id INTO new_booking_id;

    RETURN jsonb_build_object('success', true, 'booking_id', new_booking_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.book_activity_pre_checkin(p_activity_id uuid, p_guest_id uuid, p_booking_date date, p_booking_time time without time zone, p_participants integer DEFAULT 1, p_pickup_point text DEFAULT ''::text, p_notes text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_booking_id uuid;
    has_reservation boolean;
    within_dates boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.reservations
        WHERE guest_id = p_guest_id
          AND status IN ('RESERVED', 'CHECKED_IN')
    ) INTO has_reservation;

    IF NOT has_reservation THEN
        RETURN jsonb_build_object('success', false, 'error', 'Guest must have an active reservation to book activities');
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.reservations
        WHERE guest_id = p_guest_id
          AND status IN ('RESERVED', 'CHECKED_IN')
          AND p_booking_date >= check_in
          AND p_booking_date <= check_out
    ) INTO within_dates;

    IF NOT within_dates THEN
        RETURN jsonb_build_object('success', false, 'error', 'Booking date must be within your reservation dates');
    END IF;

    INSERT INTO public.activity_bookings (
        activity_id, guest_id, booking_date, booking_time,
        participants, status, pickup_point, notes, origin, created_by_name
    ) VALUES (
        p_activity_id, p_guest_id, p_booking_date, p_booking_time,
        p_participants, 'CONFIRMED', p_pickup_point, p_notes, 'MOBILE_APP', 'self'
    )
    RETURNING id INTO new_booking_id;

    RETURN jsonb_build_object('success', true, 'booking_id', new_booking_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_guest_reservation(p_reservation_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_guest_id uuid;
  v_status text;
  v_owner_id uuid;
begin
  select id into v_guest_id from guests where auth_id = auth.uid();
  if v_guest_id is null then
    return jsonb_build_object('success', false, 'error', 'Guest profile not found');
  end if;

  select guest_id, status into v_owner_id, v_status
  from reservations
  where id = p_reservation_id;

  if v_owner_id is null then
    return jsonb_build_object('success', false, 'error', 'Reservation not found');
  end if;

  if v_owner_id <> v_guest_id then
    return jsonb_build_object('success', false, 'error', 'Not authorized to cancel this reservation');
  end if;

  if v_status not in ('RESERVED', 'CONFIRMED') then
    return jsonb_build_object('success', false, 'error', 'Only reserved bookings can be cancelled');
  end if;

  update reservations
  set status = 'CANCELLED', updated_at = now()
  where id = p_reservation_id;

  return jsonb_build_object('success', true);
end;
$function$;

CREATE OR REPLACE FUNCTION public.check_guest_can_book_activity(p_guest_id uuid, p_booking_date date)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.reservations
        WHERE guest_id = p_guest_id
        AND status IN ('RESERVED', 'CHECKED_IN')
            AND (
                status = 'CHECKED_IN'
                OR (
                    status = 'RESERVED'
                    AND p_booking_date >= check_in
                    AND p_booking_date <= check_out
                )
            )
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.check_guest_checked_in(p_guest_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.reservations
        WHERE guest_id = p_guest_id
        AND status = 'CHECKED_IN'
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.check_login_lockout(p_email text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_locked_until timestamptz;
BEGIN
  SELECT locked_until INTO v_locked_until FROM public.profiles WHERE lower(email) = lower(p_email);
  IF v_locked_until IS NULL THEN
    SELECT locked_until INTO v_locked_until FROM public.guests WHERE lower(email) = lower(p_email);
  END IF;

  IF v_locked_until IS NOT NULL AND v_locked_until > now() THEN
    RETURN jsonb_build_object(
      'locked', true,
      'lockedUntil', v_locked_until,
      'remainingSeconds', GREATEST(0, EXTRACT(EPOCH FROM (v_locked_until - now()))::int)
    );
  END IF;

  RETURN jsonb_build_object('locked', false);
END;
$function$;

CREATE OR REPLACE FUNCTION public.cleanup_expired_pending_reservations()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  DELETE FROM public.pending_reservations
  WHERE expires_at < now();
END;
$function$;

CREATE OR REPLACE FUNCTION public.compute_guest_status_from_reservations(p_guest_id uuid)
 RETURNS guest_status
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    derived_status public.guest_status;
BEGIN
    IF EXISTS (
            SELECT 1
            FROM public.reservations
            WHERE guest_id = p_guest_id
              AND status = 'CHECKED_IN'
        ) THEN
        RETURN 'CHECKED_IN'::public.guest_status;
    END IF;

    IF EXISTS (
            SELECT 1
            FROM public.reservations
            WHERE guest_id = p_guest_id
              AND status IN ('RESERVED', 'CONFIRMED')
        ) THEN
        RETURN 'RESERVED'::public.guest_status;
    END IF;

    SELECT CASE
            WHEN r.status = 'CHECKED_OUT' THEN 'CHECKED_OUT'::public.guest_status
            WHEN r.status IN ('CANCELLED', 'NO_SHOW') THEN 'CANCELLED'::public.guest_status
            ELSE 'RESERVED'::public.guest_status
        END
        INTO derived_status
        FROM public.reservations r
        WHERE r.guest_id = p_guest_id
        ORDER BY r.check_in DESC NULLS LAST, r.created_at DESC NULLS LAST
        LIMIT 1;

    RETURN COALESCE(derived_status, 'RESERVED'::public.guest_status);
END;
$function$;

CREATE OR REPLACE FUNCTION public.confirm_reservation(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_reservation record;
  v_result jsonb;
BEGIN
  SELECT id, guest_id, status, confirmation_token
  INTO v_reservation
  FROM public.reservations
  WHERE confirmation_token = p_token
  FOR UPDATE;

  IF v_reservation.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid confirmation token');
  END IF;

  IF v_reservation.status != 'PENDING' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reservation already confirmed');
  END IF;

  UPDATE public.reservations
  SET status = 'CONFIRMED',
      confirmed_at = now(),
      confirmation_token = NULL
  WHERE id = v_reservation.id;

  RETURN jsonb_build_object(
    'success', true,
    'reservation_id', v_reservation.id
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_guest_profile(p_first_name text, p_last_name text, p_phone text DEFAULT NULL::text, p_nationality text DEFAULT NULL::text, p_passport text DEFAULT NULL::text, p_date_of_birth date DEFAULT NULL::date, p_gender text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_auth_id uuid;
    v_guest_id text;
    v_email text;
BEGIN
    v_auth_id := auth.uid();
    IF v_auth_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
    END IF;

    SELECT email INTO v_email FROM auth.users WHERE id = v_auth_id;

    INSERT INTO public.guests (
        auth_id, auth_user_id, first_name, last_name, email, phone,
        nationality, passport, date_of_birth, gender,
        account_status, status, created_by_name
    ) VALUES (
        v_auth_id, v_auth_id::text, p_first_name, p_last_name, v_email,
        p_phone, p_nationality, p_passport, p_date_of_birth, p_gender,
        'ACTIVE', 'RESERVED', 'self'
    )
    ON CONFLICT (auth_id) DO NOTHING
    RETURNING guest_id INTO v_guest_id;

    IF v_guest_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Guest profile already exists');
    END IF;

    INSERT INTO public.profiles (auth_id, email, full_name, role, is_active)
    VALUES (v_auth_id, v_email, p_first_name || ' ' || p_last_name, 'GUEST', true)
    ON CONFLICT (auth_id) DO NOTHING;

    RETURN jsonb_build_object('success', true, 'guest_id', v_guest_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_mobile_reservation(p_guest_id uuid, p_room_id uuid, p_check_in date, p_check_out date, p_adults integer DEFAULT 1, p_children integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_reservation_id text;
    nights integer;
    room_price numeric;
    total numeric;
    guest_email text;
    guest_name text;
    room_number text;
    room_type text;
    hotel_name text := 'La Pirogue Hotel Mauritius';
    hotel_address text := 'La Pirogue, Belle Mare, Mauritius';
    tax_rate numeric := 0.15;
    tax_amount numeric;
    cancel_policy text := 'Free cancellation up to 48 hours before check-in. Cancellations within 48 hours may incur a one-night charge.';
BEGIN
    SELECT price, room_number, type INTO room_price, room_number, room_type
        FROM public.rooms WHERE id = p_room_id;

    IF room_price IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Room not found');
    END IF;

    IF EXISTS (
            SELECT 1 FROM public.reservations
            WHERE room_id = p_room_id
              AND status NOT IN ('CANCELLED', 'NO_SHOW', 'CHECKED_OUT')
              AND check_in < p_check_out
              AND check_out > p_check_in
        ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Room not available for selected dates');
    END IF;

    nights := p_check_out - p_check_in;
    total := room_price * nights;
    tax_amount := total * tax_rate;

    INSERT INTO public.reservations (
        guest_id, room_id, check_in, check_out,
        adults, children, status, total_amount,
        created_by_name, origin
    ) VALUES (
        p_guest_id, p_room_id, p_check_in, p_check_out,
        p_adults, p_children, 'RESERVED', total,
        'self', 'MOBILE_APP'
    )
    RETURNING reservation_id INTO new_reservation_id;

    SELECT email, first_name || ' ' || last_name
        INTO guest_email, guest_name
        FROM public.guests WHERE id = p_guest_id;

    RETURN jsonb_build_object(
        'success', true,
        'reservation_id', new_reservation_id,
        'total_amount', total,
        'tax_amount', tax_amount,
        'nights', nights,
        'room_number', room_number,
        'room_type', room_type,
        'check_in', p_check_in,
        'check_out', p_check_out,
        'guest_name', guest_name,
        'guest_email', guest_email,
        'hotel_name', hotel_name,
        'hotel_address', hotel_address,
        'cancellation_policy', cancel_policy
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_pending_reservation(p_guest_id uuid, p_email text, p_room_id uuid, p_check_in date, p_check_out date, p_adults integer, p_children integer, p_total_amount numeric, p_origin text DEFAULT 'MOBILE_APP'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_token text;
BEGIN
    v_token := encode(extensions.gen_random_bytes(32), 'hex');

    INSERT INTO public.pending_reservations (
        guest_id, email, room_id, check_in, check_out,
        adults, children, total_amount, origin, verification_token
    ) VALUES (
        p_guest_id, p_email, p_room_id, p_check_in, p_check_out,
        p_adults, p_children, p_total_amount, p_origin, v_token
    );

    RETURN jsonb_build_object(
        'token', v_token,
        'email', p_email,
        'expires_in_seconds', 1800
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_manager_id()
 RETURNS text
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    year_prefix text;
    seq_val text;
BEGIN
    year_prefix := to_char(CURRENT_DATE, 'YYYY');
    seq_val := lpad(nextval('public.manager_seq')::text, 4, '0');
    RETURN 'MGR-' || year_prefix || '-' || seq_val;
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_receptionist_id()
 RETURNS text
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    year_prefix text;
    seq_val text;
BEGIN
    year_prefix := to_char(CURRENT_DATE, 'YYYY');
    seq_val := lpad(nextval('public.receptionist_seq')::text, 4, '0');
    RETURN 'REC-' || year_prefix || '-' || seq_val;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_available_rooms(p_check_in date, p_check_out date)
 RETURNS TABLE(id uuid, room_number text, type text, floor text, capacity integer, price numeric, status text, description text, amenities text[], image_path text, image_paths text[])
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT r.id, r.room_number, r.type::text, r.floor, r.capacity, r.price,
           r.status::text, r.description, r.amenities, r.image_path, r.image_paths
    FROM public.rooms r
    WHERE r.status != 'MAINTENANCE'
      AND NOT EXISTS (
          SELECT 1 FROM public.reservations res
          WHERE res.room_id = r.id
            AND res.status NOT IN ('CANCELLED', 'NO_SHOW', 'CHECKED_OUT')
            AND res.check_in < p_check_out
            AND res.check_out > p_check_in
      )
    ORDER BY r.price ASC;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_eco_leaderboard(p_limit integer DEFAULT 10)
 RETURNS TABLE(guest_id uuid, first_name text, last_name text, image_path text, total_points integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    g.id as guest_id,
    g.first_name,
    g.last_name,
    g.image_path,
    coalesce(sum(e.points), 0)::integer as total_points
  from guests g
  join guest_eco_point_events e on e.guest_id = g.id
  where (e.status is null or e.status <> 'REVOKED')
  group by g.id, g.first_name, g.last_name, g.image_path
  order by total_points desc
  limit p_limit;
$function$;

CREATE OR REPLACE FUNCTION public.get_guest_active_reservation(p_guest_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
DECLARE
    result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'id', r.id,
        'reservation_id', r.reservation_id,
        'room_id', r.room_id,
        'check_in', r.check_in,
        'check_out', r.check_out,
        'adults', r.adults,
        'children', r.children,
        'status', r.status,
        'total_amount', r.total_amount,
        'room', CASE WHEN rm.id IS NOT NULL THEN
            jsonb_build_object(
                'id', rm.id,
                'room_number', rm.room_number,
                'type', rm.type,
                'floor', rm.floor,
                'capacity', rm.capacity,
                'price', rm.price,
                'description', rm.description,
                'amenities', rm.amenities,
                'image_path', rm.image_path
            )
        ELSE NULL END
    )
    INTO result
    FROM public.reservations r
    LEFT JOIN public.rooms rm ON rm.id = r.room_id
    WHERE r.guest_id = p_guest_id
      AND r.status IN ('RESERVED', 'CHECKED_IN', 'CONFIRMED')
    ORDER BY r.created_at DESC
    LIMIT 1;

    RETURN COALESCE(result, '{}'::jsonb);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_guest_eco_points(p_guest_id uuid)
 RETURNS integer
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(sum(points), 0)::integer
  from guest_eco_point_events
  where guest_id = p_guest_id
    and (status is null or status <> 'REVOKED');
$function$;

CREATE OR REPLACE FUNCTION public.get_guest_reservation_status(p_guest_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
DECLARE
    current_status text;
BEGIN
    SELECT status INTO current_status
    FROM public.reservations
    WHERE guest_id = p_guest_id
    ORDER BY created_at DESC
    LIMIT 1;

    RETURN COALESCE(current_status, 'NONE');
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_guest_with_active_reservation(p_auth_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
DECLARE
    result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'guest', to_jsonb(g.*),
        'active_reservation', to_jsonb(r.*),
        'reservation_room', to_jsonb(rm.*)
    )
    INTO result
    FROM public.guests g
    LEFT JOIN public.reservations r ON r.guest_id = g.id AND r.status IN ('RESERVED', 'CHECKED_IN', 'CONFIRMED')
    LEFT JOIN public.rooms rm ON rm.id = r.room_id
    WHERE g.auth_id = p_auth_id
    ORDER BY r.created_at DESC
    LIMIT 1;

    RETURN COALESCE(result, '{}'::jsonb);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_reservation_by_token(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'id', r.id,
    'reservation_id', r.reservation_id,
    'status', r.status,
    'check_in', r.check_in,
    'check_out', r.check_out,
    'adults', r.adults,
    'children', r.children,
    'total_amount', r.total_amount,
    'room_number', rm.room_number,
    'room_type', rm.type
  )
  INTO v_result
  FROM public.reservations r
  LEFT JOIN public.rooms rm ON rm.id = r.room_id
  WHERE r.confirmation_token = p_token;

  IF v_result IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid token');
  END IF;

  RETURN jsonb_build_object('success', true, 'reservation', v_result);
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_reservation_cancellation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NEW.status = 'CANCELLED' AND (OLD.status IS NULL OR OLD.status != 'CANCELLED') THEN
        UPDATE public.activity_bookings
        SET status = 'CANCELLED',
            updated_at = now()
        WHERE guest_id = NEW.guest_id
          AND booking_date >= NEW.check_in
          AND booking_date <= NEW.check_out
          AND status IN ('CONFIRMED', 'PENDING');

        UPDATE public.guest_schedule_items
        SET status = 'CANCELLED',
            updated_at = now()
        WHERE guest_id = NEW.guest_id
          AND start_at::date >= NEW.check_in
          AND start_at::date <= NEW.check_out
          AND status IN ('SCHEDULED', 'CONFIRMED');

        UPDATE public.itinerary_events
        SET status = 'CANCELLED',
            updated_at = now()
        WHERE guest_id = NEW.guest_id
          AND start_at::date >= NEW.check_in
          AND start_at::date <= NEW.check_out
          AND status IN ('CONFIRMED', 'SCHEDULED');

        UPDATE public.food_orders
        SET status = 'CANCELLED',
            updated_at = now()
        WHERE guest_id = NEW.guest_id
          AND created_at::date >= NEW.check_in
          AND created_at::date <= NEW.check_out
          AND status IN ('PENDING', 'PREPARING');

        UPDATE public.guest_orders
        SET status = 'CANCELLED',
            updated_at = now()
        WHERE guest_id = NEW.guest_id
          AND (order_time::date >= NEW.check_in OR order_time IS NULL)
          AND order_time::date <= NEW.check_out
          AND status IN ('PENDING', 'CONFIRMED');

        IF NOT EXISTS (
            SELECT 1 FROM public.reservations
            WHERE guest_id = NEW.guest_id
              AND status NOT IN ('CANCELLED', 'NO_SHOW', 'CHECKED_OUT')
              AND id != NEW.id
        ) THEN
            UPDATE public.guests
            SET status = 'CANCELLED',
                updated_at = now()
            WHERE id = NEW.guest_id;
        END IF;
    END IF;

    IF NEW.status = 'CHECKED_IN' AND (OLD.status IS NULL OR OLD.status != 'CHECKED_IN') THEN
        UPDATE public.guests
        SET status = 'CHECKED_IN',
            updated_at = now()
        WHERE id = NEW.guest_id;
    END IF;

    IF NEW.status = 'CHECKED_OUT' AND (OLD.status IS NULL OR OLD.status != 'CHECKED_OUT') THEN
        UPDATE public.guests
        SET status = 'CHECKED_OUT',
            updated_at = now()
        WHERE id = NEW.guest_id;
    END IF;

    RETURN NEW;
END;
$function$;
-- NOTE: this function references public.itinerary_events and public.guest_orders,
-- neither of which exist in the live schema (see "Known issues" at the bottom).
-- It only errors if a cancelled reservation actually reaches those UPDATE
-- statements; kept verbatim to match production behavior.

CREATE OR REPLACE FUNCTION public.increment_eco_points(p_guest_id uuid, p_points integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN;
END;
$function$;

CREATE OR REPLACE FUNCTION public.link_guest_auth(p_guest_id uuid, p_auth_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE public.guests
  SET auth_id = p_auth_id,
      auth_user_id = p_auth_id::text
  WHERE id = p_guest_id;
  RETURN FOUND;
END;
$function$;

CREATE OR REPLACE FUNCTION public.log_audit_event()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.audit_logs(table_name, record_id, action, actor_id, previous_data, new_data)
  VALUES (TG_TABLE_NAME, COALESCE(NEW.id, OLD.id), TG_OP, auth.uid(),
          CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(OLD) ELSE NULL END,
          to_jsonb(NEW));
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.lookup_guest_by_booking(p_reservation_id text, p_last_name text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'id',               g.id,
    'guest_id',         g.guest_id,
    'first_name',       g.first_name,
    'last_name',        g.last_name,
    'email',            g.email,
    'phone',            g.phone,
    'nationality',      g.nationality,
    'image_path',       g.image_path,
    'vip',              g.vip,
    'reservation_id',   r.reservation_id,
    'check_in',         r.check_in,
    'check_out',        r.check_out,
    'room_id',          r.room_id,
    'reservation_status', r.status
  ) INTO result
  FROM public.guests g
  JOIN public.reservations r ON r.guest_id = g.id
  WHERE r.reservation_id = p_reservation_id
    AND LOWER(g.last_name) = LOWER(p_last_name)
  LIMIT 1;

  RETURN result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.mark_schedule_item_completed(p_item_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_item record;
  v_result jsonb;
BEGIN
  SELECT id, guest_id, title, status, end_at, eco_points_awarded
  INTO v_item
  FROM public.guest_schedule_items
  WHERE id = p_item_id
  FOR UPDATE;

  IF v_item.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Item not found');
  END IF;

  IF v_item.status = 'COMPLETED' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Already completed');
  END IF;

  IF v_item.status = 'CANCELLED' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Item is cancelled');
  END IF;

  IF (v_item.end_at + INTERVAL '5 minutes') > now() THEN
    RETURN jsonb_build_object('success', false, 'error', 'Too early to mark as completed');
  END IF;

  UPDATE public.guest_schedule_items
  SET status = 'COMPLETED',
      completed_at = now(),
      eco_points_awarded = true
  WHERE id = p_item_id;

  IF NOT v_item.eco_points_awarded THEN
    INSERT INTO public.eco_points_tx (guest_id, tx_type, points, description, status)
    VALUES (v_item.guest_id, 'EARN', 25, 'Completed scheduled activity: ' || v_item.title, 'COMPLETED');

    INSERT INTO public.eco_points_balance (guest_id, points, tier)
    VALUES (v_item.guest_id, 25, 'Bronze')
    ON CONFLICT (guest_id)
    DO UPDATE SET
        points = eco_points_balance.points + 25,
        tier = CASE
            WHEN (eco_points_balance.points + 25) >= 1000 THEN 'Platinum'
            WHEN (eco_points_balance.points + 25) >= 500 THEN 'Gold'
            WHEN (eco_points_balance.points + 25) >= 200 THEN 'Silver'
            ELSE 'Bronze'
        END;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'item_id', v_item.id,
    'points_awarded', CASE WHEN v_item.eco_points_awarded THEN 0 ELSE 25 END
  );
END;
$function$;
-- NOTE: also inserts into public.eco_points_tx / public.eco_points_balance,
-- which do not exist in the live schema — same known issue as above.

CREATE OR REPLACE FUNCTION public.notify_guest_on_booking_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_activity_name text;
BEGIN
  SELECT name INTO v_activity_name FROM public.activities WHERE id = NEW.activity_id;

  IF NEW.status = 'COMPLETED' AND (OLD.status IS NULL OR OLD.status != 'COMPLETED') THEN
    INSERT INTO public.notifications (guest_id, title, message, category)
    VALUES (
      NEW.guest_id,
      'Activity Completed: ' || COALESCE(v_activity_name, 'Activity'),
      'Great job completing your activity! Eco-points have been awarded.',
      'ACTIVITY'
    );
  ELSIF NEW.status = 'CONFIRMED' AND (OLD.status IS NULL OR OLD.status != 'CONFIRMED') THEN
    INSERT INTO public.notifications (guest_id, title, message, category)
    VALUES (
      NEW.guest_id,
      'Booking Confirmed: ' || COALESCE(v_activity_name, 'Activity'),
      'Your activity booking has been confirmed.',
      'ACTIVITY'
    );
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_guest_on_schedule_completed()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
    INSERT INTO public.notifications (guest_id, title, message, category)
    VALUES (
      NEW.guest_id,
      'Activity Completed: ' || NEW.title,
      'You earned 25 eco-points for completing this activity!',
      'SCHEDULE'
    );
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_guest_on_schedule_item()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_date text;
  v_time text;
BEGIN
  v_date := to_char(NEW.start_at AT TIME ZONE 'UTC', 'YYYY-MM-DD');
  v_time := to_char(NEW.start_at AT TIME ZONE 'UTC', 'HH24:MI');
  INSERT INTO public.notifications (guest_id, title, message, category)
  VALUES (
    NEW.guest_id,
    'Upcoming: ' || NEW.title,
    'Scheduled on ' || v_date || ' at ' || v_time || '.',
    'SCHEDULE'
  );
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_guest_on_staff_message()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.sender_type IN ('staff', 'admin', 'receptionist') THEN
    INSERT INTO public.notifications (guest_id, title, message, category)
    VALUES (
      NEW.guest_id, 'New Message from Staff',
      LEFT(NEW.content, 100), 'MESSAGE'
    );
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_staff_on_booking_request()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_guest_name text;
  v_activity_name text;
BEGIN
  SELECT COALESCE(first_name || ' ' || last_name, 'A guest')
  INTO v_guest_name FROM public.guests WHERE id = NEW.guest_id;
  SELECT COALESCE(name, 'an activity')
  INTO v_activity_name FROM public.activities WHERE id = NEW.activity_id;
  INSERT INTO public.notifications (title, message, category)
  VALUES (
    'New Booking Request',
    v_guest_name || ' requested to book: ' || v_activity_name,
    'ACTIVITY'
  );
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_staff_on_food_request()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_guest_name text;
BEGIN
  SELECT COALESCE(first_name || ' ' || last_name, 'A guest')
  INTO v_guest_name FROM public.guests WHERE id = NEW.guest_id;
  INSERT INTO public.notifications (title, message, category)
  VALUES (
    'New Food Order Request',
    v_guest_name || ' requested a food order (#' || NEW.id || ')',
    'ORDER'
  );
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_staff_on_guest_message()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_guest_name text;
BEGIN
  IF NEW.sender_type = 'guest' THEN
    SELECT COALESCE(first_name || ' ' || last_name, 'A guest')
    INTO v_guest_name FROM public.guests WHERE id = NEW.guest_id;

    INSERT INTO public.notifications (title, message, category)
    VALUES (
      'New Message from ' || v_guest_name,
      LEFT(NEW.content, 100),
      'MESSAGE'
    );
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_staff_on_mobile_reservation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    guest_name text;
    room_label text;
BEGIN
    IF NEW.origin <> 'MOBILE_APP' THEN
        RETURN NEW;
    END IF;

    SELECT trim(concat_ws(' ', g.first_name, g.last_name))
        INTO guest_name
        FROM public.guests g
        WHERE g.id = NEW.guest_id;

    SELECT concat('Room ', r.room_number)
        INTO room_label
        FROM public.rooms r
        WHERE r.id = NEW.room_id;

    INSERT INTO public.notifications (guest_id, title, message, category, is_read)
        VALUES (
            NULL,
            'New Mobile Reservation',
            concat(
                coalesce(nullif(guest_name, ''), 'Guest'),
                ' reserved ',
                coalesce(room_label, 'a room'),
                ' from ',
                NEW.check_in,
                ' to ',
                NEW.check_out,
                '. Reference: ',
                coalesce(NEW.reservation_id, NEW.id::text),
                '.'
            ),
            'Reservation',
            false
        );

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.place_food_order(p_guest_id uuid, p_items jsonb, p_subtotal numeric, p_service_charge numeric, p_tax_amount numeric, p_total numeric, p_notes text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_order_id text;
    is_checked_in boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.reservations
        WHERE guest_id = p_guest_id AND status = 'CHECKED_IN'
    ) INTO is_checked_in;

    IF NOT is_checked_in THEN
        RETURN jsonb_build_object('success', false, 'error', 'Guest must be checked in to place food orders');
    END IF;

    INSERT INTO public.food_orders (
        guest_id, items, subtotal, service_charge, tax_amount, total,
        status, notes, origin, created_by_name
    ) VALUES (
        p_guest_id, p_items, p_subtotal, p_service_charge, p_tax_amount, p_total,
        'PENDING', p_notes, 'MOBILE_APP', 'self'
    )
    RETURNING order_id INTO new_order_id;

    RETURN jsonb_build_object('success', true, 'order_id', new_order_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.record_login_attempt(p_email text, p_success boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_table text;
  v_attempts int;
  v_locked_until timestamptz;
  v_should_alert boolean := false;
BEGIN
  IF EXISTS (SELECT 1 FROM public.profiles WHERE lower(email) = lower(p_email)) THEN
    v_table := 'profiles';
  ELSIF EXISTS (SELECT 1 FROM public.guests WHERE lower(email) = lower(p_email)) THEN
    v_table := 'guests';
  ELSE
    RETURN jsonb_build_object('locked', false, 'attempts', 0);
  END IF;

  IF p_success THEN
    IF v_table = 'profiles' THEN
      UPDATE public.profiles SET failed_login_attempts = 0, locked_until = NULL WHERE lower(email) = lower(p_email);
    ELSE
      UPDATE public.guests SET failed_login_attempts = 0, locked_until = NULL WHERE lower(email) = lower(p_email);
    END IF;
    RETURN jsonb_build_object('locked', false, 'attempts', 0);
  END IF;

  IF v_table = 'profiles' THEN
    UPDATE public.profiles
      SET failed_login_attempts = failed_login_attempts + 1
      WHERE lower(email) = lower(p_email)
      RETURNING failed_login_attempts INTO v_attempts;
  ELSE
    UPDATE public.guests
      SET failed_login_attempts = failed_login_attempts + 1
      WHERE lower(email) = lower(p_email)
      RETURNING failed_login_attempts INTO v_attempts;
  END IF;

  IF v_attempts >= 3 THEN
    v_locked_until := now() + interval '15 minutes';
    v_should_alert := true;
    IF v_table = 'profiles' THEN
      UPDATE public.profiles SET locked_until = v_locked_until WHERE lower(email) = lower(p_email);
    ELSE
      UPDATE public.guests SET locked_until = v_locked_until WHERE lower(email) = lower(p_email);
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'locked', v_attempts >= 3,
    'attempts', v_attempts,
    'remainingAttempts', GREATEST(0, 3 - v_attempts),
    'lockedUntil', v_locked_until,
    'shouldAlert', v_should_alert
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_activity_booking_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NEW.created_by_name IS NULL THEN
        IF EXISTS (SELECT 1 FROM public.profiles WHERE auth_id = auth.uid()) THEN
            NEW.created_by_name = COALESCE(
                (SELECT full_name FROM public.profiles WHERE auth_id = auth.uid()),
                'Staff'
            );
        ELSE
            NEW.created_by_name = 'self';
        END IF;
    END IF;
    IF NEW.created_by IS NULL AND auth.uid() IS NOT NULL THEN
        NEW.created_by = auth.uid();
    END IF;
    IF NEW.origin IS NULL THEN
        NEW.origin = 'MOBILE_APP';
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_food_order_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NEW.created_by_name IS NULL THEN
        IF EXISTS (SELECT 1 FROM public.profiles WHERE auth_id = auth.uid()) THEN
            NEW.created_by_name = COALESCE(
                (SELECT full_name FROM public.profiles WHERE auth_id = auth.uid()),
                'Staff'
            );
        ELSE
            NEW.created_by_name = 'self';
        END IF;
    END IF;
    IF NEW.created_by IS NULL AND auth.uid() IS NOT NULL THEN
        NEW.created_by = auth.uid();
    END IF;
    IF NEW.origin IS NULL THEN
        NEW.origin = 'MOBILE_APP';
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_guest_active_on_auth_link()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.auth_id IS NOT NULL AND (OLD.auth_id IS NULL OR OLD.auth_id != NEW.auth_id) THEN
        NEW.account_status = 'ACTIVE';
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_guest_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NEW.created_by_name IS NULL THEN
        IF EXISTS (SELECT 1 FROM public.profiles WHERE auth_id = auth.uid()) THEN
            NEW.created_by_name = COALESCE(
                (SELECT full_name FROM public.profiles WHERE auth_id = auth.uid()),
                'Staff'
            );
        ELSE
            NEW.created_by_name = 'self';
        END IF;
    END IF;
    IF NEW.created_by IS NULL AND auth.uid() IS NOT NULL THEN
        NEW.created_by = auth.uid();
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_payment_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NEW.created_by_name IS NULL THEN
        IF EXISTS (SELECT 1 FROM public.profiles WHERE auth_id = auth.uid()) THEN
            NEW.created_by_name = COALESCE(
                (SELECT full_name FROM public.profiles WHERE auth_id = auth.uid()),
                'Staff'
            );
        ELSE
            NEW.created_by_name = 'self';
        END IF;
    END IF;
    IF NEW.created_by IS NULL AND auth.uid() IS NOT NULL THEN
        NEW.created_by = auth.uid();
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_reservation_created_by()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NEW.created_by_name IS NULL THEN
        IF EXISTS (SELECT 1 FROM public.profiles WHERE auth_id = auth.uid()) THEN
            NEW.created_by_name = COALESCE(
                (SELECT full_name FROM public.profiles WHERE auth_id = auth.uid()),
                'Staff'
            );
        ELSE
            NEW.created_by_name = 'self';
        END IF;
    END IF;
    IF NEW.created_by IS NULL AND auth.uid() IS NOT NULL THEN
        NEW.created_by = auth.uid();
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_guest_status_from_reservations()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    target_guest_id uuid := COALESCE(NEW.guest_id, OLD.guest_id);
BEGIN
    IF pg_trigger_depth() > 1 OR target_guest_id IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    UPDATE public.guests
        SET status = public.compute_guest_status_from_reservations(target_guest_id),
            updated_at = now()
        WHERE id = target_guest_id;

    RETURN COALESCE(NEW, OLD);
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_reservations_from_guest_status()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    target_reservation_id uuid;
    today date := CURRENT_DATE;
BEGIN
    IF pg_trigger_depth() > 1 OR NEW.status IS NOT DISTINCT FROM OLD.status THEN
        RETURN NEW;
    END IF;

    IF NEW.status = 'CANCELLED' THEN
        UPDATE public.reservations
            SET status = 'CANCELLED'::public.reservation_status,
                updated_at = now()
            WHERE guest_id = NEW.id
              AND status IN ('RESERVED', 'CONFIRMED', 'CHECKED_IN');

        RETURN NEW;
    END IF;

    SELECT r.id
        INTO target_reservation_id
        FROM public.reservations r
        WHERE r.guest_id = NEW.id
          AND r.status NOT IN ('CANCELLED', 'NO_SHOW')
          AND (
              (NEW.status = 'CHECKED_IN' AND r.status IN ('RESERVED', 'CONFIRMED', 'CHECKED_IN') AND r.check_in <= today AND r.check_out > today)
              OR (NEW.status = 'CHECKED_OUT' AND r.status IN ('CHECKED_IN', 'CHECKED_OUT'))
              OR (NEW.status = 'RESERVED' AND r.status IN ('RESERVED', 'CONFIRMED', 'CHECKED_IN'))
          )
        ORDER BY r.check_in DESC NULLS LAST, r.created_at DESC NULLS LAST
        LIMIT 1;

    IF target_reservation_id IS NOT NULL THEN
        UPDATE public.reservations
            SET status = CASE
                WHEN NEW.status = 'RESERVED' THEN 'RESERVED'::public.reservation_status
                WHEN NEW.status = 'CHECKED_IN' THEN 'CHECKED_IN'::public.reservation_status
                WHEN NEW.status = 'CHECKED_OUT' THEN 'CHECKED_OUT'::public.reservation_status
                ELSE 'CANCELLED'::public.reservation_status
            END,
            updated_at = now()
            WHERE id = target_reservation_id;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.trg_enforce_checkin_for_activities()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT public.check_guest_can_book_activity(NEW.guest_id, NEW.booking_date) THEN
        RAISE EXCEPTION 'Guest must have an active reservation within their stay period to book activities.'
            USING HINT = 'Reservation status must be RESERVED (with date in stay window) or CHECKED_IN';
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.trg_enforce_checkin_for_eco_actions()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT public.check_guest_checked_in(NEW.guest_id) THEN
        RAISE EXCEPTION 'Guest must be CHECKED_IN before participating in eco actions.'
            USING HINT = 'Update reservation status to CHECKED_IN first';
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.trg_enforce_checkin_for_food_orders()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT public.check_guest_checked_in(NEW.guest_id) THEN
        RAISE EXCEPTION 'Guest must be CHECKED_IN before placing food orders. Complete front-desk check-in first.'
            USING HINT = 'Update reservation status to CHECKED_IN first';
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_room_status_on_reservation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NEW.status IN ('CONFIRMED', 'CHECKED_IN') THEN
        UPDATE public.rooms SET status = 'OCCUPIED' WHERE id = NEW.room_id;
    ELSIF NEW.status = 'CHECKED_OUT' THEN
        UPDATE public.rooms SET status = 'CLEANING' WHERE id = NEW.room_id;
    ELSIF NEW.status IN ('CANCELLED', 'NO_SHOW') THEN
        UPDATE public.rooms SET status = 'AVAILABLE' WHERE id = NEW.room_id;
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.verify_pending_reservation(p_token text, p_auth_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_pending record;
    v_reservation_id uuid;
BEGIN
    SELECT * INTO v_pending
    FROM public.pending_reservations
    WHERE verification_token = p_token
    FOR UPDATE;

    IF v_pending IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Verification token not found or expired'
        );
    END IF;

    IF v_pending.expires_at < now() THEN
        DELETE FROM public.pending_reservations WHERE id = v_pending.id;
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Verification token has expired'
        );
    END IF;

    IF v_pending.verified_at IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'This reservation has already been verified'
        );
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.reservations
        WHERE room_id = v_pending.room_id
          AND status != 'CANCELLED'
          AND check_in < v_pending.check_out
          AND check_out > v_pending.check_in
    ) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Room is no longer available for these dates'
        );
    END IF;

    INSERT INTO public.reservations (
        guest_id, room_id, check_in, check_out,
        adults, children, total_amount, origin, status
    ) VALUES (
        v_pending.guest_id,
        v_pending.room_id,
        v_pending.check_in,
        v_pending.check_out,
        v_pending.adults,
        v_pending.children,
        v_pending.total_amount,
        v_pending.origin::public.order_origin,
        'RESERVED'
    ) RETURNING id INTO v_reservation_id;

    UPDATE public.pending_reservations
    SET verified_at = now()
    WHERE id = v_pending.id;

    RETURN jsonb_build_object(
        'success', true,
        'reservation_id', v_reservation_id,
        'guest_id', v_pending.guest_id,
        'room_id', v_pending.room_id,
        'check_in', v_pending.check_in,
        'check_out', v_pending.check_out
    );
END;
$function$;


-- =============================================================================
-- 10. TRIGGERS
-- =============================================================================

CREATE TRIGGER trg_activities_updated_at BEFORE UPDATE ON public.activities FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_audit_activities AFTER INSERT OR UPDATE ON public.activities FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER enforce_checkin_activity_bookings BEFORE INSERT ON public.activity_bookings FOR EACH ROW EXECUTE FUNCTION trg_enforce_checkin_for_activities();
CREATE TRIGGER trg_activity_bookings_updated_at BEFORE UPDATE ON public.activity_bookings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_notify_guest_booking AFTER UPDATE ON public.activity_bookings FOR EACH ROW EXECUTE FUNCTION notify_guest_on_booking_update();
CREATE TRIGGER trg_notify_staff_booking AFTER INSERT ON public.activity_bookings FOR EACH ROW EXECUTE FUNCTION notify_staff_on_booking_request();
CREATE TRIGGER trg_set_activity_booking_created_by BEFORE INSERT ON public.activity_bookings FOR EACH ROW EXECUTE FUNCTION set_activity_booking_created_by();

CREATE TRIGGER trg_audit_departments AFTER INSERT OR UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION log_audit_event();
CREATE TRIGGER trg_departments_updated_at BEFORE UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER enforce_checkin_food_orders BEFORE INSERT ON public.food_orders FOR EACH ROW EXECUTE FUNCTION trg_enforce_checkin_for_food_orders();
CREATE TRIGGER trg_audit_food_orders AFTER INSERT OR UPDATE ON public.food_orders FOR EACH ROW EXECUTE FUNCTION log_audit_event();
CREATE TRIGGER trg_food_orders_updated_at BEFORE UPDATE ON public.food_orders FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_notify_staff_food AFTER INSERT ON public.food_orders FOR EACH ROW EXECUTE FUNCTION notify_staff_on_food_request();
CREATE TRIGGER trg_set_food_order_created_by BEFORE INSERT ON public.food_orders FOR EACH ROW EXECUTE FUNCTION set_food_order_created_by();

CREATE TRIGGER trg_audit_guest_feedback AFTER INSERT OR UPDATE ON public.guest_feedback FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER trg_guest_schedule_items_updated_at BEFORE UPDATE ON public.guest_schedule_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_notify_guest_schedule AFTER INSERT ON public.guest_schedule_items FOR EACH ROW EXECUTE FUNCTION notify_guest_on_schedule_item();
CREATE TRIGGER trg_notify_guest_schedule_completed AFTER UPDATE ON public.guest_schedule_items FOR EACH ROW EXECUTE FUNCTION notify_guest_on_schedule_completed();

CREATE TRIGGER trg_audit_guests AFTER INSERT OR UPDATE ON public.guests FOR EACH ROW EXECUTE FUNCTION log_audit_event();
CREATE TRIGGER trg_guest_auth_active BEFORE UPDATE OF auth_id ON public.guests FOR EACH ROW EXECUTE FUNCTION set_guest_active_on_auth_link();
CREATE TRIGGER trg_guests_updated_at BEFORE UPDATE ON public.guests FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_guest_created_by BEFORE INSERT ON public.guests FOR EACH ROW EXECUTE FUNCTION set_guest_created_by();
CREATE TRIGGER trg_sync_reservations_from_guest_status AFTER UPDATE OF status ON public.guests FOR EACH ROW EXECUTE FUNCTION sync_reservations_from_guest_status();

CREATE TRIGGER trg_hotel_service_categories_updated_at BEFORE UPDATE ON public.hotel_service_categories FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_hotel_services_updated_at BEFORE UPDATE ON public.hotel_services FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_audit_managers AFTER INSERT OR UPDATE ON public.managers FOR EACH ROW EXECUTE FUNCTION log_audit_event();
CREATE TRIGGER trg_managers_updated_at BEFORE UPDATE ON public.managers FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_menu_items_updated_at BEFORE UPDATE ON public.menu_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_audit_messages AFTER INSERT OR UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION log_audit_event();
CREATE TRIGGER trg_messages_updated_at BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_notify_guest_message AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION notify_guest_on_staff_message();
CREATE TRIGGER trg_notify_staff_guest_message AFTER INSERT ON public.messages FOR EACH ROW WHEN ((new.sender_type = 'guest'::text)) EXECUTE FUNCTION notify_staff_on_guest_message();

CREATE TRIGGER trg_payment_extra_items_updated_at BEFORE UPDATE ON public.payment_extra_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_audit_payments AFTER INSERT OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION log_audit_event();
CREATE TRIGGER trg_auto_unfreeze AFTER INSERT OR UPDATE OF status ON public.payments FOR EACH ROW EXECUTE FUNCTION auto_unfreeze_on_payment();
CREATE TRIGGER trg_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_payment_created_by BEFORE INSERT ON public.payments FOR EACH ROW EXECUTE FUNCTION set_payment_created_by();

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_audit_receptionists AFTER INSERT OR UPDATE ON public.receptionists FOR EACH ROW EXECUTE FUNCTION log_audit_event();
CREATE TRIGGER trg_receptionists_updated_at BEFORE UPDATE ON public.receptionists FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_audit_reservations AFTER INSERT OR UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION log_audit_event();
CREATE TRIGGER trg_notify_staff_mobile_reservation AFTER INSERT ON public.reservations FOR EACH ROW EXECUTE FUNCTION notify_staff_on_mobile_reservation();
CREATE TRIGGER trg_reservation_cancellation AFTER UPDATE OF status ON public.reservations FOR EACH ROW EXECUTE FUNCTION handle_reservation_cancellation();
CREATE TRIGGER trg_reservation_cancellation_insert AFTER INSERT ON public.reservations FOR EACH ROW WHEN ((new.status = 'CANCELLED'::reservation_status)) EXECUTE FUNCTION handle_reservation_cancellation();
CREATE TRIGGER trg_reservation_room_status AFTER INSERT OR UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION update_room_status_on_reservation();
CREATE TRIGGER trg_reservations_updated_at BEFORE UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_set_reservation_created_by BEFORE INSERT ON public.reservations FOR EACH ROW EXECUTE FUNCTION set_reservation_created_by();
CREATE TRIGGER trg_sync_guest_status_from_reservations AFTER INSERT OR DELETE OR UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION sync_guest_status_from_reservations();

CREATE TRIGGER trg_roles_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_rooms_updated_at BEFORE UPDATE ON public.rooms FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_site_content_pages_updated_at BEFORE UPDATE ON public.site_content_pages FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- 11. ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eco_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_eco_point_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_schedule_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.managers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_extra_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pending_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receptionists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_content_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sustainability_activities ENABLE ROW LEVEL SECURITY;

-- Policies

CREATE POLICY "Activities public read" ON public.activities AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public read activities" ON public.activities AS PERMISSIVE FOR SELECT TO public USING (true);

CREATE POLICY "Guests insert own activity bookings" ON public.activity_bookings AS PERMISSIVE FOR INSERT TO public WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));
CREATE POLICY "Guests manage own bookings" ON public.activity_bookings AS PERMISSIVE FOR ALL TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email())))))) WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))));
CREATE POLICY "Guests view own bookings" ON public.activity_bookings AS PERMISSIVE FOR SELECT TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));

CREATE POLICY "Admin full audit_logs" ON public.audit_logs AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = 'ADMIN'::text)))));

CREATE POLICY "Admin full departments" ON public.departments AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = 'ADMIN'::text)))));
CREATE POLICY "Staff view departments" ON public.departments AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY['MANAGER'::text, 'RECEPTIONIST'::text]))))));

CREATE POLICY "Staff manage eco tiers" ON public.eco_tiers AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY['ADMIN'::text, 'MANAGER'::text]))))));
CREATE POLICY "Staff view eco tiers" ON public.eco_tiers AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY['ADMIN'::text, 'MANAGER'::text, 'RECEPTIONIST'::text]))))));

CREATE POLICY "Guests insert own food orders" ON public.food_orders AS PERMISSIVE FOR INSERT TO public WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));
CREATE POLICY "Guests manage own food orders" ON public.food_orders AS PERMISSIVE FOR ALL TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email())))))) WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))));
CREATE POLICY "Guests view own food orders" ON public.food_orders AS PERMISSIVE FOR SELECT TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));

CREATE POLICY "Guests insert own eco events" ON public.guest_eco_point_events AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))));
CREATE POLICY "Guests update own eco events" ON public.guest_eco_point_events AS PERMISSIVE FOR UPDATE TO authenticated USING ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email())))))) WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))));
CREATE POLICY "Guests view own eco events" ON public.guest_eco_point_events AS PERMISSIVE FOR SELECT TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))));
CREATE POLICY "Staff manage eco events" ON public.guest_eco_point_events AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY['ADMIN'::text, 'MANAGER'::text, 'RECEPTIONIST'::text]))))));

CREATE POLICY "Guests insert own feedback" ON public.guest_feedback AS PERMISSIVE FOR INSERT TO public WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));
CREATE POLICY "Guests manage own feedback" ON public.guest_feedback AS PERMISSIVE FOR ALL TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR (guests.auth_id IS NULL))))) WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR (guests.auth_id IS NULL)))));

CREATE POLICY "Guests manage own schedule items" ON public.guest_schedule_items AS PERMISSIVE FOR ALL TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email())))))) WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))));
CREATE POLICY "Guests view own schedule" ON public.guest_schedule_items AS PERMISSIVE FOR SELECT TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));

CREATE POLICY "Guest update own profile" ON public.guests AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = auth_id));
CREATE POLICY "Guests select own" ON public.guests AS PERMISSIVE FOR SELECT TO public USING (((auth_id = auth.uid()) OR ((auth_id IS NULL) AND (email = auth.email()))));
CREATE POLICY "Guests update own" ON public.guests AS PERMISSIVE FOR UPDATE TO public USING (((auth_id = auth.uid()) OR ((auth_id IS NULL) AND (email = auth.email())))) WITH CHECK (((auth_id = auth.uid()) OR ((auth_id IS NULL) AND (email = auth.email()))));
CREATE POLICY "Receptionist read guests" ON public.guests AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = 'RECEPTIONIST'::text)))));
CREATE POLICY "Receptionist update guests" ON public.guests AS PERMISSIVE FOR UPDATE TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = 'RECEPTIONIST'::text)))));
CREATE POLICY "Staff full access on guests" ON public.guests AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY['ADMIN'::text, 'MANAGER'::text]))))));

CREATE POLICY "Public read hotel_service_categories" ON public.hotel_service_categories AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Service categories public read" ON public.hotel_service_categories AS PERMISSIVE FOR SELECT TO public USING (true);

CREATE POLICY "Public read hotel_services" ON public.hotel_services AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Staff manage hotel_services" ON public.hotel_services AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE (profiles.auth_id = auth.uid()))));

CREATE POLICY "Admin full managers" ON public.managers AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = 'ADMIN'::text)))));
CREATE POLICY "Manager self view" ON public.managers AS PERMISSIVE FOR SELECT TO public USING ((auth_id = auth.uid()));

CREATE POLICY "Menu items public read" ON public.menu_items AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Public read menu_items" ON public.menu_items AS PERMISSIVE FOR SELECT TO public USING (true);

CREATE POLICY "Guests manage own messages" ON public.messages AS PERMISSIVE FOR ALL TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email())))))) WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))));
CREATE POLICY "Guests send messages" ON public.messages AS PERMISSIVE FOR INSERT TO public WITH CHECK (((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))) AND (sender_type = 'guest'::text)));
CREATE POLICY "Guests view own messages" ON public.messages AS PERMISSIVE FOR ALL TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));

CREATE POLICY "Guests read own notifications" ON public.notifications AS PERMISSIVE FOR SELECT TO public USING (((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))) OR (guest_id IS NULL)));
CREATE POLICY "Guests view own notifications" ON public.notifications AS PERMISSIVE FOR SELECT TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));

CREATE POLICY "Guests view own payments" ON public.payments AS PERMISSIVE FOR SELECT TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));

CREATE POLICY "Guests view own pending" ON public.pending_reservations AS PERMISSIVE FOR SELECT TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))));

CREATE POLICY "Users can insert own profile" ON public.profiles AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth_id = auth.uid()));
CREATE POLICY "Users can update own profile" ON public.profiles AS PERMISSIVE FOR UPDATE TO public USING ((auth_id = auth.uid()));
CREATE POLICY "Users can view own profile" ON public.profiles AS PERMISSIVE FOR SELECT TO public USING ((auth_id = auth.uid()));

CREATE POLICY "Admin view receptionists" ON public.receptionists AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = 'ADMIN'::text)))));
CREATE POLICY "Manager full receptionists" ON public.receptionists AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = 'MANAGER'::text)))));
CREATE POLICY "Receptionist self view" ON public.receptionists AS PERMISSIVE FOR SELECT TO public USING ((auth_id = auth.uid()));

CREATE POLICY "Guests insert own reservations" ON public.reservations AS PERMISSIVE FOR INSERT TO public WITH CHECK ((guest_id IN ( SELECT guests.id FROM guests WHERE ((guests.auth_id = auth.uid()) OR ((guests.auth_id IS NULL) AND (guests.email = auth.email()))))));
CREATE POLICY "Guests view own reservations" ON public.reservations AS PERMISSIVE FOR SELECT TO public USING ((guest_id IN ( SELECT guests.id FROM guests WHERE (guests.auth_id = auth.uid()))));
CREATE POLICY "Staff full access on reservations" ON public.reservations AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY['ADMIN'::text, 'MANAGER'::text, 'RECEPTIONIST'::text]))))));

CREATE POLICY "Roles admin full access" ON public.roles AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = 'ADMIN'::text)))));
CREATE POLICY "Roles staff read-only" ON public.roles AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY['ADMIN'::text, 'MANAGER'::text, 'RECEPTIONIST'::text]))))));

CREATE POLICY "Public read rooms" ON public.rooms AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Rooms public read" ON public.rooms AS PERMISSIVE FOR SELECT TO public USING (true);

CREATE POLICY "Public read site_content_pages" ON public.site_content_pages AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Site content public read" ON public.site_content_pages AS PERMISSIVE FOR SELECT TO public USING (true);
CREATE POLICY "Staff manage site content" ON public.site_content_pages AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND (profiles.role = ANY (ARRAY['MAIN_RECEPTIONIST'::user_role, 'RECEPTIONIST'::user_role]))))));

CREATE POLICY "Guests view active sustainability activities" ON public.sustainability_activities AS PERMISSIVE FOR SELECT TO authenticated USING ((is_active = true));
CREATE POLICY "Staff manage sustainability activities" ON public.sustainability_activities AS PERMISSIVE FOR ALL TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY['ADMIN'::text, 'MANAGER'::text]))))));
CREATE POLICY "Staff view sustainability activities" ON public.sustainability_activities AS PERMISSIVE FOR SELECT TO public USING ((EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.auth_id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY['ADMIN'::text, 'MANAGER'::text, 'RECEPTIONIST'::text]))))));


-- =============================================================================
-- KNOWN ISSUES (pre-existing in the live database, kept verbatim above)
-- =============================================================================
-- 1. handle_reservation_cancellation() references public.itinerary_events and
--    public.guest_orders, which do not exist in this schema. The reservation
--    cancellation trigger will error if it reaches those UPDATE statements.
-- 2. auto_complete_schedule_items() and mark_schedule_item_completed() insert
--    into public.eco_points_tx and public.eco_points_balance, which also do
--    not exist — eco points are actually tracked via guest_eco_point_events
--    (get_guest_eco_points/get_eco_leaderboard use that table correctly).
--    These two functions look like leftovers from an earlier eco-points
--    design and are effectively broken/unused by the current apps.
-- These are flagged, not fixed — this file mirrors the live database as-is.
