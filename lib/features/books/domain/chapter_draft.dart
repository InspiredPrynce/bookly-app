/// A chapter as it exists before it has a row (PLAN.md §5.1).
///
/// The create screen holds a list of these, reorders them, and hands the
/// list to [BookRepository] only when the reader saves — positions are
/// assigned there, from the final order, because a position invented for
/// a row that was never inserted is a gap waiting to collide with
/// `unique (book_id, position)`.
///
/// ## Why `key` exists
///
/// Local identity, never written to Postgres. A row's *content* can be
/// edited and its *position* can change, so neither identifies it; the
/// `TextField` bound to a title has to stay attached to the title it is
/// editing while the list moves underneath it, and only a stable key
/// does that. It is the counterexample to "fields the database has" —
/// it exists because the UI has a problem the schema does not.
class ChapterDraft {
  const ChapterDraft({required this.key, required this.title});

  /// Stable and local. Assigned by the screen, monotonic, never reused.
  final int key;

  /// Untouched raw text. Trimming happens on save, so the reader does
  /// not watch a trailing space they typed disappear beneath the caret.
  final String title;

  ChapterDraft copyWith({String? title}) => ChapterDraft(
        key: key,
        title: title ?? this.title,
      );
}
