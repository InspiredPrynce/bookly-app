-- Bookly · Phase 0 · foundation
-- Extensions and enum types (PLAN.md §2).
--
-- Every type here is its own `create type` rather than a check constraint
-- because the value sets are load-bearing: `circle_event_type` is written by
-- triggers, read by the activity feed, and pattern-matched by the Edge
-- Function that decides whether to push. A check constraint would let a
-- typo through as a string; an enum makes an unknown event impossible.

-- gen_random_uuid() is core in PostgreSQL 13+, and Supabase projects are
-- well past that — declared only so the default is explicit.
create extension if not exists pgcrypto;

-- ── Reading ────────────────────────────────────────────────────────────────
-- Shared by reading_progress and item_progress: one vocabulary for "where
-- am I in this" across chapters, links and whole books.
create type item_status as enum ('not_started', 'reading', 'finished');

-- Which target a progress/note row points at. Pairs with the one_target
-- check: a row has exactly one of chapter_id or link_id, and the type says
-- which one is authoritative.
create type item_type as enum ('chapter', 'link');

-- ── Catalog ────────────────────────────────────────────────────────────────
-- There is deliberately no `books.format` enum (PLAN.md §5.6): format is
-- derived from chapter_count / link_count, because a stored enum drifts and
-- a derived rule cannot. link_kind only describes an individual link.
create type link_kind as enum ('youtube', 'podcast');

-- ── Circles ────────────────────────────────────────────────────────────────
-- The column is `join_policy`; the type is prefixed so `join_policy
-- join_policy` never has to be written or read.
create type circle_join_policy as enum ('open', 'approval');
create type member_role as enum ('owner', 'member');
create type member_status as enum ('invited', 'active', 'left');

-- ── Activity ───────────────────────────────────────────────────────────────
-- PLAN.md §2.4 — final set of nine.
create type circle_event_type as enum (
  'member_joined',
  'started_reading',
  'finished_book',
  'started_chapter',
  'finished_chapter',
  'started_link',
  'finished_link',
  'posted_summary',
  'milestone'
);

-- ── Social ─────────────────────────────────────────────────────────────────
create type suggestion_status as enum ('pending', 'accepted', 'dismissed');

-- ── Shared helper ──────────────────────────────────────────────────────────
-- Maintained by trigger rather than by the client, because "@updatedAt"
-- supplied by the caller is a claim about when *someone else* last changed
-- a row — it can simply be untrue.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
