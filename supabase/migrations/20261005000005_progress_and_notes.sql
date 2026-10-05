-- Bookly · Phase 0 · foundation
-- Position tracking and notes (PLAN.md §2.2, §2.3, §5.4, §5.5).
--
-- Position only — chapter plus an optional percentage. There is no reading
-- timer anywhere in this schema, because §5.4 rules one out and a column
-- for something the app does not do is a column every reader has to
-- understand anyway.

-- ── Whole-book position ────────────────────────────────────────────────────
create table public.reading_progress (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references public.profiles (id) on delete cascade,
  book_id            uuid not null references public.books (id) on delete cascade,
  status             item_status not null default 'reading',
  current_chapter_id uuid references public.chapters (id) on delete set null,
  -- Optional; §5.4 "chapter + optional %". Null means the reader has a
  -- chapter but has not reported a position inside it.
  percent            numeric(5, 2) check (percent is null or (percent >= 0 and percent <= 100)),
  -- Times completed, not times opened: PLAN.md §6.4 renders
  -- "finished Atomic Habits · 3rd read", which is the count at the moment
  -- of the third completion. Starts at 0 — a book started and never
  -- finished has been read zero times.
  read_count         integer not null default 0 check (read_count >= 0),
  started_at         timestamptz not null default now(),
  last_read_at       timestamptz not null default now(),
  finished_at        timestamptz,
  unique (user_id, book_id)
);

create index reading_progress_book_idx on public.reading_progress (book_id, status);

create or replace function public.on_reading_progress_write()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    new.started_at := coalesce(new.started_at, now());
    new.last_read_at := now();

    if new.status = 'finished' then
      new.finished_at := coalesce(new.finished_at, now());
      new.read_count := 1;
    else
      new.finished_at := null;
      new.read_count := 0;
    end if;

    return new;
  end if;

  if new.status = 'finished' and old.status <> 'finished' then
    new.finished_at := coalesce(new.finished_at, now());
    new.read_count := old.read_count + 1;
  elsif new.status <> 'finished' and old.status = 'finished' then
    -- Un-finishing clears the timestamp but not the count: read_count is a
    -- record of completions that happened, and taking one back would make
    -- the feed's "3rd read" mean something different tomorrow.
    new.finished_at := null;
  else
    new.last_read_at := now();
  end if;

  return new;
end;
$$;

create trigger reading_progress_write
  before insert or update on public.reading_progress
  for each row execute function public.on_reading_progress_write();

-- ── Chapter / link position ────────────────────────────────────────────────
-- PLAN.md §2.2, verbatim.
--
-- One table, not two: chapter and link progress have an identical shape,
-- lifecycle and UI treatment. Two tables would mean two repositories, two
-- providers, two test suites, and a join on every feed render.
create table public.item_progress (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  book_id     uuid not null references public.books (id) on delete cascade,
  item_type   item_type not null,
  chapter_id  uuid references public.chapters (id) on delete cascade,
  link_id     uuid references public.book_links (id) on delete cascade,
  status      item_status not null default 'not_started',
  started_at  timestamptz,
  finished_at timestamptz,
  created_at  timestamptz not null default now(),
  constraint one_target      check (num_nonnulls(chapter_id, link_id) = 1),
  constraint type_matches_fk check ((item_type = 'chapter') = (chapter_id is not null))
);

create unique index item_progress_user_chapter_uidx
  on public.item_progress (user_id, chapter_id)
  where chapter_id is not null;

create unique index item_progress_user_link_uidx
  on public.item_progress (user_id, link_id)
  where link_id is not null;

create index item_progress_book_user_idx on public.item_progress (book_id, user_id);

-- ── Notes ──────────────────────────────────────────────────────────────────
-- Owner-only, always — PLAN.md §2.7 is unambiguous that no circle read path
-- exists for these, and §5.5 that every note is private by default. The
-- public counterpart is book_contributions, written by an explicit share.
create table public.reading_notes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  book_id     uuid not null references public.books (id) on delete cascade,
  chapter_id  uuid references public.chapters (id) on delete cascade,
  link_id     uuid references public.book_links (id) on delete cascade,
  content     text not null check (char_length(content) between 1 and 20000),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  -- Three scopes, and never two at once: whole-book (both null),
  -- per-chapter, or per-link (§2.3).
  constraint reading_notes_one_scope check (num_nonnulls(chapter_id, link_id) <= 1)
);

create index reading_notes_user_book_idx on public.reading_notes (user_id, book_id);

-- One note per scope. A partial unique index for each rather than a
-- composite of nullable columns: NULLs do not conflict in Postgres, so
-- `unique (user_id, book_id, chapter_id, link_id)` would happily accept an
-- infinite number of whole-book notes.
create unique index reading_notes_whole_book_uidx
  on public.reading_notes (user_id, book_id)
  where chapter_id is null and link_id is null;

create unique index reading_notes_chapter_uidx
  on public.reading_notes (user_id, chapter_id)
  where chapter_id is not null;

create unique index reading_notes_link_uidx
  on public.reading_notes (user_id, link_id)
  where link_id is not null;

create trigger reading_notes_set_updated_at
  before update on public.reading_notes
  for each row execute function public.set_updated_at();

-- ── Shared notes ───────────────────────────────────────────────────────────
-- §2.3: gains the same nullable link_id, so sharing a note on a video is
-- the same action as sharing one on a chapter. Read by active members of
-- the book's circle (§2.7); written only by the author, and only by
-- choosing to share.
create table public.book_contributions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  book_id     uuid not null references public.books (id) on delete cascade,
  chapter_id  uuid references public.chapters (id) on delete cascade,
  link_id     uuid references public.book_links (id) on delete cascade,
  content     text not null check (char_length(content) between 1 and 20000),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint book_contributions_one_scope check (num_nonnulls(chapter_id, link_id) <= 1)
);

create index book_contributions_book_idx on public.book_contributions (book_id, created_at);
create index book_contributions_user_idx on public.book_contributions (user_id);

create trigger book_contributions_set_updated_at
  before update on public.book_contributions
  for each row execute function public.set_updated_at();
