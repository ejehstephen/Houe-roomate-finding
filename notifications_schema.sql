-- =========================================
-- NOTIFICATIONS SYSTEM
-- =========================================

-- 1. Create Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'listing', 'match', 'system'
    is_read BOOLEAN DEFAULT FALSE,
    data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own notifications
CREATE POLICY "Users can view own notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: Users can update their own notifications (e.g. mark as read)
CREATE POLICY "Users can update own notifications" 
ON notifications FOR UPDATE 
USING (auth.uid() = user_id);

-- Policy: Users can delete their own notifications
CREATE POLICY "Users can delete own notifications" 
ON notifications FOR DELETE 
USING (auth.uid() = user_id);

-- Policy: Admins can insert notifications (e.g. for system events or verification)
CREATE POLICY "Admins can insert notifications" 
ON notifications FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Index for fetching user notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
-- Index for unread count
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id) WHERE is_read = FALSE;

-- 2. Function to Notify Users of New Listing in Same School
CREATE OR REPLACE FUNCTION notify_new_listing()
RETURNS TRIGGER AS $$
DECLARE
    owner_school VARCHAR(255);
    owner_name VARCHAR(255);
BEGIN
    -- Get the owner's school and name
    SELECT school, name INTO owner_school, owner_name
    FROM users
    WHERE id = NEW.owner_id;

    -- If owner has a school, notify others in the same school
    IF owner_school IS NOT NULL THEN
        INSERT INTO notifications (user_id, title, body, type, data)
        SELECT 
            id, 
            'New Listing at ' || owner_school, 
            owner_name || ' just posted a new room listing!', 
            'listing',
            jsonb_build_object('listing_id', NEW.id)
        FROM users
        WHERE school = owner_school 
        AND id != NEW.owner_id; -- Don't notify the owner
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Trigger for New Listings
DROP TRIGGER IF EXISTS on_new_listing ON room_listings;
CREATE TRIGGER on_new_listing
    AFTER INSERT ON room_listings
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_listing();
