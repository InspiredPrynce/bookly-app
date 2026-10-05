/// Sounds Bookly can play.
///
/// One enum per file — see PLAN.md §0.1.
///
/// Deliberately a single member. The notification chime is the whole sound
/// design: it plays when a toast is presented, regardless of that toast's
/// `ToastTone`. Growth here means adding real sound design, not adding a
/// second chime per severity.
enum BookSound {
  /// `assets/sound/notification.mp3` — the one chime.
  notification,
}
