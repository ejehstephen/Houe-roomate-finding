-- Seed Questionnaire Questions and Options with UUIDs

-- 1. Insert/Update Questions
INSERT INTO questionnaire_questions (id, question, type) VALUES
  ('22222222-2222-2222-2222-222222222222', 'How would you describe your cleanliness level?', 'single'),
  ('33333333-3333-3333-3333-333333333333', 'What is your typical sleep schedule?', 'single'),
  ('44444444-4444-4444-4444-444444444444', 'How social are you?', 'single'),
  ('55555555-5555-5555-5555-555555555555', 'Do you smoke or drink?', 'single'),
  ('66666666-6666-6666-6666-666666666666', 'How often do you have guests over?', 'single'),
  ('77777777-7777-7777-7777-777777777777', 'What are your study habits?', 'multiple'),
  ('99999999-9999-9999-9999-999999999999', 'What are your hobbies/interests?', 'multiple'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'How important is it to be friends with your roommate?', 'single'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Do you have an apartment?', 'single')
ON CONFLICT (id) DO UPDATE SET
  question = EXCLUDED.question,
  type = EXCLUDED.type;

-- 2. Refresh Options (Delete old options for these questions to avoid duplicates)
DELETE FROM question_options WHERE question_id IN (
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  '44444444-4444-4444-4444-444444444444',
  '55555555-5555-5555-5555-555555555555',
  '66666666-6666-6666-6666-666666666666',
  '77777777-7777-7777-7777-777777777777',
  '99999999-9999-9999-9999-999999999999',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
);

-- 3. Insert Options for each Question

-- Question 2: Cleanliness
INSERT INTO question_options (question_id, options) VALUES
  ('22222222-2222-2222-2222-222222222222', 'Very messy'),
  ('22222222-2222-2222-2222-222222222222', 'Somewhat messy'),
  ('22222222-2222-2222-2222-222222222222', 'Average'),
  ('22222222-2222-2222-2222-222222222222', 'Clean'),
  ('22222222-2222-2222-2222-222222222222', 'Very clean');

-- Question 3: Sleep Schedule
INSERT INTO question_options (question_id, options) VALUES
  ('33333333-3333-3333-3333-333333333333', 'Early bird (sleep before 10 PM)'),
  ('33333333-3333-3333-3333-333333333333', 'Normal (10 PM - 12 AM)'),
  ('33333333-3333-3333-3333-333333333333', 'Night owl (after 12 AM)'),
  ('33333333-3333-3333-3333-333333333333', 'Irregular/Flexible');

-- Question 4: Social
INSERT INTO question_options (question_id, options) VALUES
  ('44444444-4444-4444-4444-444444444444', 'Very introverted'),
  ('44444444-4444-4444-4444-444444444444', 'Somewhat introverted'),
  ('44444444-4444-4444-4444-444444444444', 'Balanced'),
  ('44444444-4444-4444-4444-444444444444', 'Somewhat social'),
  ('44444444-4444-4444-4444-444444444444', 'Very social');

-- Question 5: Habits
INSERT INTO question_options (question_id, options) VALUES
  ('55555555-5555-5555-5555-555555555555', 'Neither'),
  ('55555555-5555-5555-5555-555555555555', 'Drink occasionally'),
  ('55555555-5555-5555-5555-555555555555', 'Smoke occasionally'),
  ('55555555-5555-5555-5555-555555555555', 'Both occasionally'),
  ('55555555-5555-5555-5555-555555555555', 'Regularly');

-- Question 6: Guests
INSERT INTO question_options (question_id, options) VALUES
  ('66666666-6666-6666-6666-666666666666', 'Never'),
  ('66666666-6666-6666-6666-666666666666', 'Rarely'),
  ('66666666-6666-6666-6666-666666666666', 'Sometimes'),
  ('66666666-6666-6666-6666-666666666666', 'Often'),
  ('66666666-6666-6666-6666-666666666666', 'Very often');

-- Question 7: Study Habits
INSERT INTO question_options (question_id, options) VALUES
  ('77777777-7777-7777-7777-777777777777', 'Study at home quietly'),
  ('77777777-7777-7777-7777-777777777777', 'Study at home with music'),
  ('77777777-7777-7777-7777-777777777777', 'Study at library'),
  ('77777777-7777-7777-7777-777777777777', 'Study in groups'),
  ('77777777-7777-7777-7777-777777777777', 'Flexible');

-- Question 9: Hobbies
INSERT INTO question_options (question_id, options) VALUES
  ('99999999-9999-9999-9999-999999999999', 'Gaming'),
  ('99999999-9999-9999-9999-999999999999', 'Sports'),
  ('99999999-9999-9999-9999-999999999999', 'Reading'),
  ('99999999-9999-9999-9999-999999999999', 'Movies/TV'),
  ('99999999-9999-9999-9999-999999999999', 'Cooking'),
  ('99999999-9999-9999-9999-999999999999', 'Music'),
  ('99999999-9999-9999-9999-999999999999', 'Art'),
  ('99999999-9999-9999-9999-999999999999', 'Travel');

-- Question 10: Friendship
INSERT INTO question_options (question_id, options) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Not important - just respectful'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Somewhat important'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Important'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Very important - want to be close friends');

-- Question 11: Apartment Status
INSERT INTO question_options (question_id, options) VALUES
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Yes'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'No');
