/// Where the reader has got to with one chapter or one link —
/// PLAN.md §2.2's `item_status`, and §5.7's row statuses.
///
/// Three values, matching the column exactly, including the one that is
/// never written. `not_started` is what the *absence* of a row means, so
/// no insert ever carries it; it exists here so a screen can say it out
/// loud rather than inferring it from an empty map.
///
/// Its own file because Bookly puts every enum in one (PLAN.md §0.1).
enum ItemStatus {
  /// No row. The column's default, and this app's most common value.
  notStarted,

  /// Opened, not finished — §5.7's "Open" transition.
  reading,

  /// Done. Terminal: see `ProgressRepository` on why this one never
  /// moves backwards.
  finished;

  /// The value the `item_status` column holds.
  ///
  /// Spelled out rather than taken from [name] because `notStarted` and
  /// `not_started` differ for a reason neither side can concede: the
  /// enum member was named before Postgres was told about it, and an
  /// alias that has to be remembered on both ends is exactly the kind
  /// of thing §5.6's derived-rule argument warns about.
  String get dbValue => switch (this) {
        ItemStatus.notStarted => 'not_started',
        ItemStatus.reading => 'reading',
        ItemStatus.finished => 'finished',
      };

  /// Reads the column back.
  ///
  /// An unrecognised value falls back to [notStarted] rather than
  /// throwing. A status the app has never heard of is a row the reader
  /// has not touched as far as this build can tell, and refusing to
  /// render a book because the database is a version ahead would be a
  /// worse answer than showing it as new.
  static ItemStatus fromDb(String? value) => switch (value) {
        'reading' => ItemStatus.reading,
        'finished' => ItemStatus.finished,
        _ => ItemStatus.notStarted,
      };
}
