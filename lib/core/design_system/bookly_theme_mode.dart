import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// System / Light / Dark with persistence.
///
/// ```dart
/// final themeMode = BooklyThemeMode();
/// await themeMode.load();           // before runApp
/// MaterialApp(
///   theme: BooklyTheme.light, darkTheme: BooklyTheme.dark,
///   themeMode: themeMode.value,
/// )
/// ```
/// Wrap MaterialApp in `ValueListenableBuilder<ThemeMode>` on [themeMode].
class BooklyThemeMode extends ValueNotifier<ThemeMode> {
  BooklyThemeMode() : super(ThemeMode.system);
  static const _key = 'bookly.themeMode';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    value = switch (p.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    value = mode;
    final p = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await p.remove(_key);
    } else {
      await p.setString(_key, mode.name);
    }
  }
}
