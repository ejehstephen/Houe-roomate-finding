-- Seed Data for Room Listings
-- Matched EXACTLY to DummyData.dart

do $$
declare
  dummy_owner_id uuid;
  listing1_id uuid := gen_random_uuid();
  listing2_id uuid := gen_random_uuid();
  listing3_id uuid := gen_random_uuid();
begin

  -- 1. Ensure the Demo Owner exists
  select id into dummy_owner_id from users where email = 'owner@example.com';

  if dummy_owner_id is null then
     dummy_owner_id := gen_random_uuid();
     insert into users (id, email, name, school, age, gender, password_hash, enabled)
     values (dummy_owner_id, 'owner@example.com', 'Demo Owner', 'CampNest University', 22, 'male', 'placeholder', true);
  end if;

  -- 2. Clear existing seed listings to avoid duplicates if run multiple times
  -- (Optional: remove this block if you want to keep adding)
   DELETE FROM room_listings WHERE title IN (
    'Cozy Studio Near Campus',
    'Shared Apartment - 2BR/2BA',
    'Private Room in House'
   );

  -- 3. Insert Listings

  -- Listing 1: Cozy Studio
  insert into room_listings (id, title, description, price, location, owner_id, gender_preference, available_from, is_active, owner_phone, whatsapp_link)
  values (
    listing1_id,
    'Cozy Studio Near Campus',
    'Beautiful studio apartment just 5 minutes walk from university. Fully furnished with modern amenities.',
    800.0,
    'Downtown Campus Area',
    dummy_owner_id,
    'female',
    CURRENT_DATE + 30,
    true,
    '+1234567890',
    'https://wa.me/1234567890'
  );

  insert into room_listing_images (room_listing_id, images) values 
    (listing1_id, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-1.2.1&auto=format&fit=crop&w=1050&q=80'),
    (listing1_id, 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-1.2.1&auto=format&fit=crop&w=973&q=80');

  insert into room_listing_amenities (room_listing_id, amenities) values 
    (listing1_id, 'WiFi'), (listing1_id, 'Laundry'), (listing1_id, 'Kitchen'), (listing1_id, 'Parking');

  insert into room_listing_rules (room_listing_id, rules) values 
    (listing1_id, 'No smoking'), (listing1_id, 'No pets'), (listing1_id, 'Quiet hours after 10 PM');


  -- Listing 2: Shared Apartment
  insert into room_listings (id, title, description, price, location, owner_id, gender_preference, available_from, is_active, owner_phone, whatsapp_link)
  values (
    listing2_id,
    'Shared Apartment - 2BR/2BA',
    'Looking for a roommate to share this spacious 2-bedroom apartment. Great location with easy access to public transport.',
    600.0,
    'University District',
    dummy_owner_id,
    'any',
    CURRENT_DATE + 15,
    true,
    '+1987654321',
    'https://wa.me/1987654321'
  );

   insert into room_listing_images (room_listing_id, images) values 
    (listing2_id, 'https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?ixlib=rb-1.2.1&auto=format&fit=crop&w=1050&q=80'),
    (listing2_id, 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?ixlib=rb-1.2.1&auto=format&fit=crop&w=1053&q=80');

  insert into room_listing_amenities (room_listing_id, amenities) values 
    (listing2_id, 'WiFi'), (listing2_id, 'Gym'), (listing2_id, 'Pool'), (listing2_id, 'Study Room');

  insert into room_listing_rules (room_listing_id, rules) values 
    (listing2_id, 'No smoking'), (listing2_id, 'Clean common areas'), (listing2_id, 'Guests welcome');


   -- Listing 3: Private Room
  insert into room_listings (id, title, description, price, location, owner_id, gender_preference, available_from, is_active, owner_phone, whatsapp_link)
  values (
    listing3_id,
    'Private Room in House',
    'Private bedroom in a 4-bedroom house with 3 other students. Friendly environment and great for studying.',
    450.0,
    'Residential Area',
    dummy_owner_id,
    'female',
    CURRENT_DATE + 7,
    true,
    '+1122334455',
    'https://wa.me/1122334455'
  );

   insert into room_listing_images (room_listing_id, images) values 
    (listing3_id, 'https://images.unsplash.com/photo-1505693416388-b0346ef41492?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80');

  insert into room_listing_amenities (room_listing_id, amenities) values 
    (listing3_id, 'WiFi'), (listing3_id, 'Kitchen'), (listing3_id, 'Backyard'), (listing3_id, 'Parking');

  insert into room_listing_rules (room_listing_id, rules) values 
    (listing3_id, 'No smoking'), (listing3_id, 'Keep common areas clean'), (listing3_id, 'No loud music after 11 PM');

end;
$$;
