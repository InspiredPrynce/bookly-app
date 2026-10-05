-- Bookly · Phase 0 · foundation
-- Books, chapters and links (PLAN.md §5).
--
-- Books are user-created and never admin-seeded (§5.1), and the app holds
-- metadata plus the reader's own notes — never a whole book's text. That is
-- why `chapters.content` is nullable and why there is no `books.format`
-- enum: format is derived from chapter_count / link_count (§5.6), because
-- a stored enum drifts and a derived rule cannot.

create table public.books (
  id          uuid primary key default gen_random_uuid(),
  created_by  uuid not null references public.profiles (id) on delete cascade,
  title       text not null check (char_length(title) between 1 and 300),
  authors     text[] not null default '{}',
  about       text,
  cover_path  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index books_created_by_idx on public.books (created_by);

create trigger books_set_updated_at
  before update on public.books
  for each row execute function public.set_updated_at();

create table public.chapters (
  id          uuid primary key default gen_random_uuid(),
  book_id     uuid not null references public.books (id) on delete cascade,
  position    integer not null check (position >= 1),
  title       text not null check (char_length(title) between 1 and 300),
  -- Optional. Full book text is not required in the app (§5.1); what is
  -- here is whatever the creator chose to attach, and the reader's own
  -- notes live elsewhere entirely.
  content     text,
  created_at  timestamptz not null default now(),
  unique (book_id, position)
);

create index chapters_book_idx on public.chapters (book_id, position);

-- ── Links ──────────────────────────────────────────────────────────────────
-- A link-only book has zero rows in chapters and at least one row here
-- (§5.3, §5.7): BookDetailScreen *is* its consumption surface.
create table public.book_links (
  id          uuid primary key default gen_random_uuid(),
  book_id     uuid not null references public.books (id) on delete cascade,
  type        link_kind not null,
  title       text not null check (char_length(title) between 1 and 300),
  url         text not null check (url ~* '^https?://'),
  position    integer not null check (position >= 1),
  created_at  timestamptz not null default now(),
  unique (book_id, position)
);

create index book_links_book_idx on public.book_links (book_id, position);
