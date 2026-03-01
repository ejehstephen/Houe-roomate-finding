-- Add last_active_at column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- RPC to update user activity
CREATE OR REPLACE FUNCTION update_user_activity(user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.users
  SET last_active_at = NOW()
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC to get active user stats
CREATE OR REPLACE FUNCTION admin_get_active_user_stats()
RETURNS JSON AS $$
DECLARE
  daily_count INT;
  weekly_count INT;
  monthly_count INT;
BEGIN
  -- Daily Active Users (last 24 hours)
  SELECT COUNT(*) INTO daily_count
  FROM public.users
  WHERE last_active_at >= NOW() - INTERVAL '24 hours';

  -- Weekly Active Users (last 7 days)
  SELECT COUNT(*) INTO weekly_count
  FROM public.users
  WHERE last_active_at >= NOW() - INTERVAL '7 days';

  -- Monthly Active Users (last 30 days)
  SELECT COUNT(*) INTO monthly_count
  FROM public.users
  WHERE last_active_at >= NOW() - INTERVAL '30 days';

  RETURN json_build_object(
    'daily', daily_count,
    'weekly', weekly_count,
    'monthly', monthly_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
