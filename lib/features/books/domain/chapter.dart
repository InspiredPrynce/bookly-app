/// One chapter of a book (PLAN.md §5.1).
///
/// `content` is nullable and is *not* where a book lives: §5.1 is
/// explicit that full book text is not required in the app, and that
/// what Bookly holds is metadata plus the reader's own notes. Whatever
/// content exists is whatever the creator chose to attach.
///
/// There is also deliberately no `Book` object hanging off this —
/// chapters are read by `book_id`, and owning a whole book here would
/// make every chapter-list query carry a book it already has.
class Chapter {
  const Chapter({
    required this.id,
    required this.bookId,
    required this.position,
    required this.title,
    this.content,
  });

  final String id;
  final String bookId;

  /// 1-based, and unique within its book (`unique (book_id, position)`).
  /// This is the order the reader walks and the key [item_progress]
  /// rows are written against.
  final int position;

  final String title;
  final String? content;
}
