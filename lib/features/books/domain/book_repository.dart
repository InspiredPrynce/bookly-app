import 'dart:typed_data';

import 'book.dart';
import 'book_detail.dart';
import 'book_link_draft.dart';
import 'chapter_draft.dart';

/// Creating a book together with the chapters and links that hang off it
/// (PLAN.md §5.1–5.2).
///
/// Presentation calls this and renders the result (PLAN.md §1.1). It
/// throws a `Failure` with presentable copy — never a raw Postgres or
/// Storage payload (§3.2).
///
/// ## Why one method and not three
///
/// §5.3's rule is about the *whole* book — `chapters >= 1 || links >= 1`
/// — and the reader experiences "create book" as one act, not as three
/// requests that can each succeed or fail independently. Three public
/// methods would push the ordering (row → cover → chapters → links) and
/// its compensation onto every caller, and the second caller would get
/// it slightly different.
///
/// The cover and the optional PDF/EPUB therefore both live *inside*
/// [create] for the same reason the avatar upload lives inside
/// `ProfileRepository.update`: a screen that uploads and then forgets
/// to write the row leaves an orphaned object that nothing in the
/// database points at. For `book-uploads` that was not hypothetical —
/// migration 20261005000012 added `books.upload_path` because the
/// bucket had existed since Phase 0 with nowhere to record its hold.
abstract interface class BookRepository {
  /// Persists the book and everything attached to it.
  ///
  /// [authors] is the parsed list, not the raw comma-separated text the
  /// reader typed — splitting is a presentational convenience, and the
  /// repository's job is the row.
  ///
  /// [chapters] and [links] are drafts; their `position` values are
  /// assigned here from their final order, because `unique (book_id,
  /// position)` means a position invented for a row that was never
  /// inserted is a collision waiting to happen.
  ///
  /// Returns the book as the database now has it, so the caller commits
  /// real values rather than its own guesses.
  Future<Book> create({
    required String title,
    required List<String> authors,
    String? about,
    Uint8List? coverBytes,
    Uint8List? uploadBytes,
    required List<ChapterDraft> chapters,
    required List<BookLinkDraft> links,
  });

  /// Every book in the public catalog (§1.3, option C), newest first.
  ///
  /// A read, not a search: there is no query text because the catalog
  /// is meant to be *browsed* — it is what the reader sees the moment
  /// they sign in, and filtering a shelf you have not looked at yet is
  /// a thing to add when the shelf is long enough to need it.
  ///
  /// Newest first rather than by title: a book someone added this
  /// morning is the one they most want to find, and alphabetising puts
  /// it wherever the letter happens to land.
  Future<List<Book>> all();

  /// One book with everything hanging off it, for the screen that shows
  /// both of §5.7's branches at once.
  ///
  /// One request rather than three, because §5.7 describes *one*
  /// surface. Three round trips would give it three moments of truth: a
  /// cover could change under a chapter list that had not arrived, and
  /// a failure on the third would leave a half-loaded book on screen
  /// with no way to say which half. The database can join this; the
  /// reader should not have to.
  ///
  /// Throws `notFound` — presentable copy, §3.2 — when no such book
  /// exists or RLS declines to show it. Those two are indistinguishable
  /// from outside the database, and deliberately so: telling a reader
  /// "that book exists but you cannot have it" would confirm the
  /// existence of something the policy is meant to keep quiet.
  Future<BookDetail> detail(String bookId);

  /// A short-lived URL that opens the book's own PDF/EPUB — §5.1's
  /// optional upload, for a reader who wants the document rather than
  /// the shelf entry.
  ///
  /// Reads the path rather than the id because that is what the column
  /// holds (`books.upload_path`), and because the file is not part of
  /// [detail]: it is a whole document the reader may never ask for, and
  /// shipping it inside a join that every book screen performs would be
  /// a network cost paid for a tap most readers will not make.
  ///
  /// Short-lived and signed, never a public URL — `book-uploads` is a
  /// private bucket on purpose (migration 000008), and the signature is
  /// minted here, once, for this handoff.
  ///
  /// Throws `unknown` with presentable copy (§3.2) when the file has
  /// been removed or the policy declines — which are again the same
  /// answer from outside.
  Future<String> uploadUrl(String uploadPath);
}
