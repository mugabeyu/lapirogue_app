-- =============================================
-- LA PIROGUE - COMPREHENSIVE FIX v4
-- Notifications, Schedule Auto-Complete, File Messages
-- =============================================

-- =============================================
-- 1. ADD file_url COLUMN TO messages TABLE
-- =============================================
ALTER TABLE IF EXISTS public.messages
  ADD COLUMN IF NOT EXISTS file_url text;

ALTER TABLE IF EXISTS public.messages
  ADD COLUMN IF NOT EXISTS file_name text;

ALTER TABLE IF EXISTS public.messages
  ADD COLUMN IF NOT EXISTS file_type text;

ALTER TABLE IF EXISTS public.messages
  ADD COLUMN IF NOT EXISTS file_size integer;

-- =============================================
-- 2. ADD completed_at COLUMN TO guest_schedule_items
-- =============================================
ALTER TABLE IF EXISTS public.guest_schedule_items
  ADD COLUMN IF NOT EXISTS completed_at timestamptz;

-- =============================================
-- 3. ADD eco_points_awarded COLUMN TO track if points were given
-- =============================================
ALTER TABLE IF EXISTS public.guest_schedule_items
  ADD COLUMN IF NOT EXISTS eco_points_awarded boolean DEFAULT false;

-- =============================================
-- 4. IMPROVED NOTIFICATION TRIGGERS (ensure guest_id always set)
-- =============================================

-- 4a. Guest gets notified when staff sends a message (already has guest_id)
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

-- 4b. Guest gets notified when schedule item is created (with guest_id)
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

-- 4c. Guest gets notified when schedule item is auto-completed
CREATE OR REPLACE FUNCTION public.notify_guest_on_schedule_completed()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

DROP TRIGGER IF EXISTS trg_notify_guest_schedule_completed ON public.guest_schedule_items;
CREATE TRIGGER trg_notify_guest_schedule_completed
  AFTER UPDATE ON public.guest_schedule_items
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_guest_on_schedule_completed();

-- =============================================
-- 5. FUNCTION: auto_complete_schedule_items()
-- Marks schedule items as COMPLETED when 5+ mins past endAt
-- Awards eco-points (prevents double-awarding)
-- =============================================
CREATE OR REPLACE FUNCTION public.auto_complete_schedule_items()
RETURNS TABLE(
  item_id uuid,
  guest_id uuid,
  title text,
  points_awarded int
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
    -- Mark as completed
    UPDATE public.guest_schedule_items
    SET status = 'COMPLETED',
        completed_at = now(),
        eco_points_awarded = true
    WHERE id = v_item.id;

    -- Award eco points (25 per completed activity)
    INSERT INTO public.eco_points_tx (guest_id, tx_type, points, description, status)
    VALUES (
      v_item.guest_id,
      'EARN',
      25,
      'Completed scheduled activity: ' || v_item.title,
      'COMPLETED'
    );

    -- Update balance
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

    -- Return row
    item_id := v_item.id;
    guest_id := v_item.guest_id;
    title := v_item.title;
    points_awarded := 25;
    RETURN NEXT;
  END LOOP;
END;
$$;

-- =============================================
-- 6. FUNCTION: mark_schedule_item_completed( item_id uuid )
-- Marks a single schedule item as completed with 5-min check
-- Returns false if already completed or too early
-- =============================================
CREATE OR REPLACE FUNCTION public.mark_schedule_item_completed(p_item_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_item record;
  v_result jsonb;
BEGIN
  -- Lock the row to prevent race conditions
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

  -- Check if 5+ minutes past end_at (skip for manual force-complete)
  IF (v_item.end_at + INTERVAL '5 minutes') > now() THEN
    RETURN jsonb_build_object('success', false, 'error', 'Too early to mark as completed');
  END IF;

  -- Mark as completed
  UPDATE public.guest_schedule_items
  SET status = 'COMPLETED',
      completed_at = now(),
      eco_points_awarded = true
  WHERE id = p_item_id;

  -- Only award points if not already awarded
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
$$;

-- =============================================
-- 7. ADD guest_id TO NOTIFICATION TRIGGERS THAT MISS IT
-- =============================================

-- Staff notification triggers should create notifications WITHOUT guest_id (staff-only)
-- But guest notification triggers should ALWAYS include guest_id

-- Update: notify_staff_on_booking_request stays as-is (no guest_id = staff notification)
-- Update: notify_staff_on_food_request stays as-is (no guest_id = staff notification)

-- Add a new trigger for activity booking status changes -> notify guest
CREATE OR REPLACE FUNCTION public.notify_guest_on_booking_update()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

DROP TRIGGER IF EXISTS trg_notify_guest_booking ON public.activity_bookings;
CREATE TRIGGER trg_notify_guest_booking
  AFTER UPDATE ON public.activity_bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_guest_on_booking_update();

-- =============================================
-- 8. ENABLE REALTIME FOR notifications TABLE
-- =============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END;
$$;

-- =============================================
-- 9. STORAGE: Ensure chat_uploads bucket has proper policies
-- =============================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('chat_uploads', 'chat_uploads', true, 20971520, ARRAY['image/png','image/jpeg','image/jpg','image/webp','image/gif','application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document','text/plain','application/zip'])
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = 20971520,
  allowed_mime_types = ARRAY['image/png','image/jpeg','image/jpg','image/webp','image/gif','application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document','text/plain','application/zip'];

-- Allow authenticated users (guests via auth_id) to upload to chat_uploads
DROP POLICY IF EXISTS "Chat uploads authenticated" ON storage.objects;
CREATE POLICY "Chat uploads authenticated" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'chat_uploads'
    AND auth.role() = 'authenticated'
  );

DROP POLICY IF EXISTS "Chat uploads read all" ON storage.objects;
CREATE POLICY "Chat uploads read all" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'chat_uploads'
  );

-- =============================================
-- VERIFICATION
-- =============================================
SELECT 'Fix v4 complete' as status;
