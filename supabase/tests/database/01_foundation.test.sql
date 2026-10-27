-- Security tests for the R0 foundation. Run with: supabase test db
-- Each test tries to break a rule a real attacker would try.
begin;
create extension if not exists pgtap with schema extensions;
select plan(25);

-- ---------------------------------------------------------------- setup
insert into public.universities (slug, name, email_domains)
values ('test-uni', 'Test University', '{test.ac.bd}');

-- ------------------------------------------------- 1. structure guards
select is_empty(
  $$ select tablename from pg_tables
     where schemaname = 'public' and not rowsecurity $$,
  'every public table has row level security enabled'
);

select is_empty(
  $$ select table_name from information_schema.role_table_grants
     where table_schema = 'private'
       and grantee in ('anon', 'authenticated', 'public') $$,
  'no private table is granted to API roles'
);

-- --------------------------------------------------- 2. sign-up rules
select is(
  private.hook_before_user_created('{"user": {"email": "someone@gmail.com"}}'::jsonb) -> 'error' ->> 'http_code',
  '403',
  'hook rejects non-university email'
);

select is(
  private.hook_before_user_created('{"user": {"email": "alice@test.ac.bd"}}'::jsonb),
  '{}'::jsonb,
  'hook accepts university email'
);

select is(
  private.university_for_email('x@cse.test.ac.bd'),
  (select id from public.universities where slug = 'test-uni'),
  'department subdomain matches its university'
);

select is(
  private.university_for_email('x@nottest.ac.bd'),
  null,
  'look-alike domain does not match'
);

select throws_ok(
  $$ insert into auth.users (id, email) values ('99999999-9999-9999-9999-999999999999', 'mallory@gmail.com') $$,
  'P0001',
  'email is not from a supported university',
  'backstop trigger blocks non-university accounts'
);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.ac.bd'),
  ('22222222-2222-2222-2222-222222222222', 'bob@cse.test.ac.bd');

select is(
  (select count(*)::int from public.profiles where id in (
    '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')),
  2,
  'profiles are created for university sign-ups'
);

select is(
  (select verified_at from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  null,
  'not verified before the email code is confirmed'
);

update auth.users set email_confirmed_at = now()
  where id = '11111111-1111-1111-1111-111111111111';

select isnt(
  (select verified_at from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  null,
  'verified after the email code is confirmed'
);

select throws_ok(
  $$ update auth.users set email = 'alice@gmail.com'
     where id = '11111111-1111-1111-1111-111111111111' $$,
  'P0001',
  null,
  'cannot change email to a non-university address'
);

-- ------------------------------------------- 3. anonymous (signed out)
set local role anon;
select set_config('request.jwt.claims', '{"role": "anon"}', true);

select ok(
  (select count(*) from public.universities) >= 1,
  'signed-out users can read the university list'
);

select ok(
  (select count(*) from public.app_config) >= 1,
  'signed-out users can read app config'
);

select throws_ok(
  $$ select * from public.profiles $$,
  '42501',
  null,
  'signed-out users cannot read profiles'
);

select throws_ok(
  $$ insert into public.universities (slug, name) values ('fake', 'Fake University') $$,
  '42501',
  null,
  'signed-out users cannot add universities'
);

select throws_ok(
  $$ select public.delete_my_account() $$,
  '42501',
  null,
  'signed-out users cannot call delete_my_account'
);

-- --------------------------------------------- 4. signed in as alice
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}',
  true
);

select results_eq(
  $$ select id from public.profiles $$,
  $$ values ('11111111-1111-1111-1111-111111111111'::uuid) $$,
  'a student sees only their own profile'
);

select lives_ok(
  $$ update public.profiles set display_name = 'Alice'
     where id = '11111111-1111-1111-1111-111111111111' $$,
  'a student can edit their own name'
);

select throws_ok(
  $$ update public.profiles set role = 'admin'
     where id = '11111111-1111-1111-1111-111111111111' $$,
  '42501',
  null,
  'a student cannot make themselves admin'
);

select throws_ok(
  $$ update public.profiles set verified_at = now(), university_id = gen_random_uuid()
     where id = '11111111-1111-1111-1111-111111111111' $$,
  '42501',
  null,
  'a student cannot change verification or university'
);

-- Updating someone else's row silently matches nothing (RLS).
update public.profiles set display_name = 'Hacked'
  where id = '22222222-2222-2222-2222-222222222222';

select throws_ok(
  $$ select * from private.audit_log $$,
  '42501',
  null,
  'a student cannot read the private schema'
);

select throws_ok(
  $$ update public.app_config set value = '999' where key = 'min_supported_build' $$,
  '42501',
  null,
  'a student cannot change app config'
);

select lives_ok(
  $$ select public.delete_my_account() $$,
  'a student can delete their account'
);

-- ------------------------------------------------- 5. check as admin
reset role;

select is(
  (select display_name from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  null,
  'another student''s profile was not changed'
);

select is(
  (select count(*)::int from auth.users where id = '11111111-1111-1111-1111-111111111111'),
  0,
  'deleted account is really gone'
);

select * from finish();
rollback;
