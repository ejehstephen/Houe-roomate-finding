-- ENFORCE CASCADING DELETES
-- This script alters foreign key constraints to ensure that when a USER is deleted,
-- all their related data (listings, matches, messages, questionnaire answers) is automatically wiped.

-- 1. Room Listings (Owner)
-- Check if table exists before altering
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'room_listings') THEN
    ALTER TABLE public.room_listings
    DROP CONSTRAINT IF EXISTS room_listings_owner_id_fkey;

    ALTER TABLE public.room_listings
    ADD CONSTRAINT room_listings_owner_id_fkey
    FOREIGN KEY (owner_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- 2. Matches (User 1 and User 2)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'matches') THEN
    ALTER TABLE public.matches
    DROP CONSTRAINT IF EXISTS matches_user1_id_fkey;

    ALTER TABLE public.matches
    ADD CONSTRAINT matches_user1_id_fkey
    FOREIGN KEY (user1_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;

    ALTER TABLE public.matches
    DROP CONSTRAINT IF EXISTS matches_user2_id_fkey;

    ALTER TABLE public.matches
    ADD CONSTRAINT matches_user2_id_fkey
    FOREIGN KEY (user2_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- 3. Questionnaire Answers
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'questionnaire_answers') THEN
    ALTER TABLE public.questionnaire_answers
    DROP CONSTRAINT IF EXISTS questionnaire_answers_user_id_fkey;

    ALTER TABLE public.questionnaire_answers
    ADD CONSTRAINT questionnaire_answers_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- 4. Messages (Sender and Receiver)
-- Check if table exists before altering
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'messages') THEN
    
    -- Drop constraints if they exist
    EXECUTE 'ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey';
    EXECUTE 'ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_receiver_id_fkey';

    -- Add constraints with cascade
    EXECUTE 'ALTER TABLE public.messages
    ADD CONSTRAINT messages_sender_id_fkey
    FOREIGN KEY (sender_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE';

    EXECUTE 'ALTER TABLE public.messages
    ADD CONSTRAINT messages_receiver_id_fkey
    FOREIGN KEY (receiver_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE';
    
  END IF;
END $$;

-- 5. Notifications
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
    EXECUTE 'ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey';

    EXECUTE 'ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE';
  END IF;
END $$;

-- 6. Update delete_user function to also delete from public.users explicitly?
-- Actually, deleting from auth.users sends a signal. But we need a trigger to delete public.users if it's not a foreign key to auth.users with cascade.
-- Usually public.users.id REFERENCES auth.users.id ON DELETE CASCADE.
-- Let's ensure THAT constraint exists.

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
    -- First, remove any "orphan" users that exist in public.users 
    -- but do NOT exist in auth.users. This fixes the Foreign Key violation error.
    DELETE FROM public.users WHERE id NOT IN (SELECT id FROM auth.users);

    ALTER TABLE public.users
    DROP CONSTRAINT IF EXISTS users_id_fkey;

    ALTER TABLE public.users
    ADD CONSTRAINT users_id_fkey
    FOREIGN KEY (id)
    REFERENCES auth.users(id)
    ON DELETE CASCADE;
  END IF;
END $$;
