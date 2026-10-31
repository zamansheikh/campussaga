-- Demo content for one local account, to see every screen filled in on an
-- emulator: a class group (the account is its CR) with a Saturday-Thursday
-- routine, today's changes, tests and deadlines, announcements, Campus
-- Voice issues and three bus routes at the account's university.
--
--   psql "$DEVDB" -v email=you@example.com -f seed/demo.sql
--
-- Local development only (never the live server). Safe to re-run: the demo
-- people and group are kept, everything else is rebuilt around today.
-- Driver phone numbers use the unused 010 prefix, so they can't ring anyone.
\set ON_ERROR_STOP on
BEGIN;
SELECT set_config('demo.email', :'email', true);

DO $seed$
DECLARE
    v_me     uuid;
    v_uni    uuid;
    v_cr2    uuid;
    v_a      uuid;
    v_b      uuid;
    v_c      uuid;
    v_group  uuid;
    v_today  date := (now() AT TIME ZONE 'Asia/Dhaka')::date;
    v_dow    int  := extract(isodow FROM (now() AT TIME ZONE 'Asia/Dhaka'))::int;
    v_slot   uuid;
    v_issue  uuid;
    v_cmt    uuid;
    v_opt    uuid;
    v_route  uuid;
    v_domain text;
BEGIN
    SELECT id, university_id INTO v_me, v_uni FROM users WHERE email = current_setting('demo.email');
    IF v_me IS NULL THEN RAISE EXCEPTION 'no account with email %', current_setting('demo.email'); END IF;
    IF v_uni IS NULL THEN RAISE EXCEPTION 'pick a university in the app first'; END IF;
    SELECT domain INTO v_domain FROM university_domains WHERE university_id = v_uni ORDER BY domain LIMIT 1;
    v_domain := coalesce(v_domain, 'demo.local');

    -- ---- demo classmates ----------------------------------------------------
    INSERT INTO users (email, university_id, university_email, display_name, department, batch, role, verified_at)
    VALUES ('demo-tanvir@' || v_domain, v_uni, 'demo-tanvir@' || v_domain, 'Tanvir Ahmed', 'CS', '40', 'student', now())
    ON CONFLICT (email) DO UPDATE SET university_id = EXCLUDED.university_id RETURNING id INTO v_cr2;
    INSERT INTO users (email, university_id, university_email, display_name, department, batch, role, verified_at)
    VALUES ('demo-nusrat@' || v_domain, v_uni, 'demo-nusrat@' || v_domain, 'Nusrat Jahan', 'CS', '40', 'student', now())
    ON CONFLICT (email) DO UPDATE SET university_id = EXCLUDED.university_id RETURNING id INTO v_a;
    INSERT INTO users (email, university_id, display_name, department, batch, role)
    VALUES ('demo-rafi@gmail.com', v_uni, 'Rafiul Islam', 'CS', '40', 'student')
    ON CONFLICT (email) DO UPDATE SET university_id = EXCLUDED.university_id RETURNING id INTO v_b;
    INSERT INTO users (email, university_id, university_email, display_name, department, batch, role, verified_at)
    VALUES ('demo-sadia@' || v_domain, v_uni, 'demo-sadia@' || v_domain, 'Sadia Rahman', 'CS', '40', 'student', now())
    ON CONFLICT (email) DO UPDATE SET university_id = EXCLUDED.university_id RETURNING id INTO v_c;

    -- ---- class group (you are its CR) ----------------------------------------
    SELECT id INTO v_group FROM class_groups WHERE join_code = 'DEMJUA';
    IF v_group IS NULL THEN
        INSERT INTO class_groups (university_id, department, batch, section, semester, join_code, created_by, discoverable)
        VALUES (v_uni, 'CS', '40', 'A', 'Fall 2026', 'DEMJUA', v_me, true) RETURNING id INTO v_group;
    ELSE
        UPDATE class_groups SET university_id = v_uni, created_by = v_me WHERE id = v_group;
    END IF;
    INSERT INTO class_group_members (group_id, user_id, role) VALUES
        (v_group, v_me, 'cr'), (v_group, v_cr2, 'cr'), (v_group, v_a, 'member'), (v_group, v_b, 'member'), (v_group, v_c, 'member')
    ON CONFLICT (group_id, user_id) DO UPDATE SET role = EXCLUDED.role;

    -- ---- routine: Saturday (6) to Thursday (4) --------------------------------
    DELETE FROM routine_slots WHERE group_id = v_group;
    INSERT INTO routine_slots (group_id, course_code, course_title, teacher, room, weekday, starts_min, ends_min, kind) VALUES
        (v_group, 'CSE 311', 'Database Systems',           'Prof. Dr. Liton Jude Rozario', 'CSE 202', 6,  540,  630, 'theory'),
        (v_group, 'CSE 313', 'Computer Networks',          'Dr. Md. Musfique Anwar',       'CSE 203', 6,  660,  750, 'theory'),
        (v_group, 'CSE 311', 'Database Systems Lab',       'Samih Raihan',                 'Lab 2',   6,  840,  990, 'lab'),
        (v_group, 'CSE 315', 'Software Engineering',       'Shibli Mahmood',               'CSE 101', 6, 1000, 1090, 'theory'),
        (v_group, 'MAT 211', 'Linear Algebra',             'Dr. Anwar Hossain',            'Math 301', 7, 540,  630, 'theory'),
        (v_group, 'CSE 313', 'Computer Networks',          'Dr. Md. Musfique Anwar',       'CSE 203', 7,  660,  750, 'theory'),
        (v_group, 'ENG 101', 'Communicative English',      'Tahmina Akter',                'Arts 105', 7, 840,  930, 'theory'),
        (v_group, 'CSE 315', 'Software Engineering',       'Shibli Mahmood',               'CSE 101', 1,  540,  630, 'theory'),
        (v_group, 'CSE 317', 'Artificial Intelligence',    'Prof. Dr. Md. Humayun Kabir',  'CSE 102', 1,  660,  750, 'theory'),
        (v_group, 'CSE 313', 'Computer Networks Lab',      'Md. Rafiqul Islam',            'Lab 3',   1,  840,  990, 'lab'),
        (v_group, 'CSE 311', 'Database Systems',           'Prof. Dr. Liton Jude Rozario', 'CSE 202', 2,  540,  630, 'theory'),
        (v_group, 'MAT 211', 'Linear Algebra',             'Dr. Anwar Hossain',            'Math 301', 2, 660,  750, 'theory'),
        (v_group, 'CSE 317', 'Artificial Intelligence',    'Prof. Dr. Md. Humayun Kabir',  'CSE 102', 3,  540,  630, 'theory'),
        (v_group, 'CSE 317', 'Artificial Intelligence Lab','Safianna Sharmin',             'Lab 1',   3,  840,  990, 'lab'),
        (v_group, 'ENG 101', 'Communicative English',      'Tahmina Akter',                'Arts 105', 4, 540,  630, 'theory'),
        (v_group, 'CSE 315', 'Software Engineering',       'Shibli Mahmood',               'CSE 101', 4,  660,  750, 'theory');

    -- ---- today's changes and an extra class tomorrow ----------------------------
    DELETE FROM routine_changes WHERE group_id = v_group;
    SELECT id INTO v_slot FROM routine_slots WHERE group_id = v_group AND weekday = v_dow ORDER BY starts_min OFFSET 1 LIMIT 1;
    IF v_slot IS NOT NULL THEN
        INSERT INTO routine_changes (group_id, slot_id, date, kind, note, created_by)
        VALUES (v_group, v_slot, v_today, 'cancelled', 'Sir is at a seminar today. The class will be made up next week.', v_me);
    END IF;
    SELECT id INTO v_slot FROM routine_slots WHERE group_id = v_group AND weekday = v_dow ORDER BY starts_min OFFSET 2 LIMIT 1;
    IF v_slot IS NOT NULL THEN
        INSERT INTO routine_changes (group_id, slot_id, date, kind, room, starts_min, ends_min, note, created_by)
        SELECT v_group, id, v_today, 'moved', 'Lab 5', starts_min, ends_min, 'Lab 2 projector is broken.', v_me
        FROM routine_slots WHERE id = v_slot;
    END IF;
    INSERT INTO routine_changes (group_id, slot_id, date, kind, course_code, course_title, teacher, class_kind, room, starts_min, ends_min, note, created_by)
    VALUES (v_group, NULL, v_today + 1, 'extra', 'CSE 313', 'Computer Networks (make-up)', 'Dr. Md. Musfique Anwar', 'theory',
            'CSE 203', 960, 1050, 'Make-up for the class missed last week.', v_me);

    -- ---- tests and deadlines -------------------------------------------------
    DELETE FROM assessments WHERE group_id = v_group;
    INSERT INTO assessments (group_id, kind, course_code, course_title, date, starts_min, ends_min, room, topics, created_by) VALUES
        (v_group, 'quiz',       'CSE 313', 'Computer Networks',       v_today + 1, 660, 690, 'CSE 203', 'TCP/IP model, subnetting and routing basics (chapters 1-3).', v_me),
        (v_group, 'assignment', 'CSE 315', 'Software Engineering',    v_today + 3, 1439, NULL, '', 'Submit the SRS for your term project as a PDF (max 15 pages).', v_me),
        (v_group, 'midterm',    'CSE 311', 'Database Systems',        v_today + 6, 600, 720, 'Exam Hall 2', 'ER model, relational algebra, SQL, normalization up to BCNF.', v_me),
        (v_group, 'lab_report', 'CSE 317', 'Artificial Intelligence', v_today + 4, 1020, NULL, 'Lab 1', 'A* search lab report with code and screenshots.', v_me);

    -- ---- announcements ------------------------------------------------------
    DELETE FROM announcements WHERE group_id = v_group;
    INSERT INTO announcements (group_id, body, pinned, created_by, created_at) VALUES
        (v_group, 'Welcome to CS 40 (Section A). All routine changes and test dates will be posted here, so please keep notifications on.', true, v_me, now() - interval '6 days'),
        (v_group, 'Mid-term exams start next week. The full schedule is in Tests & deadlines.', false, v_cr2, now() - interval '1 day'),
        (v_group, 'Today''s Database lab is moved to Lab 5: the projector in Lab 2 is broken.', false, v_me, now() - interval '2 hours');

    -- ---- Campus Voice ---------------------------------------------------------
    DELETE FROM issues WHERE university_id = v_uni AND id IN (SELECT issue_id FROM issue_authors WHERE user_id IN (v_me, v_cr2, v_a, v_b, v_c));

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'hostel', false, 'No water on the 3rd floor of the hall since Sunday',
            'The taps on the 3rd floor have been dry since Sunday morning. We carry water up from the ground floor before every class and it is getting really hard.',
            'Hall 2, 3rd floor', 'in_progress', 148, 3, now() - interval '5 days', now() - interval '1 day')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_a);
    INSERT INTO issue_votes (issue_id, user_id) VALUES (v_issue, v_me), (v_issue, v_b), (v_issue, v_c);
    INSERT INTO issue_follows (issue_id, user_id) VALUES (v_issue, v_me);
    INSERT INTO status_updates (issue_id, actor_kind, actor_title, from_status, to_status, note, created_at) VALUES
        (v_issue, 'authority', 'Hall Provost', 'open', 'acknowledged', 'We know about it and the plumber has been called.', now() - interval '3 days'),
        (v_issue, 'authority', 'Hall Provost', 'acknowledged', 'in_progress', 'A new pump is ordered. Water tankers come at 7 AM and 6 PM until then.', now() - interval '1 day');
    INSERT INTO comments (issue_id, kind, handle, body, created_at) VALUES
        (v_issue, 'student', 'B2XZ', 'Same on the 2nd floor. We fill buckets from the ground floor.', now() - interval '4 days');
    INSERT INTO comments (issue_id, kind, official_title, body, created_at) VALUES
        (v_issue, 'official', 'Hall Provost', 'The new pump arrives on Thursday. Tankers will keep coming twice a day until it is fitted.', now() - interval '20 hours');
    INSERT INTO comments (issue_id, kind, handle, body, created_at) VALUES
        (v_issue, 'student', 'K7QM', 'Thank you! The evening tanker came on time today.', now() - interval '3 hours');

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'transport', false, 'Bus leaves Mirpur 10 minutes early every morning',
            'The 7:30 bus leaves at 7:20, so students who come on time miss it and are late for the 8:30 class. Please make it leave on time.',
            'Mirpur 10 stop', 'open', 61, 1, now() - interval '2 days', now() - interval '2 days')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_me);
    INSERT INTO issue_votes (issue_id, user_id) VALUES (v_issue, v_a), (v_issue, v_c);
    INSERT INTO comments (issue_id, kind, handle, body, created_at) VALUES
        (v_issue, 'student', 'M9RB', 'Happened to me twice this week too.', now() - interval '1 day');

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'it', false, 'Wi-Fi drops in the library every afternoon',
            'From around 2 PM the library Wi-Fi keeps disconnecting, so we cannot open journals or submit assignments online.',
            'Central library', 'acknowledged', 37, 0, now() - interval '3 days', now() - interval '2 days')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_b);
    INSERT INTO status_updates (issue_id, actor_kind, actor_title, from_status, to_status, note, created_at)
    VALUES (v_issue, 'authority', 'IT Office', 'open', 'acknowledged', 'We are adding an access point on the 2nd floor.', now() - interval '2 days');

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'food', false, 'Cafeteria prices went up without notice',
            'Prices at the central cafeteria went up this month without any notice. Rice with chicken now costs much more than before.',
            'Central cafeteria', 'open', 24, 0, now() - interval '1 day', now() - interval '1 day')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_c);

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'academic', false, 'Results of the last semester are not published yet',
            'It has been more than two months since the final exams and the results are still not published. We need them for scholarship forms.',
            'Exam controller office', 'open', 89, 0, now() - interval '8 hours', now() - interval '8 hours')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_cr2);
    INSERT INTO issue_votes (issue_id, user_id) VALUES (v_issue, v_me);

    INSERT INTO issues (university_id, category, private, title, body, location_label, status, me_too_count, comment_count, created_at, status_changed_at, solved_at)
    VALUES (v_uni, 'facilities', false, 'Broken fans in CSE 202 fixed',
            'Three ceiling fans in CSE 202 were broken for two weeks and it was very hot during the 11 AM class. They work again now, thank you.',
            'CSE 202', 'solved', 15, 0, now() - interval '12 days', now() - interval '2 days', now() - interval '2 days')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_a);
    INSERT INTO status_updates (issue_id, actor_kind, actor_title, from_status, to_status, note, created_at)
    VALUES (v_issue, 'authority', 'Maintenance Office', 'open', 'solved', 'All three fans were replaced.', now() - interval '2 days');

    -- ---- Campus social: posts, questions, polls (docs/CAMPUS_SOCIAL.md) -------
    -- Counts are demo numbers; the reaction emojis come from the rows below.
    -- Your own account is left out, so you can react and vote yourself.

    -- An event, posted with a name.
    INSERT INTO issues (university_id, kind, category, private, title, body, location_label, status, named, named_author_id,
                        me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'post', 'event', false, '',
            E'🎉 Cultural night on the central field this Thursday at 6 PM!\nBands, food stalls and a stand-up set. Bring your friends, entry is free.',
            'Central field', 'open', true, v_cr2, 37, 3, now() - interval '3 hours', now() - interval '3 hours')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_cr2);
    INSERT INTO issue_votes (issue_id, user_id, reaction) VALUES (v_issue, v_a, 'like'), (v_issue, v_b, 'like'), (v_issue, v_c, 'clap');
    INSERT INTO comments (issue_id, kind, handle, body, created_at) VALUES
        (v_issue, 'student', 'Q7MD', 'Count me in! 🎶', now() - interval '2 hours') RETURNING id INTO v_cmt;
    INSERT INTO comment_authors (comment_id, user_id) VALUES (v_cmt, v_b);
    INSERT INTO comments (issue_id, kind, handle, body, like_count, created_at) VALUES
        (v_issue, 'student', 'H3ZT', 'Will there be food for vegetarians?', 2, now() - interval '100 minutes') RETURNING id INTO v_cmt;
    INSERT INTO comment_authors (comment_id, user_id) VALUES (v_cmt, v_c);
    INSERT INTO comment_likes (comment_id, user_id) VALUES (v_cmt, v_a), (v_cmt, v_b);
    INSERT INTO comments (issue_id, kind, named, named_author_id, body, parent_id, created_at) VALUES
        (v_issue, 'student', true, v_cr2, 'Yes! Two stalls have veg khichuri and singara.', v_cmt, now() - interval '90 minutes');
    INSERT INTO comment_authors (comment_id, user_id) SELECT id, v_cr2 FROM comments WHERE parent_id = v_cmt;

    -- A poll.
    INSERT INTO issues (university_id, kind, category, private, title, body, status, me_too_count, comment_count,
                        poll_closes_at, created_at, status_changed_at)
    VALUES (v_uni, 'poll', 'food', false, '', 'Best cha spot near campus? ☕', 'open', 12, 1,
            now() + interval '2 days', now() - interval '5 hours', now() - interval '5 hours')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_b);
    INSERT INTO poll_options (issue_id, position, label, vote_count) VALUES
        (v_issue, 0, 'Bot tola', 18), (v_issue, 1, 'TSC canteen', 11), (v_issue, 2, 'The tong at the hall gate', 7), (v_issue, 3, 'Library café', 3);
    SELECT id INTO v_opt FROM poll_options WHERE issue_id = v_issue AND position = 0;
    INSERT INTO poll_votes (issue_id, user_id, option_id) VALUES (v_issue, v_a, v_opt), (v_issue, v_cr2, v_opt);
    SELECT id INTO v_opt FROM poll_options WHERE issue_id = v_issue AND position = 1;
    INSERT INTO poll_votes (issue_id, user_id, option_id) VALUES (v_issue, v_c, v_opt);
    INSERT INTO issue_votes (issue_id, user_id, reaction) VALUES (v_issue, v_a, 'haha'), (v_issue, v_c, 'like');
    INSERT INTO comments (issue_id, kind, handle, body, created_at) VALUES
        (v_issue, 'student', 'W4KP', 'Bot tola after the 4:30 class is unbeatable', now() - interval '4 hours') RETURNING id INTO v_cmt;
    INSERT INTO comment_authors (comment_id, user_id) VALUES (v_cmt, v_a);

    -- A question with answers, one marked from the asker.
    INSERT INTO issues (university_id, kind, category, private, title, body, status, me_too_count, comment_count,
                        created_at, status_changed_at)
    VALUES (v_uni, 'question', 'transport', false, '',
            'Does the Savar bus run on Friday mornings? I have a 9 AM make-up class this week.',
            'open', 6, 3, now() - interval '7 hours', now() - interval '7 hours')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_c);
    INSERT INTO issue_votes (issue_id, user_id, reaction) VALUES (v_issue, v_a, 'like'), (v_issue, v_b, 'wow');
    INSERT INTO comments (issue_id, kind, handle, body, like_count, created_at) VALUES
        (v_issue, 'student', 'N8RF', 'Yes, the 7:30 one runs on Fridays too. It leaves from the Savar bus stand.', 3, now() - interval '6 hours')
    RETURNING id INTO v_cmt;
    INSERT INTO comment_authors (comment_id, user_id) VALUES (v_cmt, v_b);
    INSERT INTO comment_likes (comment_id, user_id) VALUES (v_cmt, v_a), (v_cmt, v_c), (v_cmt, v_cr2);
    INSERT INTO comments (issue_id, kind, handle, body, parent_id, created_at) VALUES
        (v_issue, 'student', 'T2VJ', 'Thanks a lot! 🙏', v_cmt, now() - interval '5 hours');
    INSERT INTO comment_authors (comment_id, user_id) SELECT id, v_c FROM comments WHERE parent_id = v_cmt;
    INSERT INTO comments (issue_id, kind, handle, body, created_at) VALUES
        (v_issue, 'student', 'C5XH', 'Check the Bus routes page in the app, it has the Friday times.', now() - interval '4 hours')
    RETURNING id INTO v_cmt;
    INSERT INTO comment_authors (comment_id, user_id) VALUES (v_cmt, v_a);

    -- Fun.
    INSERT INTO issues (university_id, kind, category, private, title, body, status, me_too_count, comment_count,
                        created_at, status_changed_at)
    VALUES (v_uni, 'post', 'fun', false, '',
            'When the teacher says "just one more slide" at 4:59 PM 😅', 'open', 64, 0,
            now() - interval '9 hours', now() - interval '9 hours')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_a);
    INSERT INTO issue_votes (issue_id, user_id, reaction) VALUES (v_issue, v_b, 'haha'), (v_issue, v_c, 'haha'), (v_issue, v_cr2, 'like');

    -- Lost and found.
    INSERT INTO issues (university_id, kind, category, private, title, body, location_label, status, me_too_count, comment_count,
                        created_at, status_changed_at)
    VALUES (v_uni, 'post', 'lost_found', false, '',
            E'Found a blue water bottle and a Casio calculator (fx-991) in Room 302 after the 11 AM class.\nI left them at the department office.',
            'Room 302', 'open', 9, 0, now() - interval '26 hours', now() - interval '26 hours')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_b);
    INSERT INTO issue_votes (issue_id, user_id, reaction) VALUES (v_issue, v_c, 'like');

    -- Buy and sell, with a name.
    INSERT INTO issues (university_id, kind, category, private, title, body, location_label, status, named, named_author_id,
                        me_too_count, comment_count, created_at, status_changed_at)
    VALUES (v_uni, 'post', 'buy_sell', false, '',
            'Selling my Introduction to Algorithms (CLRS, 3rd ed.), barely used. 450 tk. Pick it up at Hall 2.',
            'Hall 2', 'open', true, v_a, 4, 0, now() - interval '2 days', now() - interval '2 days')
    RETURNING id INTO v_issue;
    INSERT INTO issue_authors (issue_id, user_id) VALUES (v_issue, v_a);
    INSERT INTO issue_votes (issue_id, user_id, reaction) VALUES (v_issue, v_c, 'like');

    -- ---- blood donation (docs/BLOOD_DONATION.md) --------------------------------
    -- Classmates are donors; two open requests. Your own account is left as
    -- it is, so you can become a donor yourself.
    DELETE FROM blood_requests WHERE requester_id IN (v_cr2, v_a, v_b, v_c);
    INSERT INTO blood_donors (user_id, blood_group, available, phone, last_donated, donations) VALUES
        (v_cr2, 'A+', true, '01711000001', NULL, 2),
        (v_a,   'A+', true, '01711000002', (now() - interval '200 days')::date, 4),
        (v_b,   'O+', true, '01711000003', (now() - interval '30 days')::date, 1),
        (v_c,   'B+', true, '01711000004', NULL, 0)
    ON CONFLICT (user_id) DO UPDATE SET blood_group = EXCLUDED.blood_group, available = EXCLUDED.available,
        phone = EXCLUDED.phone, last_donated = EXCLUDED.last_donated, donations = EXCLUDED.donations;

    INSERT INTO blood_requests (university_id, requester_id, blood_group, units, hospital, area, needed_by, urgent,
                                contact_name, contact_phone, note, notified, created_at)
    VALUES (v_uni, v_cr2, 'A+', 2, 'Enam Medical College Hospital', 'Savar',
            date_trunc('hour', now()) + interval '5 hours', true, 'Tanvir Ahmed', '01711000001',
            'My cousin has a surgery tonight. Please call if you can come.', 3, now() - interval '40 minutes')
    RETURNING id INTO v_issue;
    INSERT INTO blood_responses (request_id, donor_id, phone, created_at)
    VALUES (v_issue, v_a, '01711000002', now() - interval '20 minutes');

    INSERT INTO blood_requests (university_id, requester_id, blood_group, units, hospital, area, needed_by, urgent,
                                contact_name, contact_phone, note, notified, created_at)
    VALUES (v_uni, v_c, 'O-', 1, 'Dhaka Medical College Hospital', 'Shahbagh',
            date_trunc('day', now()) + interval '1 day 10 hours', false, 'Sadia Rahman', '01711000004',
            'Thalassemia patient, needs blood every month.', 0, now() - interval '3 hours');

    -- ---- bus routes (stops in to-campus order; minutes from the start) ------
    DELETE FROM bus_routes WHERE university_id = v_uni AND name LIKE 'Demo %';

    INSERT INTO bus_routes (university_id, name, color, notes, active, driver_name, driver_phone)
    VALUES (v_uni, 'Demo 1 · Mirpur – Savar – Campus', '#0F766E', 'Show your student ID when you board. No bus on government holidays.',
            true, 'Abdul Karim', '01000000001') RETURNING id INTO v_route;
    INSERT INTO bus_stops (route_id, position, name, landmark, to_campus_min, from_campus_min, lat, lng) VALUES
        (v_route, 0, 'Mirpur 10',     'Metro station',  0,  95, 23.8069, 90.3687),
        (v_route, 1, 'Mirpur 1',      'Sony cinema',   10,  85, 23.7957, 90.3537),
        (v_route, 2, 'Gabtoli',       'Bus terminal',  20,  75, 23.7838, 90.3445),
        (v_route, 3, 'Aminbazar',     '',              30,  65, 23.7863, 90.3256),
        (v_route, 4, 'Hemayetpur',    '',              45,  50, 23.7962, 90.2699),
        (v_route, 5, 'Savar',         'Bus stand',     60,  35, 23.8448, 90.2577),
        (v_route, 6, 'JU main gate',  '',              85,  10, 23.8780, 90.2680),
        (v_route, 7, 'Campus',        'Central field', 95,   0, 23.8813, 90.2671);
    INSERT INTO bus_trips (route_id, direction, departs_min, weekdays, note) VALUES
        (v_route, 'to_campus',   420, '{6,7,1,2,3,4}', ''),
        (v_route, 'to_campus',   480, '{6,7,1,2,3,4}', ''),
        (v_route, 'from_campus', 810, '{6,7,1,2,3,4}', ''),
        (v_route, 'from_campus', 1035, '{6,7,1,2,3,4}', 'Last bus');

    INSERT INTO bus_routes (university_id, name, color, notes, active, driver_name, driver_phone)
    VALUES (v_uni, 'Demo 2 · Farmgate – Shyamoli – Campus', '#2563EB', '', true, 'Jamal Uddin', '01000000002') RETURNING id INTO v_route;
    INSERT INTO bus_stops (route_id, position, name, landmark, to_campus_min, from_campus_min, lat, lng) VALUES
        (v_route, 0, 'Farmgate',      'Ananda cinema',  0, 110, 23.7569, 90.3897),
        (v_route, 1, 'Dhanmondi 27',  '',              15,  95, 23.7516, 90.3756),
        (v_route, 2, 'Shyamoli',      'Shishu Mela',   30,  80, 23.7745, 90.3654),
        (v_route, 3, 'Kallyanpur',    '',              40,  70, 23.7808, 90.3606),
        (v_route, 4, 'Technical',     '',              45,  65, NULL, NULL),
        (v_route, 5, 'Gabtoli',       '',              50,  60, 23.7838, 90.3445),
        (v_route, 6, 'Campus',        '',             110,   0, 23.8813, 90.2671);
    INSERT INTO bus_trips (route_id, direction, departs_min, weekdays, note) VALUES
        (v_route, 'to_campus',   405, '{6,7,1,2,3,4}', ''),
        (v_route, 'from_campus', 1020, '{6,7,1,2,3,4}', '');

    INSERT INTO bus_routes (university_id, name, color, notes, active, driver_name, driver_phone)
    VALUES (v_uni, 'Demo 3 · Uttara – Ashulia – Campus', '#7C3AED', 'Weekend route for evening programs.', true, '', '') RETURNING id INTO v_route;
    INSERT INTO bus_stops (route_id, position, name, landmark, to_campus_min, from_campus_min, lat, lng) VALUES
        (v_route, 0, 'Abdullahpur',   '',               0, NULL, 23.8797, 90.4006),
        (v_route, 1, 'Ashulia',       'Zirabo',        35, NULL, 23.8973, 90.3277),
        (v_route, 2, 'Baipail',       '',              55, NULL, 23.9306, 90.2795),
        (v_route, 3, 'Campus',        '',              75,    0, 23.8813, 90.2671);
    INSERT INTO bus_trips (route_id, direction, departs_min, weekdays, note) VALUES
        (v_route, 'to_campus',   400, '{5,6}', 'Fri, Sat only'),
        (v_route, 'from_campus', 1140, '{5,6}', '');
END
$seed$;

COMMIT;

SELECT 'group' AS what, (SELECT count(*) FROM routine_slots s JOIN class_groups g ON g.id = s.group_id WHERE g.join_code = 'DEMJUA') AS n
UNION ALL SELECT 'changes', (SELECT count(*) FROM routine_changes c JOIN class_groups g ON g.id = c.group_id WHERE g.join_code = 'DEMJUA')
UNION ALL SELECT 'tests', (SELECT count(*) FROM assessments a JOIN class_groups g ON g.id = a.group_id WHERE g.join_code = 'DEMJUA')
UNION ALL SELECT 'issues', (SELECT count(*) FROM issues i JOIN issue_authors x ON x.issue_id = i.id JOIN users u ON u.id = x.user_id WHERE u.university_id = (SELECT university_id FROM users WHERE email = :'email'))
UNION ALL SELECT 'bus routes', (SELECT count(*) FROM bus_routes WHERE name LIKE 'Demo %');
