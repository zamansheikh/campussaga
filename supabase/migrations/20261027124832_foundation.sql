-- =============================================================================
-- R0 Foundation: universities, profiles, app config, private schema.
--
-- Security model (see docs/ARCHITECTURE.md):
--   * Every public table has Row Level Security ON.
--   * Roles get only the grants they need; nothing is reachable by default.
--   * Sensitive data and helper functions live in the `private` schema,
--     which is never exposed through the API.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. Defaults: new functions are NOT executable by everyone
-- -----------------------------------------------------------------------------
alter default privileges in schema public
  revoke execute on functions from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 1. Private schema
-- -----------------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

alter default privileges in schema private
  revoke execute on functions from public, anon, authenticated;

create table private.audit_log (
  id          bigint generated always as identity primary key,
  actor_id    uuid,
  action      text not null,
  target_type text,
  target_id   text,
  meta        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);
comment on table private.audit_log is
  'Every moderator/admin action. Not reachable through the API.';

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. Universities
-- -----------------------------------------------------------------------------
create table public.universities (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name          text not null check (char_length(name) between 2 and 120),
  name_bn       text check (char_length(name_bn) <= 120),
  -- Student email domains, lower case, e.g. {'du.ac.bd'}. Subdomains match too.
  email_domains text[] not null default '{}'
                check (email_domains::text = lower(email_domains::text)),
  city          text,
  timezone      text not null default 'Asia/Dhaka',
  -- First day of the week, ISO numbering (1 = Monday ... 6 = Saturday, 7 = Sunday).
  week_start    smallint not null default 6 check (week_start between 1 and 7),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index universities_email_domains_idx
  on public.universities using gin (email_domains);
create trigger universities_set_updated_at
  before update on public.universities
  for each row execute function private.set_updated_at();

alter table public.universities enable row level security;
revoke all on public.universities from anon, authenticated;
grant select on public.universities to anon, authenticated;

-- Public list, so the app can check an email domain before sending a code.
create policy universities_read_active on public.universities
  for select to anon, authenticated
  using (is_active);
-- No insert/update/delete policies: managed by admins only.

-- Returns the university an email address belongs to, or null.
-- The longest matching domain wins (cse.du.ac.bd before du.ac.bd).
create function private.university_for_email(p_email text)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select u.id
  from public.universities u
  cross join lateral unnest(u.email_domains) as d(domain)
  cross join lateral (select lower(split_part(p_email, '@', 2)) as host) e
  where u.is_active
    and p_email like '%_@_%'
    and (e.host = d.domain or right(e.host, length(d.domain) + 1) = '.' || d.domain)
  order by length(d.domain) desc
  limit 1;
$$;

-- -----------------------------------------------------------------------------
-- 3. Profiles
-- -----------------------------------------------------------------------------
create type public.user_role as enum ('student', 'authority', 'moderator', 'admin');

create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  university_id uuid not null references public.universities (id),
  display_name  text check (display_name is null or char_length(btrim(display_name)) between 1 and 60),
  department    text check (department is null or char_length(department) <= 80),
  batch         text check (batch is null or char_length(batch) <= 20),
  role          public.user_role not null default 'student',
  -- Set when the university email is confirmed with the OTP code.
  verified_at   timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index profiles_university_id_idx on public.profiles (university_id);
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function private.set_updated_at();

alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
-- Students may edit only these columns; role, university and verification
-- are controlled by the server.
grant update (display_name, department, batch) on public.profiles to authenticated;

create policy profiles_read_own on public.profiles
  for select to authenticated
  using (id = (select auth.uid()));

create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- 4. Sign-up rules
-- -----------------------------------------------------------------------------

-- Auth hook: rejects sign-up from non-university emails with a clear message
-- before any account is created or code is sent.
create function private.hook_before_user_created(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if private.university_for_email(event -> 'user' ->> 'email') is null then
    return jsonb_build_object(
      'error', jsonb_build_object(
        'http_code', 403,
        'message', 'Please use your university email address.'
      )
    );
  end if;
  return '{}'::jsonb;
end;
$$;

grant usage on schema private to supabase_auth_admin;
grant execute on function private.hook_before_user_created(jsonb) to supabase_auth_admin;

-- Backstop (if the hook is ever misconfigured): every new user gets a
-- profile tied to their university, or the sign-up fails.
create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_university uuid := private.university_for_email(new.email);
begin
  if v_university is null then
    raise exception 'email is not from a supported university'
      using errcode = 'P0001';
  end if;

  insert into public.profiles (id, university_id, verified_at)
  values (new.id, v_university, new.email_confirmed_at);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- Keeps the profile in sync when the email is confirmed or changed.
create function private.handle_user_email_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_university uuid;
begin
  if new.email is distinct from old.email then
    v_university := private.university_for_email(new.email);
    if v_university is null then
      raise exception 'email is not from a supported university'
        using errcode = 'P0001';
    end if;
    update public.profiles
      set university_id = v_university
      where id = new.id;
  end if;

  if new.email_confirmed_at is not null and old.email_confirmed_at is null then
    update public.profiles
      set verified_at = new.email_confirmed_at
      where id = new.id and verified_at is null;
  end if;
  return new;
end;
$$;

create trigger on_auth_user_email_updated
  after update of email, email_confirmed_at on auth.users
  for each row execute function private.handle_user_email_update();

-- -----------------------------------------------------------------------------
-- 5. App config (minimum app version, feature flags)
-- -----------------------------------------------------------------------------
create table public.app_config (
  key        text primary key check (key ~ '^[a-z0-9_.]+$'),
  value      jsonb not null,
  updated_at timestamptz not null default now()
);
create trigger app_config_set_updated_at
  before update on public.app_config
  for each row execute function private.set_updated_at();

alter table public.app_config enable row level security;
revoke all on public.app_config from anon, authenticated;
grant select on public.app_config to anon, authenticated;

create policy app_config_read_all on public.app_config
  for select to anon, authenticated
  using (true);

insert into public.app_config (key, value) values
  ('min_supported_build', '1'::jsonb),
  ('features', '{"my_class": false, "campus_voice": false}'::jsonb);

-- -----------------------------------------------------------------------------
-- 6. Account deletion (required by the Play Store and our privacy promise)
-- -----------------------------------------------------------------------------
create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  -- Cascades to profiles and everything else owned by the user.
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
