-- Demo data for app-store reviewers (Google Play "App access").
-- See docs/BETA.md, "Reviewer access".
--
--   docker compose exec -T postgres psql -U campus -d campus < review-seed.sql
--
-- Creates the hidden demo university (never listed to other students), the
-- reviewer account, a class group with a Sunday-Thursday routine, a class
-- test, an assignment, announcements and a few Campus Voice issues.
-- Safe to re-run: accounts and the group are kept, while the routine, tests,
-- announcements and Voice issues are rebuilt (dates move forward with now()).
-- Remove everything with review-unseed.sql.
--
-- Needs migration 00580 (universities.is_demo). The reviewer can only sign in
-- when the server runs with REVIEW_EMAIL / REVIEW_CODE set to match.

\set ON_ERROR_STOP on

BEGIN;

DO $seed$
DECLARE
    v_uni        uuid;
    v_reviewer   uuid;
    v_cr         uuid;
    v_student    uuid;
    v_group      uuid;
    v_today      date := (now() AT TIME ZONE 'Asia/Dhaka')::date;
    v_test_day   date;
    v_due_day    date;
    v_issue      uuid;
BEGIN
    -- ---- university ---------------------------------------------------------
    INSERT INTO universities (slug, name, name_bn, city, is_active, is_demo)
    VALUES ('demo-review', 'VarsityKotha Demo University', 'ভার্সিটিকথা ডেমো বিশ্ববিদ্যালয়', 'Dhaka', true, true)
    ON CONFLICT (slug) DO UPDATE SET is_active = true, is_demo = true
    RETURNING id INTO v_uni;

    INSERT INTO university_domains (domain, university_id)
    VALUES ('review.varsitykotha.com', v_uni)
    ON CONFLICT (domain) DO UPDATE SET university_id = EXCLUDED.university_id;

    -- ---- people -------------------------------------------------------------
    INSERT INTO users (email, university_id, university_email, display_name, department, batch, role, verified_at)
    VALUES ('play-review@review.varsitykotha.com', v_uni, 'play-review@review.varsitykotha.com',
            'Play Reviewer', 'CSE', '61', 'student', now())
    ON CONFLICT (email) DO UPDATE SET
        university_id = EXCLUDED.university_id, university_email = EXCLUDED.university_email,
        display_name = EXCLUDED.display_name, department = EXCLUDED.department, batch = EXCLUDED.batch,
        role = 'student', blocked_at = NULL, verified_at = coalesce(users.verified_at, now())
    RETURNING id INTO v_reviewer;

    INSERT INTO users (email, university_id, university_email, display_name, department, batch, role, verified_at)
    VALUES ('demo-cr@review.varsitykotha.com', v_uni, 'demo-cr@review.varsitykotha.com',
            'Tanvir Ahmed', 'CSE', '61', 'student', now())
    ON CONFLICT (email) DO UPDATE SET
        university_id = EXCLUDED.university_id, university_email = EXCLUDED.university_email,
        display_name = EXCLUDED.display_name, department = EXCLUDED.department, batch = EXCLUDED.batch,
        verified_at = coalesce(users.verified_at, now())
    RETURNING id INTO v_cr;

    INSERT INTO users (email, university_id, university_email, display_name, department, batch, role, verified_at)
    VALUES ('demo-student@review.varsitykotha.com', v_uni, 'demo-student@review.varsitykotha.com',
            'Nusrat Jahan', 'CSE', '61', 'student', now())
    ON CONFLICT (email) DO UPDATE SET
        university_id = EXCLUDED.university_id, university_email = EXCLUDED.university_email,
        display_name = EXCLUDED.display_name, department = EXCLUDED.department, batch = EXCLUDED.batch,
        verified_at = coalesce(users.verified_at, now())
    RETURNING id INTO v_student;

    -- ---- class group --------------------------------------------------------
    SELECT id INTO v_group FROM class_groups WHERE university_id = v_uni AND join_code = 'DEMXRV';
    IF v_group IS NULL THEN
        INSERT INTO class_groups (university_id, department, batch, section, semester, join_code, created_by, discoverable)
        VALUES (v_uni, 'CSE', '61', 'A', 'Fall 2026', 'DEMXRV', v_cr, true)
        RETURNING id INTO v_group;
    ELSE
        UPDATE class_groups SET semester = 'Fall 2026', created_by = v_cr WHERE id = v_group;
    END IF;

    INSERT INTO class_group_members (group_id, user_id, role) VALUES
        (v_group, v_cr,       'cr'),
        (v_group, v_reviewer, 'member'),
        (v_group, v_student,  'member')
    ON CONFLICT (group_id, user_id) DO UPDATE SET role = EXCLUDED.role;

    -- ---- routine: Sunday (7) to Thursday (4) ---------------------------------
    DELETE FROM routine_slots WHERE group_id = v_group;
    INSERT INTO routine_slots (group_id, course_code, course_title, teacher, room, weekday, starts_min, ends_min, kind)
    VALUES
        -- CSE 311 Database Systems: Sun, Tue theory; Thu lab
        (v_group, 'CSE 311', 'Database Systems',      'Dr. Farhana Karim', 'AB4-702', 7,  540,  630, 'theory'),
        (v_group, 'CSE 311', 'Database Systems',      'Dr. Farhana Karim', 'AB4-702', 2,  540,  630, 'theory'),
        (v_group, 'CSE 311', 'Database Systems Lab',  'Dr. Farhana Karim', 'AB4-LAB3', 4, 840,  990, 'lab'),
        -- CSE 313 Computer Networks: Sun, Tue
        (v_group, 'CSE 313', 'Computer Networks',     'Md. Rafiqul Islam', 'AB4-704', 7,  660,  750, 'theory'),
        (v_group, 'CSE 313', 'Computer Networks',     'Md. Rafiqul Islam', 'AB4-704', 2,  660,  750, 'theory'),
        -- CSE 315 Software Engineering: Mon, Wed
        (v_group, 'CSE 315', 'Software Engineering',  'Sabrina Haque',     'AB4-702', 1,  540,  630, 'theory'),
        (v_group, 'CSE 315', 'Software Engineering',  'Sabrina Haque',     'AB4-702', 3,  540,  630, 'theory'),
        -- MAT 211 Linear Algebra: Mon, Wed
        (v_group, 'MAT 211', 'Linear Algebra',        'Dr. Anwar Hossain', 'AB2-401', 1,  660,  750, 'theory'),
        (v_group, 'MAT 211', 'Linear Algebra',        'Dr. Anwar Hossain', 'AB2-401', 3,  660,  750, 'theory'),
        -- ENG 101 Communicative English: Tue afternoon, Thu morning
        (v_group, 'ENG 101', 'Communicative English', 'Tahmina Akter',     'AB3-305', 2,  840,  930, 'theory'),
        (v_group, 'ENG 101', 'Communicative English', 'Tahmina Akter',     'AB3-305', 4,  540,  630, 'theory');

    -- ---- class test and assignment (always upcoming, never Fri/Sat) -----------
    v_test_day := v_today + 3;
    WHILE extract(isodow FROM v_test_day) IN (5, 6) LOOP v_test_day := v_test_day + 1; END LOOP;
    v_due_day := v_today + 7;
    WHILE extract(isodow FROM v_due_day) IN (5, 6) LOOP v_due_day := v_due_day + 1; END LOOP;

    DELETE FROM assessments WHERE group_id = v_group;
    INSERT INTO assessments (group_id, kind, course_code, course_title, date, starts_min, ends_min, room, topics, created_by)
    VALUES
        (v_group, 'class_test', 'CSE 311', 'Database Systems', v_test_day, 540, 590, 'AB4-702',
         'ER diagrams, relational algebra, SQL joins and normalization up to BCNF.', v_cr),
        (v_group, 'assignment', 'CSE 315', 'Software Engineering', v_due_day, 1020, NULL, '',
         'Submit the SRS document for your term project (PDF, max 15 pages) to the course email.', v_cr);

    -- ---- announcements ------------------------------------------------------
    DELETE FROM announcements WHERE group_id = v_group;
    INSERT INTO announcements (group_id, body, pinned, created_by, created_at)
    VALUES
        (v_group, 'Welcome to CSE 61 (Section A). Join your course groups and keep this app open for routine changes and class test dates.',
         true, v_cr, now() - interval '5 days'),
        (v_group, 'The Database Systems lab this Thursday will start at 2:00 PM sharp in AB4-LAB3. Please bring your lab manual.',
         false, v_cr, now() - interval '1 day');

    -- ---- Campus Voice (no photos) -------------------------------------------
    DELETE FROM issues WHERE university_id = v_uni;

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'facilities', false, 'Fans not working in AB4-702',
            'Three of the ceiling fans in AB4-702 have been broken for two weeks. It gets very hot during the 11 AM class and it is hard to concentrate.',
            'AB4, room 702', 'acknowledged', 2, 2, now() - interval '4 days', now() - interval '2 days')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_student);
    INSERT INTO issue_votes (issue_id, user_id, created_at) VALUES (v_issue, v_cr, now() - interval '3 days'), (v_issue, v_reviewer, now() - interval '2 days');
    INSERT INTO status_updates (issue_id, actor_kind, actor_title, from_status, to_status, note, created_at)
    VALUES (v_issue, 'moderator', '', 'open', 'acknowledged', 'Forwarded to the maintenance office.', now() - interval '2 days');
    INSERT INTO comments (issue_id, kind, handle, body, created_at) VALUES
        (v_issue, 'student', 'K7QM', 'Same problem in AB4-704. The fans there are very slow too.', now() - interval '3 days'),
        (v_issue, 'student', 'T4XH', 'Thanks for raising this. It is really hard to sit through the afternoon classes.', now() - interval '2 days');

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'transport', false, 'More buses needed after 5 PM',
            'After 5 PM there are only two buses to the Mirpur route and they are always full. Many of us wait more than an hour to get home.',
            'Main gate', 'open', 2, 1, now() - interval '3 days', now() - interval '3 days')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_cr);
    INSERT INTO issue_votes (issue_id, user_id, created_at) VALUES (v_issue, v_student, now() - interval '3 days'), (v_issue, v_reviewer, now() - interval '1 day');
    INSERT INTO comments (issue_id, kind, handle, body, created_at) VALUES
        (v_issue, 'student', 'M9RB', 'The Uttara route has the same issue after the evening classes.', now() - interval '2 days');

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'food', false, 'Cafeteria prices went up again',
            'Prices at the central cafeteria increased this month without any notice. A plate of rice with chicken is now much more expensive than before.',
            'Central cafeteria', 'open', 1, 0, now() - interval '2 days', now() - interval '2 days')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_student);
    INSERT INTO issue_votes (issue_id, user_id, created_at) VALUES (v_issue, v_cr, now() - interval '1 day');

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at, solved_at)
    VALUES (v_uni, 'it', false, 'Campus Wi-Fi was down in the library',
            'The library Wi-Fi was not working all of last week, so we could not access online journals. It works again since yesterday, thank you.',
            'Central library', 'solved', 1, 0, now() - interval '9 days', now() - interval '1 day', now() - interval '1 day')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_cr);
    INSERT INTO issue_votes (issue_id, user_id, created_at) VALUES (v_issue, v_student, now() - interval '8 days');
    INSERT INTO status_updates (issue_id, actor_kind, actor_title, from_status, to_status, note, created_at)
    VALUES (v_issue, 'moderator', '', 'open', 'solved', 'The IT office fixed the access point.', now() - interval '1 day');
END
$seed$;

COMMIT;

-- Check: what was created.
SELECT u.slug, u.is_demo,
       (SELECT count(*) FROM users x WHERE x.university_id = u.id) AS users,
       (SELECT count(*) FROM class_groups g WHERE g.university_id = u.id) AS groups,
       (SELECT count(*) FROM routine_slots s JOIN class_groups g ON g.id = s.group_id WHERE g.university_id = u.id) AS slots,
       (SELECT count(*) FROM issues i WHERE i.university_id = u.id) AS issues
FROM universities u WHERE u.slug = 'demo-review';
