-- Create a function that allows a user to delete their own account from auth.users
-- This is necessary because public users cannot delete from auth.users directly.
create or replace function delete_user()
returns void
language plpgsql
security definer
as $$
begin
  delete from auth.users
  where id = auth.uid();
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function delete_user to authenticated;
