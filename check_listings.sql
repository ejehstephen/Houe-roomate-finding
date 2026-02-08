-- Check if any listings exist
SELECT count(*) as listing_count FROM room_listings;

-- Check if any users exist
SELECT count(*) as user_count FROM users;

-- Check if the dummy owner exists
SELECT * FROM users WHERE email = 'owner@example.com';

-- List all listings with their owner IDs
SELECT id, title, owner_id, is_active FROM room_listings;
