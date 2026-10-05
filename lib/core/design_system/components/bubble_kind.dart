/// Who authored a chat bubble.
///
/// One enum per file — see PLAN.md §0.1.
///
/// Distinguishing AI output is not only a visual concern: [gemini] bubbles
/// carry an "AI" label in text, never colour alone (DESIGN.md §11).
enum BubbleKind {
  /// The current user's own message.
  own,

  /// Another circle member's message.
  friend,

  /// A Gemini reply.
  gemini,
}
