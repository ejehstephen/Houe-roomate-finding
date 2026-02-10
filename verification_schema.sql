-- =========================================
-- IDENTITY VERIFICATION SYSTEM
-- =========================================

-- 1. Create Verification Requests Table
CREATE TABLE IF NOT EXISTS public.verification_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    nin_number TEXT NOT NULL,
    document_type TEXT NOT NULL CHECK (document_type IN ('NIN Card', 'School ID')),
    front_image_url TEXT NOT NULL, -- Path in storage bucket
    back_image_url TEXT, -- Path in storage bucket (Optional)
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

-- Policies
-- Users can view their own requests
CREATE POLICY "Users can view own verification requests"
ON public.verification_requests FOR SELECT
USING (auth.uid() = user_id);

-- Users can create requests
CREATE POLICY "Users can create verification requests"
ON public.verification_requests FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Only admins can update status (This requires a way to distinguish admins, 
-- effectively usually handled by service_role key or a specific admin flag in users table + policy)
-- For now, we'll allow users to update IF it's their own record (e.g. resubmitting), 
-- but ideally status update should be restricted. 
-- Since we are building an admin panel that likely uses the same auth context but with 'admin' role:

CREATE POLICY "Admins can view all verification requests"
ON public.verification_requests FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Admins can update verification requests"
ON public.verification_requests FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- 2. Storage Bucket Setup
-- Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('verification_docs', 'verification_docs', false)
ON CONFLICT (id) DO NOTHING;

-- Policy: Users can upload their own files

-- Policy: Users can upload their own files
-- bucket_id = 'verification_docs'
-- file path should start with user_id/

-- (These policies depend on specific Supabase Storage implementation details, 
-- usually managed via Dashboard or specific storage.objects policies)

-- Storage Policy: View
-- Users can view their own files, Admins can view all.
CREATE POLICY "Give users access to own folder 1oj01k_0" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'verification_docs' AND (auth.uid() = owner OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')));

-- Storage Policy: Upload
-- Users can upload to their own folder
CREATE POLICY "Give users access to own folder 1oj01k_1" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'verification_docs' AND auth.uid() = owner);

-- Storage Policy: Update/Delete
-- Users can update/delete their own files
CREATE POLICY "Give users access to own folder 1oj01k_2" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'verification_docs' AND auth.uid() = owner);
CREATE POLICY "Give users access to own folder 1oj01k_3" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'verification_docs' AND auth.uid() = owner);

-- 3. Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_verification_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_verification_timestamp
BEFORE UPDATE ON public.verification_requests
FOR EACH ROW
EXECUTE FUNCTION update_verification_updated_at();
