/// A book someone created (PLAN.md §5.1).
///
/// Books are user-created and never admin-seeded, which is why
/// [createdBy] is a real field and not decoration: it is what the RLS
/// policies on `chapters` and `book_links` check when deciding whether
/// this reader may edit them, and it is what makes "my books" a query
/// rather than a guess.
///
/// No `format` field (§5.6). Whether a book is chapter-based, link-based
/// or hybrid is *derived* from its chapter and link counts — a stored
/// enum drifts the moment someone adds a link to a chapter book, and a
/// derived rule cannot. Those counts are not on this model either: they
/// are queries, and adding them here would mean every row carried two
/// aggregates it does not own.
class Book {
  const Book({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.authors,
    this.about,
    this.coverPath,
    this.coverUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String createdBy;

  final String title;

  /// `text[]`, and never collapsed into a single string: an author list
  /// with more than one entry is the common case, and joining them at
  /// the model boundary would make it impossible to ever treat them
  /// separately again.
  final List<String> authors;

  /// Nullable — §5.1 lists it as an optional part of the form.
  final String? about;

  /// Stored path (what the row holds; storage policies authorise a path).
  final String? coverPath;

  /// Derived for display. Kept beside the path rather than computed by
  /// every widget that wants to draw a cover.
  final String? coverUrl;

  final DateTime createdAt;
  final DateTime updatedAt;
}
