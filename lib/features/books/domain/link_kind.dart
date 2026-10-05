/// What an individual `book_links` row points at (PLAN.md §5.2).
///
/// Two values, and only two — YouTube and podcast. Bookly deliberately
/// does not classify the open web: the reader says which it is, because
/// a "guess from the URL" helper would be right often enough to be
/// trusted and wrong often enough to file a podcast under YouTube with
/// no visible consequence until someone else reads it.
///
/// This is Bookly's twin of the `public.link_kind` enum (migration
/// 000001). The parallel is worth keeping exact rather than loose: an
/// unknown value on the wire means a row exists that the app cannot
/// label, and [fromDb] is where that would surface.
enum LinkKind {
  youtube('youtube'),
  podcast('podcast');

  const LinkKind(this.dbValue);

  /// The exact spelling `public.link_kind` stores — lower-case, no
  /// punctuation. Not the display label: 'YouTube' and 'youtube' are
  /// different strings and only one of them is in the enum.
  final String dbValue;

  /// As the reader sees it. Upper-cased abbreviations are the brand's,
  /// not Bookly's, so this one casing is deliberate rather than shouted.
  String get label => switch (this) {
        LinkKind.youtube => 'YouTube',
        LinkKind.podcast => 'Podcast',
      };

  /// Parses a value read back from Postgres.
  ///
  /// `public.link_kind` is an enum, so an unknown value cannot arrive
  /// without something upstream having changed the column out from
  /// under the app — which is a bug, not a data condition, and so is
  /// allowed to fail loudly rather than quietly relabel the row.
  static LinkKind fromDb(String value) {
    for (final kind in values) {
      if (kind.dbValue == value) return kind;
    }
    throw StateError('Unknown link kind: $value');
  }
}
