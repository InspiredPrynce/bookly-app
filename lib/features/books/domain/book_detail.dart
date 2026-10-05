import 'book.dart';
import 'book_link.dart';
import 'chapter.dart';

/// One book together with the chapters and links hanging off it — the
/// read side of PLAN.md §5.1.
///
/// The write side deliberately has no equivalent: `create` takes the
/// pieces because it builds them. This exists because §5.7 describes
/// *one* surface with two branches — the chapter list and the link list
/// are not two screens — so a caller fetching them separately would be
/// assembling that surface itself, three times over, with three
/// moments of truth between them: a cover could change under a list
/// that had not arrived yet, and a failure on the third request would
/// leave half a book on screen with no way to say which half.
///
/// ## Why there is no `format` field (§5.6)
///
/// What kind of book this is lives in [hasChapters] and [hasLinks],
/// derived from the two lists that are already here. A stored format
/// drifts the moment someone adds a link to a chapter book; a derived
/// rule cannot — which is §5.6's entire argument, honoured by not
/// writing the column down anywhere.
class BookDetail {
  const BookDetail({
    required this.book,
    required this.chapters,
    required this.links,
  });

  final Book book;

  /// Ascending by `position` — the order the reader walks them, and
  /// the same order `item_progress` rows are keyed against.
  final List<Chapter> chapters;

  /// Ascending by `position`, §5.2's reorder key.
  final List<BookLink> links;

  /// §5.6's chapter-based branch: this book has something to read.
  bool get hasChapters => chapters.isNotEmpty;

  /// §5.6's link-based branch: this book has things to watch or listen
  /// to.
  bool get hasLinks => links.isNotEmpty;

  /// Nothing to read and only things to watch or listen to.
  ///
  /// §5.7 makes this the case where `BookDetailScreen` *is* the
  /// consumption surface — a `ReadingScreen` would be empty, because
  /// there is nothing to read.
  bool get isLinkOnly => links.isNotEmpty && chapters.isEmpty;
}
