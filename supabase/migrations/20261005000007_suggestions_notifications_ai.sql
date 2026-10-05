-- Bookly · Phase 0 · foundation
-- Suggestions, in-app notifications, device tokens and the Gemini thread
-- (PLAN.md §2.1, §6.2, §7, §8).

-- ── Book suggestions ───────────────────────────────────────────────────────
-- sender -> recipient (§6.2). The row *is* the invitation: there is no
-- separate invite table, because a suggestion and an invitation differ only
-- in who acted first, and merging them means one accept/reject path instead
-- of two that drift.
create table public.book_suggestions (
  id           uuid primary key default gen_random_uuid(),
  sender_id    uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  book_id      uuid not null references public.books (id) on delete cascade,
  message      text check (message is null or char_length(message) <= 500),
  status       suggestion_status not null default 'pending',
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  constraint suggestion_not_to_self check (sender_id <> recipient_id)
);

-- One live suggestion per (sender, recipient, book) — resending after a
-- dismiss must not stack a second card on the recipient's screen.
create unique index book_suggestions_live_uidx
  on public.book_suggestions (sender_id, recipient_id, book_id)
  where status = 'pending';

create index book_suggestions_recipient_idx
  on public.book_suggestions (recipient_id, status, created_at desc);
create index book_suggestions_sender_idx
  on public.book_suggestions (sender_id, status, created_at desc);

-- ── Device tokens ──────────────────────────────────────────────────────────
-- Deliberately NOT a column on `profiles` (PLAN.md §3.1 names `fcm_token`
-- without naming a home for it, and §2.1's profiles row does not list it).
-- profiles is readable by every signed-in reader so the feed can name its
-- actors; a token that routes pushes to someone's phone should not be.
--
-- One row per device, so signing in on a second device does not orphan the
-- first one's pushes, and logging out (§3.1, "delete fcm_token") is
-- `delete ... where user_id = auth.uid()` rather than a partial overwrite.
create table public.device_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  token      text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

create index device_tokens_user_idx on public.device_tokens (user_id);

create trigger device_tokens_set_updated_at
  before update on public.device_tokens
  for each row execute function public.set_updated_at();

-- ── In-app notifications ───────────────────────────────────────────────────
-- Written by the Edge Function (service role), read and dismissed by their
-- owner. Distinct from circle_events: those are the *feed*, this is the
-- per-user *inbox* of what the server decided to deliver to them.
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  -- Free text rather than an enum: this table carries circle events,
  -- suggestion activity and reminder outcomes, and a reminder has no
  -- circle_event_type. The app parses nothing from it — `deep_link` is
  -- what routes (§8.2, "Tap -> deep-link to that book").
  kind       text not null check (char_length(kind) between 1 and 64),
  title      text not null check (char_length(title) between 1 and 200),
  body       text not null check (char_length(body) between 1 and 500),
  deep_link  text,
  event_id   uuid references public.circle_events (id) on delete set null,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_inbox_idx
  on public.notifications (user_id, created_at desc);

-- ── Gemini conversations ───────────────────────────────────────────────────
-- Scoped by nullable chapter_id / link_id exactly like reading_notes: a
-- chat about Chapter 6 belongs to Chapter 6, a chat about the whole book
-- has both null (§7). Kept private to their owner — §7: "conversations
-- persisted / private."
--
-- The reader's GEMINI key is NOT here and must never be: it lives only in
-- Flutter Secure Storage on the device and travels only in an
-- `x-goog-api-key` header direct to Google. There is no server proxy
-- (Phase 3 decision), so nothing in this schema has any reason to hold it.
create table public.ai_chats (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  book_id    uuid not null references public.books (id) on delete cascade,
  chapter_id uuid references public.chapters (id) on delete cascade,
  link_id    uuid references public.book_links (id) on delete cascade,
  title      text check (title is null or char_length(title) <= 200),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ai_chats_one_scope check (num_nonnulls(chapter_id, link_id) <= 1)
);

create index ai_chats_user_book_idx on public.ai_chats (user_id, book_id);

create trigger ai_chats_set_updated_at
  before update on public.ai_chats
  for each row execute function public.set_updated_at();

create table public.ai_messages (
  id         uuid primary key default gen_random_uuid(),
  chat_id    uuid not null references public.ai_chats (id) on delete cascade,
  role       text not null check (role in ('user', 'model')),
  content    text not null,
  -- Search-grounding citations from the Gemini response (§7). Persisted
  -- because the transcript is the only record of *why* the model said
  -- something, and regenerating it later would be a different answer.
  sources    jsonb,
  created_at timestamptz not null default now()
);

create index ai_messages_chat_idx on public.ai_messages (chat_id, id);

-- The 20-message window (§7) is a read-side concern: the repository selects
-- the last 20. Trimming here instead would destroy the conversation rather
-- than shorten its context.
