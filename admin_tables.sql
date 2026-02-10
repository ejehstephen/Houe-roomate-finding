-- PART 1: TABLES AND COLUMNS
-- Run this script FIRST to update your database structure.

-- 1. Add Admin Role and Verification/Ban Status to Users table
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE public.users ADD COLUMN role text DEFAULT 'user';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'is_banned') THEN
        ALTER TABLE public.users ADD COLUMN is_banned boolean DEFAULT false;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'is_verified') THEN
        ALTER TABLE public.users ADD COLUMN is_verified boolean DEFAULT false;
    END IF;
END $$;

-- 2. Enhance Room Listings (Featured Status)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'room_listings' AND column_name = 'is_featured') THEN
        ALTER TABLE public.room_listings ADD COLUMN is_featured boolean DEFAULT false;
    END IF;
END $$;

-- 3. Create Reports Table
CREATE TABLE IF NOT EXISTS public.reports (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
    reported_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL, 
    reported_listing_id uuid REFERENCES public.room_listings(id) ON DELETE SET NULL, 
    reason text NOT NULL,
    details text,
    status text DEFAULT 'pending', 
    created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Policies for Reports
DROP POLICY IF EXISTS "Users can create reports" ON public.reports;
CREATE POLICY "Users can create reports" ON public.reports FOR INSERT TO authenticated WITH CHECK (auth.uid() = reporter_id);


