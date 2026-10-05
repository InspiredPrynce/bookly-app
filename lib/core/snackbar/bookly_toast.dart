import 'package:flutter/material.dart';

import '../errors/toast_tone.dart';
import 'bookly_overlay.dart';
import 'toast_request.dart';
import 'top_toast_bar.dart';

/// Bookly's toasts: top-anchored, replacing rather than queueing, and bound
/// to the one chime (PLAN.md §4.5).
///
/// ## Replace, don't queue
///
/// When a second toast arrives while one is up, the first is **removed and
/// the new one takes its place**, immediately. A queue is worse than it
/// sounds: a reader pressing "Join circle" twice quickly could raise two
/// failures, and a queue would deliver them four seconds apart — the second
/// landing while they were still acting on the first. The toast that
/// matters is the most recent one.
///
/// ## Nothing is decided here
///
/// Tone → ground, hinge and icon is resolved by [TopToastBar] against the
/// ambient theme, so this class passes no colors at all. It owns the parts
/// the bar cannot: reaching the root overlay, ensuring only one entry exists
/// at a time, and handing the request across the rebuild boundary.
///
/// ## The chime is not this class's business either
///
/// It is fired from [ChimeOnPresent]'s `initState`, inside the bar. Playing
/// it here would ring for a toast that was replaced before it ever appeared.
abstract final class BooklyToast {
  /// The bar currently on screen, if any. There is never more than one.
  static OverlayEntry? _entry;

  /// Presents [message] at the top of the app.
  ///
  /// [title] is optional: PLAN.md §3.2 and §7.8 write their copy as single
  /// sentences, and a title band above one line is mostly empty space. Pass
  /// one only when there is genuinely a second thing to say.
  static void show({
    required String message,
    required ToastTone tone,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    /// The bar being replaced leaves now, without an exit animation. An
    /// animated dismissal would leave two bars on screen for the length of
    /// it, and the point of replacing is that the previous message stops
    /// mattering immediately.
    _clear();

    final overlay = BooklyOverlay.overlay;
    if (overlay == null) {
      /// No navigator yet — pre-`runApp`, a test, or a teardown. The toast
      /// is lost, and that is correct: a toast is decoration, never the only
      /// channel for something that has to happen.
      debugPrint('⚠️ BooklyToast: no overlay — ${tone.name}: $message');
      return;
    }

    final request = ToastRequest(
      message: message,
      tone: tone,
      duration: duration,
      title: title,
    );

    /// `late final` so the entry can name itself in the completion callback,
    /// which runs after this statement.
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => TopToastBar(
        request: request,
        onDismissed: () {
          /// Identity, not merely "is there an entry" — a bar that timed out
          /// and a bar replaced by a newer toast both land here, and only
          /// the first must take itself down.
          if (identical(_entry, entry)) _clear();
        },
      ),
    );

    _entry = entry;
    overlay.insert(entry);
  }

  /// Takes down whatever is showing, if anything.
  static void hide() => _clear();

  static void _clear() {
    final entry = _entry;
    _entry = null;
    if (entry == null || !entry.mounted) return;
    entry.remove();
  }

  /// The action completed.
  static void success(String message, {Duration duration = const Duration(seconds: 4)}) =>
      show(message: message, tone: ToastTone.success, duration: duration);

  /// Retryable trouble. Given the extra second, because these messages
  /// usually carry a next step the reader has to act on.
  static void error(String message, {Duration duration = const Duration(seconds: 5)}) =>
      show(message: message, tone: ToastTone.error, duration: duration);

  /// Recoverable or environmental — offline, interrupted.
  static void warning(String message) =>
      show(message: message, tone: ToastTone.warning);

  /// A neutral fact about the app.
  static void info(String message) =>
      show(message: message, tone: ToastTone.info);

  /// A pointer to something the reader can go and do.
  static void help(String message) =>
      show(message: message, tone: ToastTone.help);

  /// Inline-strength severity, for when a bar is the only surface available.
  static void danger(String message) =>
      show(message: message, tone: ToastTone.danger);
}
