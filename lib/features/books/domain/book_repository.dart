import 'dart:typed_data';

import 'book.dart';
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
/// The cover upload therefore lives *inside* [create] for the same
/// reason the avatar upload lives inside `ProfileRepository.update`: a
/// screen that uploads and then forgets to write the row leaves an
/// orphaned object that nothing in the database points at.
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
    required List<ChapterDraft> chapters,
    required List<BookLinkDraft> links,
  });
}
