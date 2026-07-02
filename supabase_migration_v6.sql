-- =============================================
-- LA PIROGUE - MIGRATION v6: Reservation Activation
-- Adds confirmation_token and confirmed_at to reservations
-- Creates edge function helpers for email confirmation
-- =============================================

-- 1. ADD COLUMNS TO reservations TABLE
ALTER TABLE IF EXISTS public.reservations
  ADD COLUMN IF NOT EXISTS confirmation_token text;

ALTER TABLE IF EXISTS public.reservations
  ADD COLUMN IF NOT EXISTS confirmed_at timestamptz;

-- Add unique index on confirmation_token for fast lookups
DROP INDEX IF EXISTS idx_reservations_confirmation_token;
CREATE UNIQUE INDEX IF NOT EXISTS idx_reservations_confirmation_token
  ON public.reservations (confirmation_token)
  WHERE confirmation_token IS NOT NULL;

-- 2. RPC: confirm_reservation(token text)
-- Called by the edge function when guest clicks the email link
CREATE OR REPLACE FUNCTION public.confirm_reservation(p_token text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

-- 3. RPC: get_reservation_by_token(token text)
-- Used by the confirmation page to show reservation details
CREATE OR REPLACE FUNCTION public.get_reservation_by_token(p_token text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

-- 4. ENSURE RLS POLICY ALLOWS GUESTS TO INSERT THEIR OWN RESERVATIONS
DROP POLICY IF EXISTS "Guests insert own reservations" ON public.reservations;
CREATE POLICY "Guests insert own reservations" ON public.reservations
  FOR INSERT
  WITH CHECK (
    guest_id IN (
      SELECT id FROM public.guests
      WHERE auth_id = auth.uid()
         OR (auth_id IS NULL AND email = auth.email())
    )
  );

-- 5. VERIFICATION
SELECT 'Migration v6 complete' as status;
