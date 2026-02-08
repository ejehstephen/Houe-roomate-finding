-- Trigger to automatically create a public.users entry when a new auth.users entry is created.
-- This bypasses the need for the client to insert the user, avoiding RLS issues with unverified emails.

-- 1. Create the function
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (
    id, 
    email, 
    name, 
    school, 
    age, 
    gender, 
    profile_image, 
    phone_number, 
    enabled,
    password_hash -- Required by your schema (NOT NULL)
  )
  values (
    new.id,
    new.email,
    -- Extract metadata from raw_user_meta_data
    COALESCE(new.raw_user_meta_data->>'name', 'New User'),
    COALESCE(new.raw_user_meta_data->>'school', 'Unknown School'),
    COALESCE((new.raw_user_meta_data->>'age')::int, 18),
    COALESCE(new.raw_user_meta_data->>'gender', 'other'),
    COALESCE(new.raw_user_meta_data->>'profile_image', 'https://example.com/default-profile.png'),
    NULL, -- phone_number
    TRUE, -- enabled
    'managed_by_supabase_auth' -- Placeholder for password_hash to satisfy NOT NULL constraint
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    profile_image = EXCLUDED.profile_image;
    
  return new;
end;
$$;

-- 2. Create the trigger
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute procedure public.handle_new_user();
