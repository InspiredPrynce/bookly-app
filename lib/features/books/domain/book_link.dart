import 'link_kind.dart';

/// One YouTube or podcast link attached to a book (PLAN.md §5.2).
///
/// A book with zero chapters and at least one of these is a *link-only*
/// book, and §5.7 makes its `BookDetailScreen` the consumption surface —
/// there is no `ReadingScreen` to show, because there is nothing to
/// read.
///
/// There is no `Book` object hanging off this: links are read by
/// `book_id`, and the caller already knows which book it asked about.
class BookLink {
  const BookLink({
    required this.id,
    required this.bookId,
    required this.kind,
    required this.title,
    required this.url,
    required this.position,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final LinkKind kind;
  final String title;
  final String url;

  /// 1-based, unique within its book, and **the reorder key** — §5.2
  /// names it as such. Reordering rewrites positions; it never rewrites
  /// `id`, because progress and notes point at rows, not at orderings.
  final int position;

  final DateTime createdAt;
}
