-- Add is_owner_verified column to room_listings table
ALTER TABLE room_listings 
ADD COLUMN is_owner_verified BOOLEAN DEFAULT FALSE;

-- Update existing records based on user verification status (optional, but good practice)
-- This assumes a 'users' table or similar where verification status is stored.
-- If you rely on the app to set this for new listings, the default FALSE is safe.
