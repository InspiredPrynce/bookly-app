-- Bookly · Phase 0 · foundation
-- Default privileges (PLAN.md §2.7).
--
-- ## Why this file exists
--
-- 20261005000009_rls.sql revokes `anon` from the sixteen tables that existed
-- when it ran. It could not revoke what did not exist yet.
--
-- Supabase's default ACLs in `public` grant, to every object created from
-- here on:
--
--   tables ....... `anon = arwdDxtm/postgres`  (select, insert, update,
--                                               delete, truncate, references,
--                                               trigger)
--   functions .... `anon = X/postgres`          (execute)
--   sequences .... `anon = rwU/postgres`
--
-- So any table a later migration forgets to revoke would land already
-- readable by an anonymous client, and would depend entirely on nobody
-- writing a `to anon` policy to stay closed. Bookly has no anonymous
-- surface at all — the first screen after splash is /login or /catalog, and
-- the catalog is a *reader's* catalog — so those grants should never exist
-- in the first place rather than be chased down table by table.
--
-- Scoping the statement `for role postgres` matters: `supabase_admin` owns a
-- second set of default ACLs in this schema, and neither this migration nor
-- any other in this repo creates objects as that role.
--
-- ## Trigger functions, and why anon keeps showing up as `EXECUTE = true`
--
-- The `revoke execute ... from anon` list below drops anon's *explicit*
-- grant from each trigger function. It does not drop anon's access.
-- PostgreSQL ACLs are additive, every role belongs to `PUBLIC`, and these
-- functions still carry `=X/postgres`. So `has_function_privilege('anon',
-- ...)` keeps returning true — by design, not oversight.
--
-- That is the right end state, for a reason that was verified against this
-- database rather than assumed:
--
--     select public.handle_new_user();
--     ERROR: trigger functions can only be called as triggers
--
-- None of these can be invoked as a plain function at all, so there is
-- nothing here for an anonymous caller to reach. Revoking from `PUBLIC`
-- would close a hole that does not exist while endangering the roles that
-- must keep firing these triggers: `supabase_auth_admin` for
-- `handle_new_user()` on `auth.users`, `dashboard_user` for table edits,
-- and authenticated / service_role / postgres for everything else.
--
-- The explicit revoke still earns its lines: it records which roles the
-- function is actually *for*, so a later hardening pass has a correct
-- starting point instead of guessing.

alter default privileges for role postgres in schema public
  revoke all on tables    from anon;
alter default privileges for role postgres in schema public
  revoke all on functions from anon;
alter default privileges for role postgres in schema public
  revoke all on sequences from anon;

revoke execute on function public.emit_on_contribution      from anon;
revoke execute on function public.emit_on_item_progress     from anon;
revoke execute on function public.emit_on_member_joined     from anon;
revoke execute on function public.emit_on_reading_progress  from anon;
revoke execute on function public.guard_last_owner          from anon;
revoke execute on function public.guard_member_update       from anon;
revoke execute on function public.handle_new_user           from anon;
revoke execute on function public.on_reading_progress_write from anon;
revoke execute on function public.seed_book_circle          from anon;
revoke execute on function public.set_updated_at            from anon;
revoke execute on function public.rls_auto_enable           from anon;
