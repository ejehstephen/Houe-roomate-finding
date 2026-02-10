-- RUN THIS SCRIPT ALONE FIRST
-- This strictly adds the missing columns required for the admin dashboard.

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS role text DEFAULT 'user';
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_banned boolean DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_verified boolean DEFAULT false;

ALTER TABLE public.room_listings ADD COLUMN IF NOT EXISTS is_featured boolean DEFAULT false;
