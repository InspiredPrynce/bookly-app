import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_theme.dart';

/// The reader's surface choice, with persistence.
///
/// Deliberately a separate setting from `BooklyThemeMode` rather than a
/// fourth value on it: System / Light / Dark answers *how is the app
/// dressed*, this answers *how is the page dressed*. See [ReadingTheme]
/// for why those are two questions.
///
/// **Not wired to anything yet**, which is the same position
/// `BooklyThemeMode` has been in since Phase 0 — its consumer is
/// Phase 3's Settings screen. Shipping the setting ahead of the screen
/// means that when the toggle lands it chooses between real, already
/// exercised options instead of being the first thing ever to exercise
/// them.
///
/// ```dart
/// final readingTheme = ReadingThemeMode();
/// await readingTheme.load();          // before the first read
///
/// // in a reading surface:
/// Theme(
///   data: BooklyTheme.reading(
///     choice: readingTheme.value,
///     systemBrightness: WidgetsBinding.instance.platformDispatcher
///         .platformBrightness,
///   ),
///   child: ...,
/// )
/// ```
class ReadingThemeMode extends ValueNotifier<ReadingTheme> {
  ReadingThemeMode() : super(ReadingTheme.system);
  static const _key = 'bookly.readingTheme';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    value = switch (p.getString(_key)) {
      'light' => ReadingTheme.light,
      'dark' => ReadingTheme.dark,
      'nightPaper' => ReadingTheme.nightPaper,
      _ => ReadingTheme.system,
    };
  }

  Future<void> set(ReadingTheme theme) async {
    value = theme;
    final p = await SharedPreferences.getInstance();
    if (theme == ReadingTheme.system) {
      await p.remove(_key);
    } else {
      await p.setString(_key, theme.name);
    }
  }
}
