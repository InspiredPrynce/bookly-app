-- Bookly · Phase 0 · foundation
-- RLS performance (PLAN.md §2.7), after a pass against the
-- supabase-postgres-best-practices and postgres-patterns skills.
--
-- ## Part A · index every foreign key  [schema-foreign-key-indexes, HIGH]
--
-- PostgreSQL does not index foreign keys. An unindexed FK turns both JOINs
-- and ON DELETE CASCADE into a sequential scan of the referencing table —
-- the rule rates it 10-100x. Ten FK columns were bare:
--
--   ai_chats.chapter_id / link_id          book_contributions.chapter_id / link_id
--   circle_events.book_id / chapter_id / link_id
--   circle_members.invited_by             notifications.event_id
--   reading_progress.current_chapter_id
--
-- The nullable ones are indexed partially (WHERE ... IS NOT NULL), matching
-- the convention already in this schema (reading_notes_chapter_uidx,
-- item_progress_user_chapter_uidx, ...) so the index covers only rows that
-- can actually match. A NOT NULL column gets a plain index: a constant-true
-- partial predicate would only risk the planner failing to match it.
--
-- The RLS policies themselves were already covered — every table carrying a
-- non-trivial qualifier has at least one supporting index, and
-- books.created_by, circle_members(user_id, status), circle_events(circle_id,
-- created_at DESC) and the rest were indexed in 20261005000003-000006.
--
-- ## Part B · wrap auth.uid() in a subquery  [security-rls-performance, HIGH]
--
-- The rule, verbatim:
--
--     -- incorrect: auth.uid() called per row
--     create policy ... using (auth.uid() = user_id);
--     -- correct: called once, cached
--     create policy ... using ((select auth.uid()) = user_id);
--
-- auth.uid() is a STABLE function reading request.jwt.claim.sub. In a policy
-- qualifier PostgreSQL re-evaluates it for every row it inspects, so a
-- reader with 5 000 notes calls it 5 000 times to answer one query.
-- Wrapping it makes the expression uncorrelated, which lets the planner
-- hoist it into an InitPlan: evaluated once for the whole statement.
--
-- All 39 policies using a bare auth.uid() are rewritten below; the other
-- seven use `true` or a row-correlated call such as is_active_member(x),
-- where there is nothing to hoist — the argument varies per row, so
-- `select`-wrapping would change the plan shape without saving a call.
--
-- This is a performance edit only. Every expression below is the one
-- already live, with auth.uid() -> (select auth.uid()) substituted; no
-- predicate, role or command changes, and no policy is added or removed.
-- The file is generated from pg_policies rather than transcribed by hand,
-- so what runs is exactly what was reviewed.


-- ── Part A · foreign key indexes ─────────────────────────────────────────

create index if not exists ai_chats_chapter_idx
  on public.ai_chats (chapter_id) where chapter_id is not null;
create index if not exists ai_chats_link_idx
  on public.ai_chats (link_id) where link_id is not null;
create index if not exists book_contributions_chapter_idx
  on public.book_contributions (chapter_id) where chapter_id is not null;
create index if not exists book_contributions_link_idx
  on public.book_contributions (link_id) where link_id is not null;
create index if not exists circle_events_book_idx
  on public.circle_events (book_id) where book_id is not null;
create index if not exists circle_events_chapter_idx
  on public.circle_events (chapter_id) where chapter_id is not null;
create index if not exists circle_events_link_idx
  on public.circle_events (link_id) where link_id is not null;
create index if not exists circle_members_invited_by_idx
  on public.circle_members (invited_by) where invited_by is not null;
create index if not exists notifications_event_idx
  on public.notifications (event_id) where event_id is not null;
create index if not exists reading_progress_chapter_idx
  on public.reading_progress (current_chapter_id) where current_chapter_id is not null;

-- ── Part B · RLS policies, auth.uid() wrapped ───────────────────────────

drop policy if exists "chats are deleted by their owner" on public.ai_chats;
create policy "chats are deleted by their owner"
  on public.ai_chats for delete to authenticated
  using ((user_id = (select auth.uid())));

drop policy if exists "chats are edited by their owner" on public.ai_chats;
create policy "chats are edited by their owner"
  on public.ai_chats for update to authenticated
  using ((user_id = (select auth.uid())))
  with check ((user_id = (select auth.uid())));

drop policy if exists "chats are read by their owner" on public.ai_chats;
create policy "chats are read by their owner"
  on public.ai_chats for select to authenticated
  using ((user_id = (select auth.uid())));

drop policy if exists "chats are started by their owner" on public.ai_chats;
create policy "chats are started by their owner"
  on public.ai_chats for insert to authenticated
  with check ((user_id = (select auth.uid())));

drop policy if exists "chat messages are deleted with their chat" on public.ai_messages;
create policy "chat messages are deleted with their chat"
  on public.ai_messages for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM ai_chats c
  WHERE ((c.id = ai_messages.chat_id) AND (c.user_id = (select auth.uid()))))));

drop policy if exists "chat messages are read with their chat" on public.ai_messages;
create policy "chat messages are read with their chat"
  on public.ai_messages for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM ai_chats c
  WHERE ((c.id = ai_messages.chat_id) AND (c.user_id = (select auth.uid()))))));

drop policy if exists "chat messages are written to their own chat" on public.ai_messages;
create policy "chat messages are written to their own chat"
  on public.ai_messages for insert to authenticated
  with check ((EXISTS ( SELECT 1
   FROM ai_chats c
  WHERE ((c.id = ai_messages.chat_id) AND (c.user_id = (select auth.uid()))))));

drop policy if exists "shared notes are deleted by their author" on public.book_contributions;
create policy "shared notes are deleted by their author"
  on public.book_contributions for delete to authenticated
  using ((user_id = (select auth.uid())));

drop policy if exists "shared notes are edited by their author" on public.book_contributions;
create policy "shared notes are edited by their author"
  on public.book_contributions for update to authenticated
  using ((user_id = (select auth.uid())))
  with check ((user_id = (select auth.uid())));

drop policy if exists "shared notes are written by their author" on public.book_contributions;
create policy "shared notes are written by their author"
  on public.book_contributions for insert to authenticated
  with check ((user_id = (select auth.uid())));

drop policy if exists "links are managed by their book's creator" on public.book_links;
create policy "links are managed by their book's creator"
  on public.book_links for all to authenticated
  using ((EXISTS ( SELECT 1
   FROM books b
  WHERE ((b.id = book_links.book_id) AND (b.created_by = (select auth.uid()))))))
  with check ((EXISTS ( SELECT 1
   FROM books b
  WHERE ((b.id = book_links.book_id) AND (b.created_by = (select auth.uid()))))));

drop policy if exists "a suggestion is answered by its recipient" on public.book_suggestions;
create policy "a suggestion is answered by its recipient"
  on public.book_suggestions for update to authenticated
  using ((recipient_id = (select auth.uid())))
  with check ((recipient_id = (select auth.uid())));

drop policy if exists "a suggestion is read by its sender and its recipient" on public.book_suggestions;
create policy "a suggestion is read by its sender and its recipient"
  on public.book_suggestions for select to authenticated
  using (((sender_id = (select auth.uid())) OR (recipient_id = (select auth.uid()))));

drop policy if exists "a suggestion is sent as its sender" on public.book_suggestions;
create policy "a suggestion is sent as its sender"
  on public.book_suggestions for insert to authenticated
  with check ((sender_id = (select auth.uid())));

drop policy if exists "a suggestion is withdrawn by its sender" on public.book_suggestions;
create policy "a suggestion is withdrawn by its sender"
  on public.book_suggestions for delete to authenticated
  using ((sender_id = (select auth.uid())));

drop policy if exists "a book is created by its creator" on public.books;
create policy "a book is created by its creator"
  on public.books for insert to authenticated
  with check ((created_by = (select auth.uid())));

drop policy if exists "a book is deleted by its creator" on public.books;
create policy "a book is deleted by its creator"
  on public.books for delete to authenticated
  using ((created_by = (select auth.uid())));

drop policy if exists "a book is managed by its creator" on public.books;
create policy "a book is managed by its creator"
  on public.books for update to authenticated
  using ((created_by = (select auth.uid())))
  with check ((created_by = (select auth.uid())));

drop policy if exists "chapters are managed by their book's creator" on public.chapters;
create policy "chapters are managed by their book's creator"
  on public.chapters for all to authenticated
  using ((EXISTS ( SELECT 1
   FROM books b
  WHERE ((b.id = chapters.book_id) AND (b.created_by = (select auth.uid()))))))
  with check ((EXISTS ( SELECT 1
   FROM books b
  WHERE ((b.id = chapters.book_id) AND (b.created_by = (select auth.uid()))))));

drop policy if exists "a circle's membership is read by its own members" on public.circle_members;
create policy "a circle's membership is read by its own members"
  on public.circle_members for select to authenticated
  using (((user_id = (select auth.uid())) OR is_active_member(circle_id)));

drop policy if exists "a circle's membership is updated by the member themselves or by" on public.circle_members;
create policy "a circle's membership is updated by the member themselves or by"
  on public.circle_members for update to authenticated
  using (((user_id = (select auth.uid())) OR is_circle_owner(circle_id)))
  with check (((user_id = (select auth.uid())) OR is_circle_owner(circle_id)));

drop policy if exists "a circle's membership is written by the member themselves or by" on public.circle_members;
create policy "a circle's membership is written by the member themselves or by"
  on public.circle_members for insert to authenticated
  with check (((user_id = (select auth.uid())) OR is_circle_owner(circle_id)));

drop policy if exists "a circle's join policy is set by its book's creator" on public.circles;
create policy "a circle's join policy is set by its book's creator"
  on public.circles for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM books b
  WHERE ((b.id = circles.book_id) AND (b.created_by = (select auth.uid()))))))
  with check ((EXISTS ( SELECT 1
   FROM books b
  WHERE ((b.id = circles.book_id) AND (b.created_by = (select auth.uid()))))));

drop policy if exists "device tokens are refreshed by their owner" on public.device_tokens;
create policy "device tokens are refreshed by their owner"
  on public.device_tokens for update to authenticated
  using ((user_id = (select auth.uid())))
  with check ((user_id = (select auth.uid())));

drop policy if exists "device tokens are registered by their owner" on public.device_tokens;
create policy "device tokens are registered by their owner"
  on public.device_tokens for insert to authenticated
  with check ((user_id = (select auth.uid())));

drop policy if exists "device tokens are their owner's alone" on public.device_tokens;
create policy "device tokens are their owner's alone"
  on public.device_tokens for select to authenticated
  using ((user_id = (select auth.uid())));

drop policy if exists "device tokens are withdrawn by their owner" on public.device_tokens;
create policy "device tokens are withdrawn by their owner"
  on public.device_tokens for delete to authenticated
  using ((user_id = (select auth.uid())));

drop policy if exists "item progress is read by its owner and their circle" on public.item_progress;
create policy "item progress is read by its owner and their circle"
  on public.item_progress for select to authenticated
  using (((user_id = (select auth.uid())) OR is_active_member_of_book(book_id)));

drop policy if exists "item progress is written by its owner" on public.item_progress;
create policy "item progress is written by its owner"
  on public.item_progress for all to authenticated
  using ((user_id = (select auth.uid())))
  with check ((user_id = (select auth.uid())));

drop policy if exists "notifications are cleared by their recipient" on public.notifications;
create policy "notifications are cleared by their recipient"
  on public.notifications for delete to authenticated
  using ((user_id = (select auth.uid())));

drop policy if exists "notifications are marked read by their recipient" on public.notifications;
create policy "notifications are marked read by their recipient"
  on public.notifications for update to authenticated
  using ((user_id = (select auth.uid())))
  with check ((user_id = (select auth.uid())));

drop policy if exists "notifications are read by their recipient" on public.notifications;
create policy "notifications are read by their recipient"
  on public.notifications for select to authenticated
  using ((user_id = (select auth.uid())));

drop policy if exists "profiles are edited by their owner" on public.profiles;
create policy "profiles are edited by their owner"
  on public.profiles for update to authenticated
  using ((id = (select auth.uid())))
  with check ((id = (select auth.uid())));

drop policy if exists "notes are deleted by their owner" on public.reading_notes;
create policy "notes are deleted by their owner"
  on public.reading_notes for delete to authenticated
  using ((user_id = (select auth.uid())));

drop policy if exists "notes are edited by their owner" on public.reading_notes;
create policy "notes are edited by their owner"
  on public.reading_notes for update to authenticated
  using ((user_id = (select auth.uid())))
  with check ((user_id = (select auth.uid())));

drop policy if exists "notes are read by their owner" on public.reading_notes;
create policy "notes are read by their owner"
  on public.reading_notes for select to authenticated
  using ((user_id = (select auth.uid())));

drop policy if exists "notes are written by their owner" on public.reading_notes;
create policy "notes are written by their owner"
  on public.reading_notes for insert to authenticated
  with check ((user_id = (select auth.uid())));

drop policy if exists "reading position is read by its owner and their circle" on public.reading_progress;
create policy "reading position is read by its owner and their circle"
  on public.reading_progress for select to authenticated
  using (((user_id = (select auth.uid())) OR is_active_member_of_book(book_id)));

drop policy if exists "reading position is written by its owner" on public.reading_progress;
create policy "reading position is written by its owner"
  on public.reading_progress for all to authenticated
  using ((user_id = (select auth.uid())))
  with check ((user_id = (select auth.uid())));

