-- =============================================================
-- get_roommate_matches: SELF-HEALING version
-- Uses the actual question text to find question IDs dynamically
-- No more hardcoded UUIDs!
-- Run this SQL in the Supabase SQL Editor
-- =============================================================

CREATE OR REPLACE FUNCTION get_roommate_matches()
RETURNS TABLE (
  id TEXT,
  name TEXT,
  age INT,
  gender TEXT,
  school TEXT,
  "profileImage" TEXT,
  "phoneNumber" TEXT,
  "compatibilityScore" INT,
  "commonInterests" JSONB,
  budget FLOAT,
  preferences JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_gender TEXT;
  v_school TEXT;
  v_my_apartment TEXT;
  v_my_cleanliness TEXT;
  v_my_habits TEXT;
  -- Dynamically resolved question IDs
  v_cleanliness_qid UUID;
  v_habits_qid UUID;
  v_apartment_qid UUID;
  v_lifestyle_qids UUID[];
BEGIN
  -- 1. Get current user's profile
  SELECT u.gender, u.school
  INTO v_gender, v_school
  FROM users u
  WHERE u.id = v_user_id;

  IF v_gender IS NULL THEN
    RETURN; -- No profile found
  END IF;

  -- 2. Resolve question IDs dynamically by question text keywords
  SELECT qq.id INTO v_cleanliness_qid
  FROM questionnaire_questions qq
  WHERE LOWER(qq.question) ILIKE '%clean%'
  LIMIT 1;

  SELECT qq.id INTO v_habits_qid
  FROM questionnaire_questions qq
  WHERE LOWER(qq.question) ILIKE '%smok%' OR LOWER(qq.question) ILIKE '%habit%' OR LOWER(qq.question) ILIKE '%drink%'
  LIMIT 1;

  SELECT qq.id INTO v_apartment_qid
  FROM questionnaire_questions qq
  WHERE LOWER(qq.question) ILIKE '%apartment%' OR LOWER(qq.question) ILIKE '%have a place%' OR LOWER(qq.question) ILIKE '%own place%' OR LOWER(qq.question) ILIKE '%already have%'
  LIMIT 1;

  -- Lifestyle/interest question IDs (all questions EXCEPT cleanliness, habits, apartment)
  SELECT ARRAY_AGG(qq.id) INTO v_lifestyle_qids
  FROM questionnaire_questions qq
  WHERE qq.id NOT IN (
    COALESCE(v_cleanliness_qid, gen_random_uuid()),
    COALESCE(v_habits_qid, gen_random_uuid()),
    COALESCE(v_apartment_qid, gen_random_uuid())
  );

  -- 3. Get current user's key answers
  IF v_cleanliness_qid IS NOT NULL THEN
    SELECT COALESCE(
      (SELECT av.answers FROM questionnaire_answers qa
       JOIN answer_values av ON av.answer_id = qa.id
       WHERE qa.user_id = v_user_id AND qa.question_id = v_cleanliness_qid LIMIT 1),
      (SELECT qa.text FROM questionnaire_answers qa
       WHERE qa.user_id = v_user_id AND qa.question_id = v_cleanliness_qid LIMIT 1)
    ) INTO v_my_cleanliness;
  END IF;

  IF v_habits_qid IS NOT NULL THEN
    SELECT COALESCE(
      (SELECT av.answers FROM questionnaire_answers qa
       JOIN answer_values av ON av.answer_id = qa.id
       WHERE qa.user_id = v_user_id AND qa.question_id = v_habits_qid LIMIT 1),
      (SELECT qa.text FROM questionnaire_answers qa
       WHERE qa.user_id = v_user_id AND qa.question_id = v_habits_qid LIMIT 1)
    ) INTO v_my_habits;
  END IF;

  IF v_apartment_qid IS NOT NULL THEN
    SELECT COALESCE(
      (SELECT av.answers FROM questionnaire_answers qa
       JOIN answer_values av ON av.answer_id = qa.id
       WHERE qa.user_id = v_user_id AND qa.question_id = v_apartment_qid LIMIT 1),
      (SELECT qa.text FROM questionnaire_answers qa
       WHERE qa.user_id = v_user_id AND qa.question_id = v_apartment_qid LIMIT 1)
    ) INTO v_my_apartment;
  END IF;

  -- 4. Return scored matches
  RETURN QUERY
  WITH my_interest_answers AS (
    SELECT qa.question_id, av.answers AS answer_text
    FROM questionnaire_answers qa
    JOIN answer_values av ON av.answer_id = qa.id
    WHERE qa.user_id = v_user_id
      AND (v_lifestyle_qids IS NULL OR qa.question_id = ANY(v_lifestyle_qids))
  ),
  candidates AS (
    SELECT c.*
    FROM users c
    WHERE c.id != v_user_id
      AND LOWER(c.gender) = LOWER(v_gender)
      AND LOWER(c.school) = LOWER(v_school)
      AND c.is_banned = false
  ),
  candidate_apartment AS (
    SELECT qa.user_id,
           COALESCE(
             (SELECT av2.answers FROM answer_values av2 WHERE av2.answer_id = qa.id LIMIT 1),
             qa.text
           ) AS apt_answer
    FROM questionnaire_answers qa
    WHERE v_apartment_qid IS NOT NULL AND qa.question_id = v_apartment_qid
  ),
  candidate_cleanliness AS (
    SELECT qa.user_id,
           COALESCE(
             (SELECT av2.answers FROM answer_values av2 WHERE av2.answer_id = qa.id LIMIT 1),
             qa.text
           ) AS clean_answer
    FROM questionnaire_answers qa
    WHERE v_cleanliness_qid IS NOT NULL AND qa.question_id = v_cleanliness_qid
  ),
  candidate_habits AS (
    SELECT qa.user_id,
           COALESCE(
             (SELECT av2.answers FROM answer_values av2 WHERE av2.answer_id = qa.id LIMIT 1),
             qa.text
           ) AS habit_answer
    FROM questionnaire_answers qa
    WHERE v_habits_qid IS NOT NULL AND qa.question_id = v_habits_qid
  ),
  candidate_interest_answers AS (
    SELECT qa.user_id, qa.question_id, av.answers AS answer_text
    FROM questionnaire_answers qa
    JOIN answer_values av ON av.answer_id = qa.id
    WHERE v_lifestyle_qids IS NULL OR qa.question_id = ANY(v_lifestyle_qids)
  ),
  interest_overlap AS (
    SELECT cia.user_id,
           COUNT(*) AS overlap_count
    FROM candidate_interest_answers cia
    INNER JOIN my_interest_answers ma
      ON cia.question_id = ma.question_id
      AND cia.answer_text = ma.answer_text
    GROUP BY cia.user_id
  ),
  my_answer_count AS (
    SELECT COUNT(*) AS total FROM my_interest_answers
  ),
  common_interests_agg AS (
    SELECT cia.user_id,
           jsonb_agg(DISTINCT cia.answer_text) AS interests
    FROM candidate_interest_answers cia
    INNER JOIN my_interest_answers ma
      ON cia.question_id = ma.question_id
      AND cia.answer_text = ma.answer_text
    GROUP BY cia.user_id
  ),
  scored AS (
    SELECT
      cand.id::TEXT AS match_id,
      cand.name::TEXT AS match_name,
      cand.age AS match_age,
      cand.gender::TEXT AS match_gender,
      cand.school::TEXT AS match_school,
      COALESCE(cand.profile_image, '')::TEXT AS match_profile_image,
      cand.phone_number::TEXT AS match_phone_number,

      -- Cleanliness score (35%) - neutral 50 if not answered
      CASE
        WHEN v_my_cleanliness IS NULL OR cc.clean_answer IS NULL THEN 50
        ELSE GREATEST(0, 100 - 25 * ABS(
          (CASE v_my_cleanliness
            WHEN 'Very messy' THEN 1 WHEN 'Somewhat messy' THEN 2
            WHEN 'Average' THEN 3 WHEN 'Clean' THEN 4 WHEN 'Very clean' THEN 5 ELSE 3 END)
          -
          (CASE cc.clean_answer
            WHEN 'Very messy' THEN 1 WHEN 'Somewhat messy' THEN 2
            WHEN 'Average' THEN 3 WHEN 'Clean' THEN 4 WHEN 'Very clean' THEN 5 ELSE 3 END)
        ))
      END AS cleanliness_score,

      -- Habits score (35%) - neutral 50 if not answered
      CASE
        WHEN v_my_habits IS NULL OR ch.habit_answer IS NULL THEN 50
        WHEN v_my_habits = ch.habit_answer THEN 100
        WHEN v_my_habits = 'Neither' AND ch.habit_answer = 'Regularly' THEN 0
        WHEN v_my_habits = 'Neither' AND ch.habit_answer ILIKE '%occasionally%' THEN 40
        WHEN v_my_habits = 'Regularly' AND ch.habit_answer = 'Neither' THEN 20
        WHEN v_my_habits = 'Regularly' AND ch.habit_answer ILIKE '%occasionally%' THEN 80
        WHEN v_my_habits ILIKE '%occasionally%' AND ch.habit_answer ILIKE '%occasionally%' THEN 90
        ELSE 50
      END AS habits_score,

      -- Interest score (30%)
      CASE
        WHEN mac.total = 0 OR mac.total IS NULL THEN 0
        ELSE LEAST(100, ROUND((COALESCE(io.overlap_count, 0)::NUMERIC / mac.total) * 200))
      END AS interest_score,

      COALESCE(cia_agg.interests, '[]'::jsonb) AS common_interests

    FROM candidates cand
    LEFT JOIN candidate_apartment ca ON ca.user_id = cand.id
    LEFT JOIN candidate_cleanliness cc ON cc.user_id = cand.id
    LEFT JOIN candidate_habits ch ON ch.user_id = cand.id
    LEFT JOIN interest_overlap io ON io.user_id = cand.id
    LEFT JOIN common_interests_agg cia_agg ON cia_agg.user_id = cand.id
    CROSS JOIN my_answer_count mac
    WHERE
      -- APARTMENT RULE (NULL-safe): if either party hasn't answered, still show match
      (
        v_my_apartment IS NULL
        OR ca.apt_answer IS NULL
        OR (v_my_apartment = 'Yes' AND ca.apt_answer = 'No')
        OR (v_my_apartment = 'No'  AND ca.apt_answer IN ('Yes', 'No'))
      )
  )
  SELECT
    s.match_id,
    s.match_name,
    s.match_age,
    s.match_gender,
    s.match_school,
    s.match_profile_image,
    s.match_phone_number,
    ROUND(
      (s.cleanliness_score * 0.35) +
      (s.habits_score * 0.35) +
      (s.interest_score * 0.30)
    )::INT AS compat_score,
    s.common_interests,
    0.0::FLOAT AS budget_val,
    '[]'::JSONB AS prefs
  FROM scored s
  ORDER BY compat_score DESC
  LIMIT 50;
END;
$$;
