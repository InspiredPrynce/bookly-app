/// Severity of a toast, deciding styling only.
///
/// One enum per file — see PLAN.md §0.1.
///
/// **Tone does not choose a sound.** The `ToastTone → sound` mapping was
/// removed by decision: Bookly plays one chime, `BookSound.notification`,
/// whenever a toast is presented (PLAN.md §4). Tone styles the bar — ground,
/// rule, icon — and nothing else.
enum ToastTone {
  /// Something the reader must correct or retry. Oxblood-grounded.
  error,

  /// Recoverable or environmental — offline, interrupted stream.
  warning,

  /// The action completed. Amber, not green.
  success,

  /// Inline, under a field: "No Bookly account with that email."
  danger,

  /// Neutral context — safety block, plain information.
  info,

  /// A way forward rather than a fault: "Add your Gemini key in Settings."
  help,
}
