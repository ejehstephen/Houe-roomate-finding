-- Enable the storage extension if not already enabled (usually enabled by default in Supabase)
-- create extension if not exists "storage";

-- 1. Create 'listings' bucket for room images and videos
insert into storage.buckets (id, name, public)
values ('listings', 'listings', true)
on conflict (id) do nothing;

-- 2. Create 'avatars' bucket for user profile images
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- ================================================================
-- POLICIES for 'listings' bucket
-- ================================================================

-- Allow Public Access to view files in 'listings'
create policy "Public Access to Listings"
on storage.objects for select
using ( bucket_id = 'listings' );

-- Allow Authenticated Users to upload files to 'listings'
create policy "Authenticated Users can Insert Listings Media"
on storage.objects for insert
with check (
  bucket_id = 'listings'
  and auth.role() = 'authenticated'
);

-- Allow Users to Update their own files in 'listings'
create policy "Users can Update their own Listing Media"
on storage.objects for update
using (
  bucket_id = 'listings'
  and auth.uid() = owner
);

-- Allow Users to Delete their own files in 'listings'
create policy "Users can Delete their own Listing Media"
on storage.objects for delete
using (
  bucket_id = 'listings'
  and auth.uid() = owner
);

-- ================================================================
-- POLICIES for 'avatars' bucket
-- ================================================================

-- Allow Public Access to view files in 'avatars'
create policy "Public Access to Avatars"
on storage.objects for select
using ( bucket_id = 'avatars' );

-- Allow Authenticated Users to upload files to 'avatars'
create policy "Authenticated Users can Insert Avatars"
on storage.objects for insert
with check (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
);

-- Allow Users to Update their own files in 'avatars'
create policy "Users can Update their own Avatars"
on storage.objects for update
using (
  bucket_id = 'avatars'
  and auth.uid() = owner
);

-- Allow Users to Delete their own files in 'avatars'
create policy "Users can Delete their own Avatars"
on storage.objects for delete
using (
  bucket_id = 'avatars'
  and auth.uid() = owner
);
