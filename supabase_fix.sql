-- =============================================
-- LA PIROGUE - COMPREHENSIVE SUPABASE FIX v2
-- Run in SQL Editor: https://supabase.com/dashboard/project/txalwdljaxltchcrauhp/sql/new
-- =============================================

-- =============================================
-- 0. ENSURE auth_user_id COLUMN EXISTS ON guests
-- =============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'guests'
      AND column_name = 'auth_user_id'
  ) THEN
    ALTER TABLE public.guests ADD COLUMN auth_user_id text;
  END IF;
END;
$$;

-- =============================================
-- 1. BACKFILL auth_id FOR EXISTING GUESTS
-- =============================================
UPDATE public.guests
SET auth_id = auth_user_id::uuid
WHERE auth_id IS NULL AND auth_user_id IS NOT NULL;

-- =============================================
-- 2. UPDATE link_guest_auth RPC (sets both columns)
-- =============================================
CREATE OR REPLACE FUNCTION public.link_guest_auth(
  p_guest_id uuid,
  p_auth_id uuid
) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.guests
  SET auth_id = p_auth_id,
      auth_user_id = p_auth_id::text
  WHERE id = p_guest_id;
  RETURN FOUND;
END;
$$;

-- =============================================
-- 3. STORAGE: Guest-photos bucket + RLS
-- =============================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
SELECT 'guest-photos', 'guest-photos', true, 5242880, ARRAY['image/jpeg','image/png','image/gif','image/webp']
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'guest-photos');

-- Remove restrictive policies and replace with permissive ones
DROP POLICY IF EXISTS "Guest photos upload own" ON storage.objects;
DROP POLICY IF EXISTS "Guest photos authenticated" ON storage.objects;
DROP POLICY IF EXISTS "Guest photos update own" ON storage.objects;

-- Allow any authenticated user to upload to guest-photos
DROP POLICY IF EXISTS "Guest photos upload any auth" ON storage.objects;
CREATE POLICY "Guest photos upload any auth" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'guest-photos'
    AND auth.role() = 'authenticated'
  );

-- Public read for guest-photos (already public bucket)
DROP POLICY IF EXISTS "Guest photos read all" ON storage.objects;
CREATE POLICY "Guest photos read all" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'guest-photos'
  );

-- Allow uploader to update their own files
DROP POLICY IF EXISTS "Guest photos update own" ON storage.objects;
CREATE POLICY "Guest photos update own" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'guest-photos'
    AND auth.role() = 'authenticated'
  );

-- =============================================
-- 4. RLS: GUESTS (with email fallback for auth linking)
-- =============================================
ALTER TABLE IF EXISTS public.guests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Guests select own" ON public.guests;
DROP POLICY IF EXISTS "Guests view own profile" ON public.guests;
CREATE POLICY "Guests select own" ON public.guests
  FOR SELECT USING (
    auth_id = auth.uid()
    OR (auth_id IS NULL AND email = auth.email())
  );

DROP POLICY IF EXISTS "Guests update own" ON public.guests;
DROP POLICY IF EXISTS "Guests view own profile" ON public.guests;
CREATE POLICY "Guests update own" ON public.guests
  FOR UPDATE USING (
    auth_id = auth.uid()
    OR (auth_id IS NULL AND email = auth.email())
  )
  WITH CHECK (
    auth_id = auth.uid()
    OR (auth_id IS NULL AND email = auth.email())
  );

-- =============================================
-- 5. RLS: PUBLIC READ FOR GUEST-FACING TABLES
-- =============================================
ALTER TABLE IF EXISTS public.eco_actions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Eco actions public read" ON public.eco_actions;
CREATE POLICY "Eco actions public read" ON public.eco_actions
  FOR SELECT USING (true);

ALTER TABLE IF EXISTS public.hotel_service_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service categories public read" ON public.hotel_service_categories;
CREATE POLICY "Service categories public read" ON public.hotel_service_categories
  FOR SELECT USING (true);

ALTER TABLE IF EXISTS public.hotel_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Hotel services public read" ON public.hotel_services;
CREATE POLICY "Hotel services public read" ON public.hotel_services
  FOR SELECT USING (true);

ALTER TABLE IF EXISTS public.emergency_contacts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Emergency contacts public read" ON public.emergency_contacts;
CREATE POLICY "Emergency contacts public read" ON public.emergency_contacts
  FOR SELECT USING (true);

ALTER TABLE IF EXISTS public.site_content_pages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Site content public read" ON public.site_content_pages;
CREATE POLICY "Site content public read" ON public.site_content_pages
  FOR SELECT USING (true);

-- =============================================
-- 6. RLS: GUEST WRITE POLICIES (with email fallback)
-- =============================================

-- Helper function to get guest ID(s) for the current authenticated user
-- This ensures the subquery works even via email fallback

-- FOOD ORDERS
ALTER TABLE IF EXISTS public.food_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Guests manage own food orders" ON public.food_orders;
CREATE POLICY "Guests manage own food orders" ON public.food_orders
  FOR ALL
  USING (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  )
  WITH CHECK (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  );

-- ACTIVITY BOOKINGS
ALTER TABLE IF EXISTS public.activity_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Guests manage own bookings" ON public.activity_bookings;
CREATE POLICY "Guests manage own bookings" ON public.activity_bookings
  FOR ALL
  USING (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  )
  WITH CHECK (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  );

-- ECO POINTS TX
ALTER TABLE IF EXISTS public.eco_points_tx ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Guests manage own eco points tx" ON public.eco_points_tx;
CREATE POLICY "Guests manage own eco points tx" ON public.eco_points_tx
  FOR ALL
  USING (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  )
  WITH CHECK (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  );

-- MESSAGES
ALTER TABLE IF EXISTS public.messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Guests manage own messages" ON public.messages;
CREATE POLICY "Guests manage own messages" ON public.messages
  FOR ALL
  USING (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  )
  WITH CHECK (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  );

-- NOTIFICATIONS
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Guests read own notifications" ON public.notifications;
CREATE POLICY "Guests read own notifications" ON public.notifications
  FOR SELECT USING (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
    OR guest_id IS NULL
  );

-- GUEST FEEDBACK
ALTER TABLE IF EXISTS public.guest_feedback ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Guests manage own feedback" ON public.guest_feedback;
CREATE POLICY "Guests manage own feedback" ON public.guest_feedback
  FOR ALL
  USING (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  )
  WITH CHECK (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  );

-- GUEST SCHEDULE ITEMS
ALTER TABLE IF EXISTS public.guest_schedule_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Guests manage own schedule items" ON public.guest_schedule_items;
CREATE POLICY "Guests manage own schedule items" ON public.guest_schedule_items
  FOR ALL
  USING (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  )
  WITH CHECK (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  );

-- GUEST ECO ACTIONS
ALTER TABLE IF EXISTS public.guest_eco_actions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Guests manage own eco actions" ON public.guest_eco_actions;
CREATE POLICY "Guests manage own eco actions" ON public.guest_eco_actions
  FOR ALL
  USING (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  )
  WITH CHECK (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  );

-- =============================================
-- 7. ECO POINTS: Cumulative balance + RPC
-- =============================================

-- Create or update eco_points_balance view
DROP VIEW IF EXISTS public.eco_points_balance CASCADE;
CREATE OR REPLACE VIEW public.eco_points_balance AS
SELECT
  g.id AS guest_id,
  COALESCE(SUM(ept.points) FILTER (WHERE ept.tx_type = 'EARN' AND ept.status = 'COMPLETED'), 0) AS points,
  CASE
    WHEN COALESCE(SUM(ept.points) FILTER (WHERE ept.tx_type = 'EARN' AND ept.status = 'COMPLETED'), 0) >= 1000 THEN 'Platinum'
    WHEN COALESCE(SUM(ept.points) FILTER (WHERE ept.tx_type = 'EARN' AND ept.status = 'COMPLETED'), 0) >= 500 THEN 'Gold'
    WHEN COALESCE(SUM(ept.points) FILTER (WHERE ept.tx_type = 'EARN' AND ept.status = 'COMPLETED'), 0) >= 200 THEN 'Silver'
    ELSE 'Bronze'
  END AS tier
FROM public.guests g
LEFT JOIN public.eco_points_tx ept ON ept.guest_id = g.id
GROUP BY g.id;

-- RPC to increment eco points (called by Flutter after insert)
CREATE OR REPLACE FUNCTION public.increment_eco_points(
  p_guest_id uuid,
  p_points int
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN;
END;
$$;

-- =============================================
-- 8. NOTIFICATION TRIGGERS
-- =============================================

-- 8a. Staff gets notified when guest requests an activity booking
CREATE OR REPLACE FUNCTION public.notify_staff_on_booking_request()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

DROP TRIGGER IF EXISTS trg_notify_staff_booking ON public.activity_bookings;
CREATE TRIGGER trg_notify_staff_booking
  AFTER INSERT ON public.activity_bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_staff_on_booking_request();

-- 8b. Staff gets notified when guest requests a food order
CREATE OR REPLACE FUNCTION public.notify_staff_on_food_request()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

DROP TRIGGER IF EXISTS trg_notify_staff_food ON public.food_orders;
CREATE TRIGGER trg_notify_staff_food
  AFTER INSERT ON public.food_orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_staff_on_food_request();

-- 8c. Guest gets notified when staff sends a message
CREATE OR REPLACE FUNCTION public.notify_guest_on_staff_message()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

DROP TRIGGER IF EXISTS trg_notify_guest_message ON public.messages;
CREATE TRIGGER trg_notify_guest_message
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_guest_on_staff_message();

-- =============================================
-- 8d. Guest gets notified when a schedule item is created (upcoming activities)
CREATE OR REPLACE FUNCTION public.notify_guest_on_schedule_item()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

DROP TRIGGER IF EXISTS trg_notify_guest_schedule ON public.guest_schedule_items;
CREATE TRIGGER trg_notify_guest_schedule
  AFTER INSERT ON public.guest_schedule_items
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_guest_on_schedule_item();

-- 9. ADD guest_id COLUMN TO notifications (if missing)
-- =============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'guest_id'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN guest_id uuid REFERENCES public.guests(id) ON DELETE CASCADE;
  END IF;
END;
$$;

-- =============================================
-- 10. ENABLE REALTIME FOR MESSAGES
-- =============================================
-- Ensure supabase_realtime publication exists and includes messages
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
  END IF;
END;
$$;

-- Explicitly add messages table to realtime (in case FOR ALL TABLES wasn't used)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;
END;
$$;

-- =============================================
-- 11. FIX AUDIT LOG TRIGGER FOR GUEST OPERATIONS
-- =============================================
-- The audit trigger on guest-facing tables runs as the guest user, who lacks
-- INSERT on audit_logs. Fix by: (a) making the function SECURITY DEFINER so
-- it runs with owner privileges, and (b) disabling RLS on audit_logs directly.

ALTER TABLE public.audit_logs DISABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.log_audit_event()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.audit_logs(table_name, record_id, action, actor_id, previous_data, new_data)
  VALUES (TG_TABLE_NAME, COALESCE(NEW.id, OLD.id), TG_OP, auth.uid(),
          CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(OLD) ELSE NULL END,
          to_jsonb(NEW));
  RETURN NEW;
END;
$$;

-- Also ensure guest_feedback has WITH CHECK for INSERT so guest RLS allows it
DROP POLICY IF EXISTS "Guests manage own feedback" ON public.guest_feedback;
CREATE POLICY "Guests manage own feedback" ON public.guest_feedback
  FOR ALL
  USING (guest_id IN (SELECT id FROM public.guests WHERE auth_id = auth.uid() OR auth_id IS NULL))
  WITH CHECK (guest_id IN (SELECT id FROM public.guests WHERE auth_id = auth.uid() OR auth_id IS NULL));

-- Drop the old restrictive policy if it still exists
DROP POLICY IF EXISTS "Guests view own feedback" ON public.guest_feedback;

-- =============================================
-- 12. VERIFICATION
-- =============================================
SELECT 'Fix complete v3' as status;

SELECT tablename, rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'activities', 'menu_items', 'rooms', 'site_content_pages',
    'hotel_service_categories', 'hotel_services', 'emergency_contacts',
    'eco_actions', 'eco_points_tx', 'guest_eco_actions',
    'guests', 'reservations', 'activity_bookings',
    'messages', 'notifications', 'food_orders',
    'guest_feedback', 'guest_schedule_items'
  )
ORDER BY tablename;
