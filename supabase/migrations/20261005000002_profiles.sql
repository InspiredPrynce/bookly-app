-- Bookly · Phase 0 · foundation
-- profiles (PLAN.md §2.1, §2.5, §3).
--
-- The profile row is created by a trigger on auth.users, never by the app.
-- Registration only supplies a name, email and password; if the app had to
-- remember to insert a profile too, every other table's foreign key would
-- be one forgotten write away from failing.
--
-- Everything on this table is safe for a signed-in reader to see: the
-- activity feed, the member list and MemberProfileSheet all need names,
-- avatars and bios of people they share a circle with, and a policy that
-- admitted "any profile row, but not these columns" cannot be expressed in
-- Postgres without column grants — which break Supabase's generated
-- `select *`. Consequently nothing private lives here. `fcm_token` in
-- particular does NOT: it is a routing credential for this user's device
-- and belongs to them alone, so it sits in `device_tokens`
-- (20261005000007), which is self-only under RLS.

create table public.profiles (
  id                    uuid primary key references auth.users (id) on delete cascade,
  name                  text not null check (char_length(name) between 1 and 60),
  -- A path within the avatars bucket, not a URL: a storage policy
  -- authorises a path, and a URL embeds the project ref instead.
  avatar_path           text,
  bio                   text check (bio is null or char_length(bio) <= 160),
  daily_reminder_time   time,

  -- PLAN.md §2.5 — the four sharing toggles. These gate *push*, never the
  -- feed: circle_events are written unconditionally by the triggers in
  -- 20261005000006_activity.sql. A reader choosing not to interrupt their
  -- circle has not chosen to hide their reading from it.
  notify_book_start       boolean not null default true,
  notify_chapter_start    boolean not null default true,
  notify_book_finished    boolean not null default true,
  notify_chapter_finished boolean not null default false, -- the noisiest one

  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ── Every auth user gets a profile ─────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'name', ''),
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      split_part(coalesce(new.email, 'reader'), '@', 1)
    )
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── Finding someone by email ───────────────────────────────────────────────
-- An invite by email (PLAN.md §6.2) has to answer "is there an account
-- with this address?", and auth.users is not readable by clients — so this
-- is the one path to it.
--
-- It confirms existence to the person doing the search and to nobody else:
-- it returns a single row only when one exact, trimmed, case-insensitive
-- email matches, and no row otherwise. That is precisely PLAN.md §6.10's
-- error copy ("No Bookly account with that email"), which is a statement
-- made to the searcher.
create or replace function public.find_profile_by_email(p_email text)
returns table (id uuid, name text, avatar_path text)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.name, p.avatar_path
  from public.profiles p
  join auth.users u on u.id = p.id
  where auth.uid() is not null
    and lower(u.email) = lower(trim(p_email));
$$;

revoke all on function public.find_profile_by_email(text) from public, anon;
grant execute on function public.find_profile_by_email(text) to authenticated;
