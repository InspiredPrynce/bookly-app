import 'package:flutter/foundation.dart';

import '../errors/toast_tone.dart';

/// One toast, as handed to the bar that renders it.
///
/// A value rather than four loose parameters because it travels across the
/// overlay's rebuild boundary, where a `final` class of named fields survives
/// better than a positional list.
@immutable
class ToastRequest {
  const ToastRequest({
    required this.message,
    required this.tone,
    required this.duration,
    this.title,
  });

  /// Always present: the copy the reader actually has to read.
  final String message;

  /// Optional. When null the bar shows the message alone — the error tables
  /// in PLAN.md §3.2 and §7.8 are written as single sentences, and a title
  /// band above one line of text is mostly empty space.
  final String? title;

  final ToastTone tone;
  final Duration duration;
}
