import 'link_kind.dart';

/// A link as it exists before it has a row (PLAN.md §5.2).
///
/// The create screen holds a list of these, reorders them, and hands the
/// list to [BookRepository] only when the reader saves — like
/// `ChapterDraft`, positions are assigned from the final order rather
/// than guessed along the way.
///
/// ## Why `key` exists
///
/// Local identity, never written to Postgres. A row's `url` and `title`
/// are both editable and its `position` is both editable and the reorder
/// key, so no stored field identifies a row while it is being edited.
/// The `TextField` bound to a title must stay attached to *that* title
/// while the list moves underneath it, and a stable local key is the
/// only thing here that does not change.
class BookLinkDraft {
  const BookLinkDraft({
    required this.key,
    required this.kind,
    required this.title,
    required this.url,
  });

  /// Stable and local. Assigned by the screen, monotonic, never reused.
  final int key;

  final LinkKind kind;

  /// Untouched raw text — trimmed on save.
  final String title;
  final String url;

  BookLinkDraft copyWith({LinkKind? kind, String? title, String? url}) =>
      BookLinkDraft(
        key: key,
        kind: kind ?? this.kind,
        title: title ?? this.title,
        url: url ?? this.url,
      );
}
