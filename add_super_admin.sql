-- ============================================================
-- Super Admin Protection
-- Run this in Supabase SQL Editor
-- ============================================================

-- Step 1: Add is_super_admin column
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN DEFAULT FALSE;

-- Step 2: Set YOUR account as super admin
-- Replace the email below with YOUR admin email
UPDATE public.users
SET is_super_admin = TRUE
WHERE email = 'your-email@example.com';  -- << CHANGE THIS

-- Step 3: RLS policy - only super admins can change the 'role' column
-- First drop old policy if exists
DROP POLICY IF EXISTS "Admins can update user roles" ON public.users;

-- New policy: only super admins can promote/demote
CREATE POLICY "Only super admins can change roles"
ON public.users
FOR UPDATE
USING (
  (SELECT is_super_admin FROM public.users WHERE id = auth.uid()) = TRUE
)
WITH CHECK (
  (SELECT is_super_admin FROM public.users WHERE id = auth.uid()) = TRUE
);
