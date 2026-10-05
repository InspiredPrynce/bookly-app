/// Machine-readable causes a `Failure` can carry.
///
/// One enum per file — see PLAN.md §0.1.
///
/// The application layer maps a code to a `ToastTone` and copy; keeping the
/// distinction here rather than in message strings is what lets
/// "wrong credentials" and "unknown" both render as `error` while one is
/// specific and the other is deliberately vague (PLAN.md §3.2, §7.8).
enum FailureCode {
  // ── Transport ───────────────────────────────────────────────────────────
  /// No connection. `warning` + "You're offline…"
  networkOffline,

  // ── Auth (§3.2) ─────────────────────────────────────────────────────────
  /// Wrong email/password pair. Never says which was wrong.
  invalidCredentials,

  /// An email found no profile. `danger`, inline under the field.
  noAccount,

  /// Registration with a taken address.
  emailAlreadyRegistered,

  /// Below policy. `danger`, inline under the field.
  weakPassword,

  // ── Session & access ────────────────────────────────────────────────────
  /// RLS refused, or the session is gone.
  unauthorised,

  /// A row the caller expected to exist did not.
  notFound,

  /// Write lost a race — optimistic rollback territory (§6.10).
  conflict,

  /// Expired or malformed invite link (§6.10).
  invalidLink,

  /// Client- or server-side throttle tripped.
  rateLimited,

  // ── Gemini (§7.8) ───────────────────────────────────────────────────────
  /// No key on device. `help` + deep-link to Settings.
  geminiMissingKey,

  /// Key rejected or revoked by Google.
  geminiInvalidKey,

  /// Quota exhausted. `warning`, "resets shortly".
  geminiQuota,

  /// Gemini refused the prompt. `info`, no blame.
  geminiSafetyBlock,

  /// Stream ended mid-answer. `warning` + Retry.
  geminiStreamCut,

  // ── Catch-all ───────────────────────────────────────────────────────────
  /// Anything unclassified. Always generic copy — never the underlying text.
  unknown,
}
