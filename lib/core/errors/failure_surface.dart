/// Which surface a `Failure` is presented on.
///
/// One enum per file — PLAN.md §0.1.
///
/// Decided per *cause*, not per screen, because the two call for different
/// information. A weak password is wrong **in a specific field**: telling
/// the reader only that "something went wrong" leaves them hunting the
/// whole form for a mistake they cannot see. Wrong credentials are wrong
/// for the form as a whole — the reader cannot tell whether the email or
/// the password was mistyped, so naming a field would accuse the wrong one
/// (§3.2).
enum FailureSurface {
  /// Rendered beneath the field it belongs to, in `danger`.
  inline,

  /// Rendered as a top-anchored toast (§4.5).
  toast,
}
