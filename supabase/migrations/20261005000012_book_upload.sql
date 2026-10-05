-- Bookly · Phase 1 · books
-- Where a book's optional PDF / EPUB lives (PLAN.md §5.1).
--
-- §5.1 lists the upload as part of `BookForm`, and 20261005000008
-- created the private `book-uploads` bucket it goes into — but nothing
-- in the schema ever said which book a given object belonged to.
-- Without this column an upload is an orphan in a private bucket: no
-- query can find it, and the reader can only reach it again if they
-- still happen to have the file on their device. That is the same
-- failure `ProfileRepository.update` is written against — upload, then
-- write the row, or the object has no reference to it anywhere — and
-- it was missing here.
--
-- The file's *kind* is deliberately not a second column. `pdf` and
-- `epub` are already spelled out in this path's extension, and a stored
-- `kind` would drift from it — the same reasoning §5.6 gives for
-- refusing to store the book's format at all. Format is derived.
alter table public.books
  add column upload_path text;
