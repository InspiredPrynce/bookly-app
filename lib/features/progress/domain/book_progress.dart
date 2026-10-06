import 'package:flutter/foundation.dart';

import 'item_status.dart';

/// Everything the signed-in reader has already done inside one book —
/// their own `item_progress` rows and nobody else's.
///
/// ## Why two maps and not one
///
/// The table stores chapters and links in separate nullable columns,
/// guarded by `one_target`, so there is one id space per item *kind* and
/// no single map could hold both without the reader having to remember
/// which kind an id came from. Keeping them apart also means
/// [chapterStatus] cannot be handed a link id: the name of the method
/// says which list it is asking about, and the type system agrees.
///
/// ## Absence is a value
///
/// A missing id is [ItemStatus.notStarted] — the column's own default,
/// expressed as "no row yet". That is what lets this object be empty
/// while a book is still honest to render, and why no call site has a
/// `null` status to check for.
@immutable
class BookProgress {
  const BookProgress({this.chapters = const {}, this.links = const {}});

  /// chapterId → status.
  final Map<String, ItemStatus> chapters;

  /// linkId → status.
  final Map<String, ItemStatus> links;

  /// A book whose rows have not loaded yet, and a book with nothing done
  /// in it, render identically — which is the point. Both say
  /// `▸ Start ▶`, and a reader should not see a spinner where no answer
  /// is owed yet.
  static const empty = BookProgress();

  ItemStatus chapterStatus(String chapterId) =>
      chapters[chapterId] ?? ItemStatus.notStarted;

  ItemStatus linkStatus(String linkId) =>
      links[linkId] ?? ItemStatus.notStarted;

  /// Links finished, for §5.7's "3 of 7 completed".
  ///
  /// Counted from the rows that exist rather than from the book's total,
  /// because a link nobody has touched has no row — and is correctly not
  /// counted as done. The denominator comes from the book.
  int get finishedLinkCount =>
      links.values.where((s) => s == ItemStatus.finished).length;

  BookProgress withChapter(String chapterId, ItemStatus status) =>
      BookProgress(chapters: {...chapters, chapterId: status}, links: links);

  BookProgress withLink(String linkId, ItemStatus status) =>
      BookProgress(chapters: chapters, links: {...links, linkId: status});
}
