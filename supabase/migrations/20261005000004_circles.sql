-- Bookly · Phase 0 · foundation
-- Circles and membership (PLAN.md §6.1–6.3).
--
-- "A circle exists the moment a book does." There is no create-circle
-- button, so there is no insert policy for circles either: a trigger seeds
-- one, along with the creator's owner membership, in the same transaction
-- that creates the book. A client that could write circles would be a
-- client that could leave a book with no circle.

create table public.circles (
  id          uuid primary key default gen_random_uuid(),
  book_id     uuid not null unique references public.books (id) on delete cascade,
  -- PLAN.md §6.1: `approval` is the default, and the book's creator may
  -- switch it to `open`.
  join_policy circle_join_policy not null default 'approval',
  created_at  timestamptz not null default now()
);

create table public.circle_members (
  id          uuid primary key default gen_random_uuid(),
  circle_id   uuid not null references public.circles (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  role        member_role not null default 'member',
  status      member_status not null default 'invited',
  -- Insert-time, and never rewritten: PLAN.md §6.3 assigns identity colours
  -- "server-side by joined_at ... so ordering is deterministic under
  -- races", and §6.1 keeps the row after a member leaves so their
  -- contributions keep their authorship. Both only work if this is stable.
  joined_at   timestamptz not null default now(),
  -- NULL means the member inserted the row themselves — a request to join
  -- under an `approval` policy (§6.2). A row with an `invited_by` is one
  -- an owner invited. Both start at `invited` and become `active` on
  -- approval; both end at `left`. The status enum has no `pending`, and
  -- adding one would contradict §2.1's final set.
  invited_by  uuid references public.profiles (id) on delete set null,
  unique (circle_id, user_id)
);

create index circle_members_user_idx on public.circle_members (user_id, status);
create index circle_members_circle_idx on public.circle_members (circle_id, status);

-- ── Seed on book creation ──────────────────────────────────────────────────
create or replace function public.seed_book_circle()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_circle_id uuid;
begin
  insert into public.circles (book_id)
  values (new.id)
  returning id into v_circle_id;

  insert into public.circle_members (circle_id, user_id, role, status)
  values (v_circle_id, new.created_by, 'owner', 'active');

  return new;
end;
$$;

create trigger books_seed_circle
  after insert on public.books
  for each row execute function public.seed_book_circle();

-- ── The owner cannot walk away ─────────────────────────────────────────────
-- PLAN.md §6.1: "Owner cannot leave without transferring ownership or
-- deleting the book." Deleting the book cascades the circle away; this
-- guard covers the other case — including the quieter version of it, an
-- owner demoting themselves to member while nobody else holds the role.
--
-- SECURITY DEFINER so the "is anyone else an owner?" lookup sees the whole
-- circle regardless of which member row the caller is writing.
create or replace function public.guard_last_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.role = 'owner'
     and (new.role <> 'owner' or new.status <> 'active')
     and not exists (
       select 1
       from public.circle_members
       where circle_id = old.circle_id
         and role = 'owner'
         and status = 'active'
         and id <> old.id
     ) then
    raise exception 'Transfer ownership before leaving the circle';
  end if;

  return new;
end;
$$;

create trigger circle_members_guard_last_owner
  before update on public.circle_members
  for each row execute function public.guard_last_owner();

-- ── What a member may change about themselves ──────────────────────────────
-- The UPDATE policy in 20261005000009 lets an active member write their own
-- row, and a `with check` clause cannot reference OLD — so there is no way
-- to express "you may change your status, but not your role" in a policy.
-- A trigger is the only place that rule fits.
--
-- `joined_at` is frozen outright. §6.3 assigns identity colours by it, and
-- a member editing their own join time would be choosing where in the
-- colour order they sit — which is exactly the race that assignment exists
-- to settle.
create or replace function public.guard_member_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.joined_at <> old.joined_at then
    raise exception 'joined_at is assigned, not chosen';
  end if;

  if new.circle_id <> old.circle_id then
    raise exception 'A membership cannot be moved between circles';
  end if;

  if new.role <> old.role and not public.is_circle_owner(old.circle_id) then
    raise exception 'Only a circle owner can change roles';
  end if;

  if new.user_id <> old.user_id then
    raise exception 'A membership cannot be reassigned';
  end if;

  return new;
end;
$$;

create trigger circle_members_guard_member_update
  before update on public.circle_members
  for each row execute function public.guard_member_update();

-- ── Membership predicates used by RLS ──────────────────────────────────────
-- These are SECURITY DEFINER on purpose. The obvious way to write
-- "is the caller an active member of this circle?" is a subquery against
-- circle_members inside the circle_members policy itself — and that is
-- infinite recursion, which Postgres reports as an error rather than
-- something you can work around. Taking the lookup outside RLS here is what
-- lets the policies below be readable.

create or replace function public.is_active_member(p_circle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.circle_members
    where circle_id = p_circle_id
      and user_id = auth.uid()
      and status = 'active'
  );
$$;

create or replace function public.is_circle_owner(p_circle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.circle_members
    where circle_id = p_circle_id
      and user_id = auth.uid()
      and status = 'active'
      and role = 'owner'
  );
$$;

create or replace function public.book_circle_id(p_book_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.circles where book_id = p_book_id;
$$;

create or replace function public.is_active_member_of_book(p_book_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_active_member(public.book_circle_id(p_book_id));
$$;

-- ── Identity colours ───────────────────────────────────────────────────────
-- PLAN.md §6.3: six colours in join order, assigned server-side. The client
-- owns the palette (it lives with the design tokens); the server owns the
-- ordering, because two members joining within the same millisecond would
-- otherwise race for whichever colour the client happened to pick first.
--
-- Ranked over *every* row in the circle, including members who have left.
-- §6.1 keeps a departed member's rows so their contributions keep their
-- authorship, and those contributions render with a member colour — a
-- colour that reshuffled when they walked out would retroactively change
-- who wrote what.
create or replace function public.circle_member_colors(p_circle_id uuid)
returns table (user_id uuid, color_index integer)
language sql
stable
security definer
set search_path = public
as $$
  select m.user_id,
         (row_number() over (order by m.joined_at, m.id) - 1)::integer
  from public.circle_members m
  where m.circle_id = p_circle_id
    and public.is_active_member(p_circle_id)
  order by m.joined_at, m.id;
$$;

revoke all on function public.circle_member_colors(uuid) from public, anon;
grant execute on function public.circle_member_colors(uuid) to authenticated;
