-- Bookly · Phase 0 · foundation
-- circle_events and the triggers that write it (PLAN.md §2.4).
--
-- ## Service-role only
--
-- RLS on this table admits no INSERT, UPDATE or DELETE for any client role
-- — see 20261005000009_rls.sql. The only writers are these triggers, which
-- are SECURITY DEFINER so they run with the table owner's rights rather
-- than the reader's.
--
-- ## Why triggers rather than a client write
--
-- §2.4 is explicit: written by trigger "so the client cannot forget to
-- write one and the feed can never desync from actual progress." PLAN.md
-- §6.7's step 2 ("Insert circle_events started_reading") is therefore
-- satisfied by this file, not by the app — the app upserts reading_progress
-- and the event follows. A client-side write would have been two sources of
-- truth for one fact.
--
-- ## What these triggers deliberately do NOT do
--
-- They do not consult `profiles.notify_*`. Those four toggles gate *push*,
-- not the feed (§6.8) — "the feed always shows your milestones." Whether a
-- phone buzzes is decided per recipient in the Edge Function (§8.3), where
-- rate limiting also lives.
--
-- `milestone` has no trigger: nothing in PLAN.md derives one from a write,
-- so it stays available for the service role rather than being invented
-- here.

create table public.circle_events (
  id          uuid primary key default gen_random_uuid(),
  circle_id   uuid not null references public.circles (id) on delete cascade,
  actor_id    uuid references public.profiles (id) on delete set null,
  type        circle_event_type not null,
  book_id     uuid references public.books (id) on delete cascade,
  chapter_id  uuid references public.chapters (id) on delete cascade,
  link_id     uuid references public.book_links (id) on delete cascade,
  created_at  timestamptz not null default now(),
  constraint circle_events_one_item check (num_nonnulls(chapter_id, link_id) <= 1)
);

create index circle_events_feed_idx
  on public.circle_events (circle_id, created_at desc);
create index circle_events_actor_idx on public.circle_events (actor_id);

-- ── Whole-book events ──────────────────────────────────────────────────────
create or replace function public.emit_on_reading_progress()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_circle uuid;
  v_type   circle_event_type;
begin
  v_circle := public.book_circle_id(new.book_id);
  if v_circle is null then
    return null;
  end if;

  if tg_op = 'INSERT' then
    if new.status = 'reading' then
      v_type := 'started_reading';
    elsif new.status = 'finished' then
      v_type := 'finished_book';
    end if;
  else
    if new.status = 'reading' and old.status <> 'reading' then
      v_type := 'started_reading';
    elsif new.status = 'finished' and old.status <> 'finished' then
      v_type := 'finished_book';
    end if;
  end if;

  if v_type is not null then
    insert into public.circle_events (circle_id, actor_id, type, book_id)
    values (v_circle, new.user_id, v_type, new.book_id);
  end if;

  return null;
end;
$$;

create trigger reading_progress_emit_event
  after insert or update on public.reading_progress
  for each row execute function public.emit_on_reading_progress();

-- ── Chapter / link events ──────────────────────────────────────────────────
create or replace function public.emit_on_item_progress()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_circle uuid;
  v_type   circle_event_type;
begin
  v_circle := public.book_circle_id(new.book_id);
  if v_circle is null then
    return null;
  end if;

  if tg_op = 'INSERT' then
    if new.status = 'reading' then
      v_type := case when new.item_type = 'chapter'
                     then 'started_chapter'::circle_event_type
                     else 'started_link'::circle_event_type end;
    elsif new.status = 'finished' then
      v_type := case when new.item_type = 'chapter'
                     then 'finished_chapter'::circle_event_type
                     else 'finished_link'::circle_event_type end;
    end if;
  else
    if new.status = 'reading' and old.status <> 'reading' then
      v_type := case when new.item_type = 'chapter'
                     then 'started_chapter'::circle_event_type
                     else 'started_link'::circle_event_type end;
    elsif new.status = 'finished' and old.status <> 'finished' then
      v_type := case when new.item_type = 'chapter'
                     then 'finished_chapter'::circle_event_type
                     else 'finished_link'::circle_event_type end;
    end if;
  end if;

  if v_type is not null then
    insert into public.circle_events (circle_id, actor_id, type, book_id, chapter_id, link_id)
    values (v_circle, new.user_id, v_type, new.book_id, new.chapter_id, new.link_id);
  end if;

  return null;
end;
$$;

create trigger item_progress_emit_event
  after insert or update on public.item_progress
  for each row execute function public.emit_on_item_progress();

-- ── Membership ─────────────────────────────────────────────────────────────
-- Fires for the creator as well: seeding a book's circle inserts an active
-- owner row, and PLAN.md §6.4's feed example shows exactly that —
-- "＋ You joined the circle".
create or replace function public.emit_on_member_joined()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_circle uuid;
  v_book   uuid;
begin
  if tg_op = 'INSERT' then
    -- A row is created as 'invited' (owner invite, or a self-request under
    -- an approval policy) or as 'active' (the seeded owner). Only the
    -- second is somebody joining.
    if new.status <> 'active' then
      return null;
    end if;
  else
    -- Fires exactly once per person: when an invited or left row becomes
    -- active. A role change on an already-active row, and a departure,
    -- are not a join — without this branch, approving an invite twice or
    -- promoting someone would put two "joined the circle" cards in the
    -- feed.
    if old.status = 'active' or new.status <> 'active' then
      return null;
    end if;
  end if;

  select book_id into v_book from public.circles where id = new.circle_id;
  if v_book is null then
    return null;
  end if;

  insert into public.circle_events (circle_id, actor_id, type, book_id)
  values (new.circle_id, new.user_id, 'member_joined', v_book);

  return null;
end;
$$;

create trigger circle_members_emit_joined
  after insert or update on public.circle_members
  for each row execute function public.emit_on_member_joined();

-- ── Shared notes ───────────────────────────────────────────────────────────
create or replace function public.emit_on_contribution()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_circle uuid;
begin
  v_circle := public.book_circle_id(new.book_id);
  if v_circle is null then
    return null;
  end if;

  insert into public.circle_events
    (circle_id, actor_id, type, book_id, chapter_id, link_id)
  values
    (v_circle, new.user_id, 'posted_summary', new.book_id, new.chapter_id, new.link_id);

  return null;
end;
$$;

create trigger book_contributions_emit_event
  after insert on public.book_contributions
  for each row execute function public.emit_on_contribution();
