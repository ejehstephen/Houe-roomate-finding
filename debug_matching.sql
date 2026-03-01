-- ============================================================
-- MATCHING DIAGNOSTIC SCRIPT
-- Run in Supabase SQL Editor > New Query
-- This will show you EXACTLY why matches are empty
-- ============================================================

-- 1. See the REAL question IDs in your database
SELECT id, question, type
FROM questionnaire_questions;

-- 2. See YOUR answers (run as your user via Supabase Auth > set user token, or just see all)
SELECT 
  qa.question_id,
  qq.question,
  qa.text,
  av.answers
FROM questionnaire_answers qa
LEFT JOIN questionnaire_questions qq ON qq.id = qa.question_id
LEFT JOIN answer_values av ON av.answer_id = qa.id
ORDER BY qa.question_id;

-- 3. See how many people there are per school+gender combo
SELECT gender, school, COUNT(*) as user_count
FROM users
WHERE is_banned = false
GROUP BY gender, school
ORDER BY user_count DESC;

-- 4. Call the function directly (run as yourself)
SELECT * FROM get_roommate_matches();
