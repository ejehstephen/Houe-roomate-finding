-- Add missing columns to the users table to match UserModel
-- This fixes "column not found" errors when updating profile.

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS preferences text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS phone_number text,
ADD COLUMN IF NOT EXISTS profile_image text;

-- Verify the columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users';
