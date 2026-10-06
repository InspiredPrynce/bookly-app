import 'book_progress.dart';
import 'item_status.dart';

/// Reading position for chapters and links (PLAN.md §5.4, §5.7).
///
/// Position only — there is no elapsed time anywhere in this interface
/// because §5.4 rules a reading timer out, and a method that returned
/// one would be a promise the schema cannot keep.
///
/// ## What the four writes return
///
/// Each returns the status the row now holds, which is **not always the
/// status that was asked for**. A row already `finished` stays finished
/// when the reader opens it again, so `startLink` on a watched link
/// answers `finished`. The screen must render the repository's answer
/// and not its own request, or a row would claim something the database
/// does not hold — the exact drift §5.6's derived-rule argument is
/// about.
///
/// ## Why four methods and not two
///
/// The *table* is one table for both kinds, and §2.2 says so. The *call
/// site* is never ambiguous: a link row opens a link, a chapter row
/// opens a chapter. Spelling the four out keeps that certainty at the
/// boundary and lets the shared monotonic rule live in one private
/// method behind them — rather than a nullable `chapterId`/`linkId` pair
/// that the compiler cannot check the caller got right. The database's
/// `one_target` constraint can, and would simply reject it.
///
/// It throws a `Failure` with presentable copy — never a raw Postgres
/// payload (§3.2).
abstract interface class ProgressRepository {
  /// Every status this reader has inside [bookId].
  ///
  /// Filtered to the signed-in user on purpose. RLS lets circle members
  /// read each other's rows (§2.7) so the activity feed can show what
  /// others are up to — but this is the *reader's own* progress, and
  /// rendering a colleague's `finished` as theirs would be a lie the
  /// screen has no way to tell apart from the truth.
  Future<BookProgress> load(String bookId);

  /// The reader opened this chapter (§5.7: Open → `reading`).
  Future<ItemStatus> startChapter({
    required String bookId,
    required String chapterId,
  });

  /// The reader marked this chapter finished (§5.7: Mark → `finished`).
  Future<ItemStatus> finishChapter({
    required String bookId,
    required String chapterId,
  });

  /// The reader opened this link (§5.7: "Open writes `item_progress =
  /// reading`").
  Future<ItemStatus> startLink({
    required String bookId,
    required String linkId,
  });

  /// The reader marked this link watched or listened (§5.7: "Mark …
  /// writes `finished`").
  Future<ItemStatus> finishLink({
    required String bookId,
    required String linkId,
  });
}
