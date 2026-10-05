-- Bookly · Phase 0 · foundation
-- Storage buckets and their object policies (PLAN.md §3.1, §5.1).
--
-- ## Path convention: the caller's own folder first
--
-- Every object lives at `{auth.uid()}/{whatever}`. That makes ownership a
-- string comparison against the first path segment, which is the only thing
-- storage RLS can check — it has no idea which book a file belongs to, so
-- "may I write this cover?" has to reduce to "is this my folder?".
--
-- ## Public read vs. private read
--
-- `avatars` and `book-covers` are public buckets because the app renders
-- them through plain object URLs in a list, where a per-request signed URL
-- would mean a token refresh per cover. They contain a photo and a piece of
-- cover art — if someone guesses a path, that is the whole exposure.
--
-- `book-uploads` is NOT public: it holds a PDF or EPUB the reader supplied
-- for their own copy. Reading it is still open to any signed-in account
-- (the book itself is in the public catalog), but the object must not be
-- reachable by a URL that could be pasted to a stranger.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/png', 'image/jpeg', 'image/webp']),
  ('book-covers', 'book-covers', true, 10485760, array['image/png', 'image/jpeg', 'image/webp']),
  ('book-uploads', 'book-uploads', false, 52428800, array['application/pdf', 'application/epub+zip'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ── avatars ────────────────────────────────────────────────────────────────
drop policy if exists "avatars are readable" on storage.objects;
create policy "avatars are readable"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "avatars are written to their owner's folder" on storage.objects;
create policy "avatars are written to their owner's folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars are removed from their owner's folder" on storage.objects;
create policy "avatars are removed from their owner's folder"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── book covers ────────────────────────────────────────────────────────────
-- Same three, one key difference: the creator's folder, not the reader's,
-- because a cover is uploaded while editing a book the caller owns but is
-- then displayed to everyone. Ownership of the *folder* still holds, since
-- the cover is always written by the book's creator (§2.7: books — creator
-- manage).
drop policy if exists "book covers are readable" on storage.objects;
create policy "book covers are readable"
  on storage.objects for select
  using (bucket_id = 'book-covers');

drop policy if exists "book covers are written to their owner's folder" on storage.objects;
create policy "book covers are written to their owner's folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'book-covers'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "book covers are removed from their owner's folder" on storage.objects;
create policy "book covers are removed from their owner's folder"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'book-covers'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── book uploads (PDF / EPUB) ──────────────────────────────────────────────
-- Private bucket: write and delete are confined to the uploader's folder,
-- but reading is open to every signed-in account. The book is in the public
-- catalog (§1.3 visibility option C) and its copy is simply where the
-- reader put it — restricting reads to circle members would break the
-- catalog, and restricting them to the uploader would make every
-- recommendation unreadable.
drop policy if exists "book uploads are readable by signed-in readers" on storage.objects;
create policy "book uploads are readable by signed-in readers"
  on storage.objects for select to authenticated
  using (bucket_id = 'book-uploads');

drop policy if exists "book uploads are written to their owner's folder" on storage.objects;
create policy "book uploads are written to their owner's folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'book-uploads'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "book uploads are removed from their owner's folder" on storage.objects;
create policy "book uploads are removed from their owner's folder"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'book-uploads'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
