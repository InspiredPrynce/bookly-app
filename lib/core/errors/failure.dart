import 'failure_code.dart';

/// A failure that is safe to show a reader.
///
/// Thrown by repositories and caught by the application layer, which maps
/// [code] to a `ToastTone` and decides where the message appears — bar,
/// inline under a field, or a full-screen error view.
///
/// Two rules this type exists to enforce (PLAN.md §3.2, §7.8):
///
/// * **[message] is always presentable copy.** No stack traces, no raw
///   payloads, no API response bodies.
/// * **[cause] is never rendered and never logged in production.** It is
///   retained purely so a debug build can show what actually happened —
///   in particular the Gemini key, which must not reach a log line or an
///   error payload under any circumstance.
class Failure implements Exception {
  const Failure({required this.code, required this.message, this.cause});

  /// What went wrong, in terms Bookly can display.
  final FailureCode code;

  /// User-facing copy, already decided by whoever constructed this.
  final String message;

  /// The underlying error, for development diagnostics only.
  final Object? cause;

  /// Deliberately excludes [cause]: a `toString` is the most common thing
  /// to end up in a log line, and this is the last gate before one.
  @override
  String toString() => 'Failure(${code.name}): $message';
}
