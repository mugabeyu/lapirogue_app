-- =============================================
-- LA PIROGUE - FIX v5: Guest->Admin Messaging
-- Ensures staff gets notified when guests reply
-- Run in SQL Editor: https://supabase.com/dashboard/project/txalwdljaxltchcrauhp/sql/new
-- =============================================

-- =============================================
-- 1. STAFF NOTIFICATION when guest sends a message
--    The existing trigger only notifies the GUEST
--    when staff messages. This adds the reverse:
--    notify STAFF when a guest replies.
-- =============================================
CREATE OR REPLACE FUNCTION public.notify_staff_on_guest_message()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

DROP TRIGGER IF EXISTS trg_notify_staff_guest_message ON public.messages;
CREATE TRIGGER trg_notify_staff_guest_message
  AFTER INSERT ON public.messages
  FOR EACH ROW
  WHEN (NEW.sender_type = 'guest')
  EXECUTE FUNCTION public.notify_staff_on_guest_message();

-- =============================================
-- VERIFICATION
-- =============================================
SELECT 'Fix v5 complete' as status;
