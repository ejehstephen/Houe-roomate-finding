-- 1. Add Trust & Safety columns to room_listings (Report count only)
alter table room_listings 
add column if not exists report_count int default 0;

-- 2. Create app_config table for dynamic settings (e.g. support number)
create table if not exists public.app_config (
  key text primary key,
  value text
);

alter table public.app_config enable row level security;

drop policy if exists "Allow public read access" on public.app_config;

create policy "Allow public read access"
  on public.app_config
  for select
  using (true);

insert into public.app_config (key, value)
values ('support_whatsapp', '2348134351762')
on conflict (key) do nothing;

-- 3. Create a secure RPC function to report a listing
-- This ensures users can only increment the count, not set it to arbitrary values
create or replace function report_listing(listing_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  update room_listings
  set report_count = report_count + 1
  where id = listing_id;
end;
$$;

-- 4. Grant execute permission to authenticated users
grant execute on function report_listing to authenticated;
