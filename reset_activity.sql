-- Reset last_active_at for all users to NULL
-- This clears the "false positive" active status caused by the initial migration
UPDATE public.users
SET last_active_at = NULL;
