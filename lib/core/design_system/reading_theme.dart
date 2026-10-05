/// What the reading surface is dressed in (PLAN.md §4.10).
///
/// Four options, not three — because night-paper is an answer the app's
/// own System / Light / Dark control does not have. This is a
/// *reading* choice: "how should the page look while I read". The
/// app's theme is a different question, and the two are deliberately
/// allowed to disagree. Light for the app through the day with
/// Night-paper for the page at 11pm is a coherent pair, not a
/// contradiction — and making it one setting would force a reader to
/// choose between the two things they actually wanted.
///
/// Its own file because Bookly puts every enum in one (PLAN.md §0.1).
enum ReadingTheme {
  /// Follow the device, the way the app's own control does.
  system,

  /// The app's light palette — "The Reading Desk".
  light,

  /// The app's dark palette — "The Night Salon".
  dark,

  /// PLAN.md §4.10: canvas `#0F0D0B`, parchment text `#D9CFBD`,
  /// line-height 1.75, ≥7:1. Dark whether or not the device is.
  nightPaper,
}
