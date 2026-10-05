/// §5.3's publish rule, in one place.
///
/// ```
/// chapter_count >= 1  ||  link_count >= 1   → publishable
/// neither                                  → not a book
/// ```
///
/// This replaces the earlier "≥ 1 chapter" rule, and it is expressed
/// once because it has more than one surface already: the create form's
/// Save button, and later the same button on an edit screen. A rule
/// copied into two `onPressed` handlers is a rule that will be changed
/// in one of them.
///
/// It takes counts rather than a `Book`, because the whole point of the
/// rule is that it applies to a book that does not exist yet.
abstract final class BookPublishRule {
  /// Whether a book with these counts is worth saving.
  static bool isPublishable({
    required int chapterCount,
    required int linkCount,
  }) =>
      chapterCount >= 1 || linkCount >= 1;

  /// Shown under the sections rather than under Save: the rule is about
  /// what is *missing*, and a message attached to the button would
  /// accuse the button of a shortfall the reader can only fix elsewhere.
  static const missingContentMessage =
      'A book needs something to read — add at least one chapter or one link.';

  /// §5.3 in a sentence, for the line the form shows *before* the reader
  /// has added anything — so the rule is stated up front rather than
  /// only enforced at the end.
  static const hint = 'Add chapters, or links to video and podcasts.';
}
