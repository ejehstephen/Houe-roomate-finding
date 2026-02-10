-- PART 2: FUNCTIONS AND POLICIES
-- Run this script SECOND, only after successfully running admin_tables.sql

-- Policies requiring 'role' column
-- (Moved here to ensure table structure is ready)

DROP POLICY IF EXISTS "Admins can view reports" ON public.reports;
CREATE POLICY "Admins can view reports" ON public.reports FOR SELECT TO authenticated USING (
    (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

DROP POLICY IF EXISTS "Admins can update reports" ON public.reports;
CREATE POLICY "Admins can update reports" ON public.reports FOR UPDATE TO authenticated USING (
    (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

-- Function to ban a user
CREATE OR REPLACE FUNCTION admin_ban_user(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Access Denied: Only admins can ban users';
  END IF;

  UPDATE public.users SET is_banned = true WHERE id = target_user_id;
  UPDATE public.room_listings SET is_active = false WHERE owner_id = target_user_id;
END;
$$;

-- Function to verify a user
CREATE OR REPLACE FUNCTION admin_verify_user(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Access Denied';
  END IF;

  UPDATE public.users SET is_verified = true WHERE id = target_user_id;
END;
$$;

-- Function to feature a listing
CREATE OR REPLACE FUNCTION admin_feature_listing(target_listing_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Access Denied';
  END IF;

  UPDATE public.room_listings SET is_featured = true WHERE id = target_listing_id;
END;
$$;

-- Function to delete a listing
CREATE OR REPLACE FUNCTION admin_delete_listing(target_listing_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Access Denied';
  END IF;

  DELETE FROM public.room_listings WHERE id = target_listing_id;
END;
$$;

-- Function to get platform stats
CREATE OR REPLACE FUNCTION admin_get_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  total_users int;
  active_listings int;
  pending_reports int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Access Denied';
  END IF;

  SELECT count(*) INTO total_users FROM public.users;
  SELECT count(*) INTO active_listings FROM public.room_listings WHERE is_active = true;
  SELECT count(*) INTO pending_reports FROM public.reports WHERE status = 'pending';

  RETURN json_build_object(
    'total_users', total_users,
    'active_listings', active_listings,
    'pending_reports', pending_reports
  );
END;
$$;

-- Broadcast notification helper
CREATE OR REPLACE FUNCTION admin_broadcast_notification(title text, body text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Access Denied';
  END IF;

  INSERT INTO public.notifications (user_id, title, body, type, is_read)
  SELECT id, title, body, 'system', false FROM public.users;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION admin_ban_user TO authenticated;
GRANT EXECUTE ON FUNCTION admin_verify_user TO authenticated;
GRANT EXECUTE ON FUNCTION admin_feature_listing TO authenticated;
GRANT EXECUTE ON FUNCTION admin_delete_listing TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_stats TO authenticated;
GRANT EXECUTE ON FUNCTION admin_broadcast_notification TO authenticated;
