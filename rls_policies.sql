-- Enable Row Level Security (RLS) on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_verification_code ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_listing_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_listing_amenities ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_listing_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE questionnaire_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE questionnaire_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE answer_values ENABLE ROW LEVEL SECURITY;

-- =========================================
-- 1. USERS
-- =========================================
-- Allow everyone (authenticated or not) to read profiles for matching/display
CREATE POLICY "Public profiles are viewable by everyone" 
ON users FOR SELECT 
USING (true);

-- Allow users to insert their OWN profile during sign up
-- Note: Requires that the inserted 'id' matches the Supabase Auth 'uid'
CREATE POLICY "Users can insert their own profile" 
ON users FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Allow users to update their OWN profile
CREATE POLICY "Users can update own profile" 
ON users FOR UPDATE 
USING (auth.uid() = id);

-- =========================================
-- 2. EMAIL VERIFICATION
-- =========================================
CREATE POLICY "Users view own verification codes"
ON email_verification_code FOR SELECT
USING (auth.uid() = user_id);

-- =========================================
-- 3. ROOM LISTINGS
-- =========================================
-- Active listings are viewable by everyone
CREATE POLICY "Listings are viewable by everyone" 
ON room_listings FOR SELECT 
USING (true);

-- Authenticated users can create listings (must own them)
CREATE POLICY "Users can create listings" 
ON room_listings FOR INSERT 
WITH CHECK (auth.uid() = owner_id);

-- Owners can monitor/update their listings
CREATE POLICY "Owners can update listings" 
ON room_listings FOR UPDATE 
USING (auth.uid() = owner_id);

-- Owners can delete their listings
CREATE POLICY "Owners can delete listings" 
ON room_listings FOR DELETE 
USING (auth.uid() = owner_id);

-- =========================================
-- 4. LISTING DETAILS (Images, Amenities, Rules)
-- =========================================
-- Viewable by everyone
CREATE POLICY "Listing images viewable by everyone" ON room_listing_images FOR SELECT USING (true);
CREATE POLICY "Listing amenities viewable by everyone" ON room_listing_amenities FOR SELECT USING (true);
CREATE POLICY "Listing rules viewable by everyone" ON room_listing_rules FOR SELECT USING (true);

-- Manageable by listing owner (recursive check on parent listing)
CREATE POLICY "Owners manage images" ON room_listing_images FOR ALL 
USING (EXISTS (SELECT 1 FROM room_listings WHERE id = room_listing_images.room_listing_id AND owner_id = auth.uid()));

CREATE POLICY "Owners manage amenities" ON room_listing_amenities FOR ALL 
USING (EXISTS (SELECT 1 FROM room_listings WHERE id = room_listing_amenities.room_listing_id AND owner_id = auth.uid()));

CREATE POLICY "Owners manage rules" ON room_listing_rules FOR ALL 
USING (EXISTS (SELECT 1 FROM room_listings WHERE id = room_listing_rules.room_listing_id AND owner_id = auth.uid()));

-- =========================================
-- 5. QUESTIONNAIRE QUESTIONS & OPTIONS
-- =========================================
-- Read-only for everyone
CREATE POLICY "Questions viewable by everyone" ON questionnaire_questions FOR SELECT USING (true);
CREATE POLICY "Options viewable by everyone" ON question_options FOR SELECT USING (true);

-- =========================================
-- 6. QUESTIONNAIRE ANSWERS
-- =========================================
-- Viewable by authenticated users (needed for matching calculations)
CREATE POLICY "Answers viewable by authenticated users" 
ON questionnaire_answers FOR SELECT 
TO authenticated 
USING (true);

-- Users manage their own answers
CREATE POLICY "Users manage own answers" 
ON questionnaire_answers FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- =========================================
-- 7. ANSWER VALUES
-- =========================================
-- Viewable by authenticated users
CREATE POLICY "Answer values viewable by authenticated users" 
ON answer_values FOR SELECT 
TO authenticated 
USING (true);

-- Users manage their own answer values (via parent answer check)
CREATE POLICY "Users manage own answer values" 
ON answer_values FOR ALL 
USING (EXISTS (SELECT 1 FROM questionnaire_answers WHERE id = answer_values.answer_id AND user_id = auth.uid()));
