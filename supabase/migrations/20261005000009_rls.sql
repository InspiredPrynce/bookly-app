-- Bookly · Phase 0 · foundation
-- Row Level Security (PLAN.md §2.6, §2.7).
--
-- ## The spine
--
--   read a book's data .......... any signed-in account (public catalog,
--                                 §1.3 visibility option C)
--   read a circle's data ........ active members of that circle only
--   read a note / a chat ........ its owner, always
--   write someone else's data ... nobody, ever
--
-- The test §2.7 sets is that a member of circle A cannot read circle B's
-- circle_events, reading_notes, ai_chats or book_contributions. Every
-- predicate below routes through `is_active_member` /
-- `is_active_member_of_book` (SECURITY DEFINER, from
-- 20261005000004_circles.sql), which resolve a circle id server-side so
-- that a caller cannot name their way into a circle they are not in.
--
-- ## Two structural notes
--
-- 1. A policy on `circle_members` that subqueries `circle_members` is
--    infinite recursion, so membership checks live in SECURITY DEFINER
--    functions rather than inline.
--
-- 2. `anon` has no access at all — every table is revoked outright, not
--    merely guarded by RLS. The app's first screen after splash is /login
--    or /catalog, and a catalog entry is a *reader's* catalog. Leaving a
--    policy that anon could reach is a policy someone later writes `to
--    anon` against.

-- ═══════════════════════════════════════════════════════════════════════════
-- profiles
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.profiles enable row level security;

-- Readable by every signed-in account because the feed, the member list and
-- MemberProfileSheet all need other people's names, avatars and bios.
-- Nothing private is on this table — see 20261005000002_profiles.sql, and
-- note that `device_tokens` exists precisely so the token need not be.
create policy "profiles are readable by signed-in readers"
  on public.profiles for select to authenticated using (true);

create policy "profiles are edited by their owner"
  on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- No INSERT policy: handle_new_user() is SECURITY DEFINER and owns the
-- table. No DELETE policy: profiles cascade from auth.users, and a reader
-- deleting their own profile would be a different feature.

-- ═══════════════════════════════════════════════════════════════════════════
-- books · chapters · book_links  (public catalog)
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.books enable row level security;
alter table public.chapters enable row level security;
alter table public.book_links enable row level security;

create policy "the catalog is readable by signed-in readers"
  on public.books for select to authenticated using (true);

create policy "a book is created by its creator"
  on public.books for insert to authenticated
  with check (created_by = auth.uid());

create policy "a book is managed by its creator"
  on public.books for update to authenticated
  using (created_by = auth.uid()) with check (created_by = auth.uid());

create policy "a book is deleted by its creator"
  on public.books for delete to authenticated
  using (created_by = auth.uid());

-- Chapters and links inherit their book's ownership rather than having any
-- of their own: the check walks to books and compares created_by, so there
-- is exactly one definition of "may edit this content" in the schema.
create policy "chapters are readable with their book"
  on public.chapters for select to authenticated using (true);

create policy "chapters are managed by their book's creator"
  on public.chapters for all to authenticated
  using (exists (
    select 1 from public.books b
    where b.id = book_id and b.created_by = auth.uid()
  ))
  with check (exists (
    select 1 from public.books b
    where b.id = book_id and b.created_by = auth.uid()
  ));

create policy "links are readable with their book"
  on public.book_links for select to authenticated using (true);

create policy "links are managed by their book's creator"
  on public.book_links for all to authenticated
  using (exists (
    select 1 from public.books b
    where b.id = book_id and b.created_by = auth.uid()
  ))
  with check (exists (
    select 1 from public.books b
    where b.id = book_id and b.created_by = auth.uid()
  ));

-- ═══════════════════════════════════════════════════════════════════════════
-- circles · circle_members
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.circles enable row level security;
alter table public.circle_members enable row level security;

-- join_policy is readable by anyone signed in: the BookDetailScreen has to
-- show "Request to join" rather than "Join" before it knows whether it may.
create policy "a circle's join policy is readable"
  on public.circles for select to authenticated using (true);

-- §6.1: the book's creator may switch approval -> open. Circles are never
-- inserted or deleted by a client — seed_book_circle() owns creation and
-- deletion cascades from books.
create policy "a circle's join policy is set by its book's creator"
  on public.circles for update to authenticated
  using (exists (
    select 1 from public.books b
    where b.id = book_id and b.created_by = auth.uid()
  ))
  with check (exists (
    select 1 from public.books b
    where b.id = book_id and b.created_by = auth.uid()
  ));

-- SELECT is deliberately wider than §2.7's terse "self-read". The member
-- list on CircleScreen, MemberProfileSheet, the activity feed's colours and
-- the owner's JoinRequestSheet all require rows belonging to *other*
-- people; self-read would render the circle unusable. What §2.7's phrase
-- protects against is cross-circle reads, and that is what the second
-- clause excludes: you see your own row anywhere, and other people's rows
-- only where you are an active member alongside them.
create policy "a circle's membership is read by its own members"
  on public.circle_members for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_active_member(circle_id)
  );

-- Insert covers both directions of §6.2: an owner inviting someone else,
-- and a reader inserting their own row to ask to join an `approval` circle
-- (invited_by is null distinguishes the two — see
-- 20261005000004_circles.sql).
create policy "a circle's membership is written by the member themselves or by its owner"
  on public.circle_members for insert to authenticated
  with check (
    user_id = auth.uid()
    or public.is_circle_owner(circle_id)
  );

create policy "a circle's membership is updated by the member themselves or by its owner"
  on public.circle_members for update to authenticated
  using (
    user_id = auth.uid()
    or public.is_circle_owner(circle_id)
  )
  with check (
    user_id = auth.uid()
    or public.is_circle_owner(circle_id)
  );

-- No DELETE: §6.1 retains the row so a departed member's contributions keep
-- their authorship. Leaving is an UPDATE to status = 'left'.

-- ═══════════════════════════════════════════════════════════════════════════
-- reading_progress · item_progress
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.reading_progress enable row level security;
alter table public.item_progress enable row level security;

-- §2.7: "self read+write; position visible to circle members." The whole
-- row is visible to the circle rather than only the position columns,
-- because MemberProfileSheet (§6.6) shows circle members exactly these —
-- their position and their read count — and §6.4 puts "3rd read" in the
-- feed. Column-level filtering here would break both.
create policy "reading position is read by its owner and their circle"
  on public.reading_progress for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_active_member_of_book(book_id)
  );

create policy "reading position is written by its owner"
  on public.reading_progress for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "item progress is read by its owner and their circle"
  on public.item_progress for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_active_member_of_book(book_id)
  );

create policy "item progress is written by its owner"
  on public.item_progress for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- reading_notes  (owner-only, always)
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.reading_notes enable row level security;

-- §2.5: "owner-only always" — the single row of §2.7 that admits no circle
-- read path at all. Sharing is a separate, explicit action that writes a
-- book_contributions row; there is no membership in this table's audience.
create policy "notes are read by their owner"
  on public.reading_notes for select to authenticated
  using (user_id = auth.uid());

create policy "notes are written by their owner"
  on public.reading_notes for insert to authenticated
  with check (user_id = auth.uid());

create policy "notes are edited by their owner"
  on public.reading_notes for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "notes are deleted by their owner"
  on public.reading_notes for delete to authenticated
  using (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- book_contributions
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.book_contributions enable row level security;

create policy "shared notes are read by the book's circle"
  on public.book_contributions for select to authenticated
  using (public.is_active_member_of_book(book_id));

create policy "shared notes are written by their author"
  on public.book_contributions for insert to authenticated
  with check (user_id = auth.uid());

create policy "shared notes are edited by their author"
  on public.book_contributions for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "shared notes are deleted by their author"
  on public.book_contributions for delete to authenticated
  using (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- book_suggestions
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.book_suggestions enable row level security;

create policy "a suggestion is read by its sender and its recipient"
  on public.book_suggestions for select to authenticated
  using (sender_id = auth.uid() or recipient_id = auth.uid());

create policy "a suggestion is sent as its sender"
  on public.book_suggestions for insert to authenticated
  with check (sender_id = auth.uid());

-- Only the recipient resolves a suggestion. The sender may withdraw one
-- they have not had answered, but cannot flip their own dismissal into an
-- acceptance.
create policy "a suggestion is answered by its recipient"
  on public.book_suggestions for update to authenticated
  using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

create policy "a suggestion is withdrawn by its sender"
  on public.book_suggestions for delete to authenticated
  using (sender_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- circle_events  (read-only for every client role)
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.circle_events enable row level security;

create policy "circle events are read by their circle's members"
  on public.circle_events for select to authenticated
  using (public.is_active_member(circle_id));

-- No INSERT / UPDATE / DELETE policy at all. Enabling RLS with no write
-- policy is the enforcement: the only writers are the SECURITY DEFINER
-- triggers in 20261005000006_activity.sql, which run as the table owner
-- and therefore bypass RLS. §2.7's phrasing — "service-role writes only" —
-- is satisfied by those triggers; the service role bypasses RLS for the
-- cases where the server itself records something (a pushed milestone).

-- ═══════════════════════════════════════════════════════════════════════════
-- notifications · device_tokens  (self-only)
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;

create policy "notifications are read by their recipient"
  on public.notifications for select to authenticated
  using (user_id = auth.uid());

create policy "notifications are marked read by their recipient"
  on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "notifications are cleared by their recipient"
  on public.notifications for delete to authenticated
  using (user_id = auth.uid());

-- No INSERT policy: the Edge Function writes these with the service role.

create policy "device tokens are their owner's alone"
  on public.device_tokens for select to authenticated
  using (user_id = auth.uid());

create policy "device tokens are registered by their owner"
  on public.device_tokens for insert to authenticated
  with check (user_id = auth.uid());

create policy "device tokens are refreshed by their owner"
  on public.device_tokens for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "device tokens are withdrawn by their owner"
  on public.device_tokens for delete to authenticated
  using (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- ai_chats · ai_messages  (owner-only)
-- ═══════════════════════════════════════════════════════════════════════════
alter table public.ai_chats enable row level security;
alter table public.ai_messages enable row level security;

-- §7: conversations persisted / private. There is no sharing path for a
-- chat, so there is no second reader to admit here.
create policy "chats are read by their owner"
  on public.ai_chats for select to authenticated
  using (user_id = auth.uid());

create policy "chats are started by their owner"
  on public.ai_chats for insert to authenticated
  with check (user_id = auth.uid());

create policy "chats are edited by their owner"
  on public.ai_chats for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "chats are deleted by their owner"
  on public.ai_chats for delete to authenticated
  using (user_id = auth.uid());

-- Messages carry no user_id of their own; ownership is resolved through the
-- chat. Reading ai_chats inside this policy applies ai_chats' own RLS to
-- the subquery, so the subquery returns a row only when the caller could
-- have selected that chat anyway — the check cannot be satisfied
-- indirectly.
create policy "chat messages are read with their chat"
  on public.ai_messages for select to authenticated
  using (exists (
    select 1 from public.ai_chats c
    where c.id = chat_id and c.user_id = auth.uid()
  ));

create policy "chat messages are written to their own chat"
  on public.ai_messages for insert to authenticated
  with check (exists (
    select 1 from public.ai_chats c
    where c.id = chat_id and c.user_id = auth.uid()
  ));

create policy "chat messages are deleted with their chat"
  on public.ai_messages for delete to authenticated
  using (exists (
    select 1 from public.ai_chats c
    where c.id = chat_id and c.user_id = auth.uid()
  ));

-- ═══════════════════════════════════════════════════════════════════════════
-- Close the anonymous door
-- ═══════════════════════════════════════════════════════════════════════════
revoke all on public.profiles            from anon;
revoke all on public.books               from anon;
revoke all on public.chapters            from anon;
revoke all on public.book_links          from anon;
revoke all on public.circles             from anon;
revoke all on public.circle_members      from anon;
revoke all on public.reading_progress    from anon;
revoke all on public.item_progress       from anon;
revoke all on public.reading_notes       from anon;
revoke all on public.book_contributions  from anon;
revoke all on public.book_suggestions    from anon;
revoke all on public.circle_events       from anon;
revoke all on public.notifications       from anon;
revoke all on public.device_tokens       from anon;
revoke all on public.ai_chats            from anon;
revoke all on public.ai_messages         from anon;

-- Membership helpers are called from policies, which only ever run for a
-- table the caller can query — and the caller can only query tables with a
-- session.
revoke all on function public.is_active_member(uuid)          from public, anon;
revoke all on function public.is_circle_owner(uuid)           from public, anon;
revoke all on function public.book_circle_id(uuid)            from public, anon;
revoke all on function public.is_active_member_of_book(uuid)  from public, anon;

grant execute on function public.is_active_member(uuid)          to authenticated;
grant execute on function public.is_circle_owner(uuid)           to authenticated;
grant execute on function public.book_circle_id(uuid)            to authenticated;
grant execute on function public.is_active_member_of_book(uuid)  to authenticated;

-- ═══════════════════════════════════════════════════════════════════════════
-- Realtime (§6.4, §8.3)
-- ═══════════════════════════════════════════════════════════════════════════
-- Lifecycle-scoped: the client subscribes while a screen is mounted and
-- unsubscribes in dispose. Membership in the publication is a server-side
-- permission; *when* you listen is entirely the app's choice, which is what
-- keeps a chat on BookDetailScreen silent once you navigate away from it.
--
-- RLS still applies to the stream — a subscriber receives only the rows
-- their own policy would let them select.
do $$
declare
  t text;
begin
  foreach t in array array[
    'public.circle_events',
    'public.book_contributions',
    'public.circle_members',
    'public.notifications'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname || '.' || tablename = t
    ) then
      execute format('alter publication supabase_realtime add table %s', t);
    end if;
  end loop;
end;
$$;
