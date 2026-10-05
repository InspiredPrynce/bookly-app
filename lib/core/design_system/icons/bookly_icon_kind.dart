/// Every Lucide glyph Bookly knows how to draw.
///
/// One member per file, per PLAN.md §0.1. The value is the upstream Lucide
/// filename under `assets/icons/lucide/`, so adding an icon is one line here
/// plus the `.svg` beside its neighbours — `pubspec.yaml` registers that
/// directory wholesale, so there is no third step to forget.
///
/// Lucide, 24px grid, 1.75px stroke, no mixed libraries — PLAN.md §4.3.
/// `assets/icons/README.md` records why these are vendored rather than
/// reached through an `IconData` package.
///
/// Members are named for what the glyph **depicts**, never for what a screen
/// currently uses it for. [circleCheck] marks success in a toast today and
/// could underline a finished chapter tomorrow; a `success` member would
/// read as a lie the moment it did.
enum BooklyIconKind {
  /// Upstream `x` — dismiss, close, clear.
  close('x'),

  /// Upstream `circle-check` — a thing that is done.
  circleCheck('circle-check'),

  /// Upstream `circle-alert` — a thing that failed.
  circleAlert('circle-alert'),

  /// Upstream `triangle-alert` — a thing needing care.
  triangleAlert('triangle-alert'),

  /// Upstream `info`. Lucide also ships `circle-info`; this is the file that
  /// matches the circle-and-i silhouette this replaced.
  info('info'),

  /// Upstream `lightbulb` — a hint or a suggestion.
  lightbulb('lightbulb');

  const BooklyIconKind(this.lucideName);

  /// The upstream Lucide filename, without `.svg`.
  ///
  /// A field rather than a private detail because it is what a reader needs
  /// when a glyph is missing: the thrown error should name the file to
  /// fetch, not the enum member to go inspect.
  final String lucideName;

  /// Where the glyph sits in the asset bundle.
  String get assetPath => 'assets/icons/lucide/$lucideName.svg';
}
