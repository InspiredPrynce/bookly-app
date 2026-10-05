import 'failure_code.dart';
import 'failure_surface.dart';
import 'toast_tone.dart';

/// `FailureCode` → severity and placement (PLAN.md §3.2, §7.8).
///
/// Two pure functions over the code, deliberately knowing nothing about
/// widgets, overlays or copy: the *message* was decided when the
/// [Failure] was constructed, and this decides only how serious it looks
/// and where it belongs.
///
/// Keeping it separate is what lets "wrong credentials" and "unknown"
/// both render as `error` while one is specific and the other is
/// deliberately vague — the reader-facing difference is carried by the
/// copy, never by the code.
///
/// Severity styles a bar's ground, rule and icon. It never selects a
/// sound: Bookly plays one chime whenever a toast is presented (§4.5).
abstract final class FailureMapper {
  /// How serious [code] is.
  static ToastTone tone(FailureCode code) => switch (code) {
        // ── Transport & throttle ─────────────────────────────────────
        FailureCode.networkOffline => ToastTone.warning,
        FailureCode.rateLimited => ToastTone.warning,

        // ── Auth (§3.2) ─────────────────────────────────────────────
        // The pair below are the reason tone and copy are decided in
        // different places: both are `error`, but only one may name
        // what went wrong.
        FailureCode.invalidCredentials => ToastTone.error,
        FailureCode.emailAlreadyRegistered => ToastTone.error,
        FailureCode.noAccount => ToastTone.danger,
        FailureCode.weakPassword => ToastTone.danger,

        // ── Session & access ────────────────────────────────────────
        FailureCode.unauthorised => ToastTone.error,
        FailureCode.notFound => ToastTone.info,
        FailureCode.conflict => ToastTone.warning,
        FailureCode.invalidLink => ToastTone.error,

        // ── Gemini (§7.8) ───────────────────────────────────────────
        FailureCode.geminiMissingKey => ToastTone.help,
        FailureCode.geminiInvalidKey => ToastTone.error,
        FailureCode.geminiQuota => ToastTone.warning,
        FailureCode.geminiSafetyBlock => ToastTone.info,
        FailureCode.geminiStreamCut => ToastTone.warning,

        // ── Catch-all ───────────────────────────────────────────────
        // Generic copy and a plain error: an unclassified failure has
        // earned no privilege to look interesting.
        FailureCode.unknown => ToastTone.error,
      };

  /// Where [code] belongs — under its field, or at the top of the app.
  static FailureSurface surface(FailureCode code) => switch (code) {
        // Wrong *in that input*, and nowhere else implicates. Nothing
        // else in the form is accused, because nothing else is at fault.
        FailureCode.weakPassword ||
        FailureCode.noAccount =>
          FailureSurface.inline,

        // Everything else names no field, so presenting it as one would
        // imply a field the reader did not get wrong.
        _ => FailureSurface.toast,
      };
}
