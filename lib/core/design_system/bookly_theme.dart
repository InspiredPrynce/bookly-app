import 'package:flutter/material.dart';

import 'bookly_colors.dart';
import 'bookly_tokens.dart';
import 'bookly_typography.dart';

/// Reads Bookly's semantic tokens off the ambient theme.
extension BooklyContext on BuildContext {
  BooklyColors get colors => Theme.of(this).extension<BooklyColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Literary Clothbound [ThemeData], light ("The Reading Desk") and dark
/// ("The Night Salon").
///
/// Three named button treatments carry the whole interaction language:
///
/// - **Cloth & Foil** ([_filled]) — the primary action. High-contrast warm
///   ground, ivory type, a hairline gilt border.
/// - **Paper & Rule** ([_outlined]) — the secondary action. Paper ground,
///   hairline rule, charcoal type; presses toward a tone-down of the paper.
/// - **Gilt Gold** ([_accent]) — burnished amber, reserved for primary
///   conversion events.
abstract final class BooklyTheme {
  static ThemeData get light => _build(Brightness.light, BooklyColors.light);
  static ThemeData get dark => _build(Brightness.dark, BooklyColors.dark);

  /// Card-catalog field: a single bottom rule, never a four-sided box, with
  /// the focus state elevating to Burnished Amber and no glowing halo.
  static InputDecorationTheme _input(BooklyColors c) {
    BorderSide rule(Color color) =>
        BorderSide(color: color, width: BooklyBorder.inputBottom);
    return InputDecorationTheme(
      isDense: true,
      filled: false,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: BooklySpace.md,
      ),
      border: UnderlineInputBorder(borderSide: rule(c.border)),
      enabledBorder: UnderlineInputBorder(borderSide: rule(c.border)),
      focusedBorder: UnderlineInputBorder(borderSide: rule(c.focusRing)),
      errorBorder: UnderlineInputBorder(borderSide: rule(c.danger)),
      focusedErrorBorder: UnderlineInputBorder(borderSide: rule(c.danger)),
      hintStyle: BooklyType.bodyMd.copyWith(color: c.textTertiary),
      labelStyle: BooklyType.bodyMd.copyWith(color: c.textSecondary),
      errorStyle: BooklyType.labelMd.copyWith(color: c.danger),
    );
  }

  /// Cloth & Foil. Ground = `text`, type = `textOnAccent`, which resolves to
  /// Warm Charcoal + Soft Ivory in light and the exact inverse in dark — the
  /// same cloth, lit from the other side.
  static ButtonStyle _filled(BooklyColors c) => FilledButton.styleFrom(
        backgroundColor: c.text,
        foregroundColor: c.textOnAccent,
        disabledBackgroundColor: c.textDisabled,
        disabledForegroundColor: c.bg,
        side: BorderSide(color: c.accent, width: BooklyBorder.thin),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: BooklySpace.lg,
          vertical: BooklySpace.sm,
        ),
        minimumSize: const Size(0, BooklySpace.tapMin),
        textStyle: BooklyType.button,
        shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.rSm),
      );

  /// Paper & Rule.
  static ButtonStyle _outlined(BooklyColors c) => OutlinedButton.styleFrom(
        backgroundColor: c.surface,
        foregroundColor: c.text,
        side: BorderSide(color: c.border, width: BooklyBorder.thin),
        padding: const EdgeInsets.symmetric(
          horizontal: BooklySpace.lg,
          vertical: BooklySpace.sm,
        ),
        minimumSize: const Size(0, BooklySpace.tapMin),
        textStyle: BooklyType.button,
        shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.rSm),
      );

  /// Gilt Gold — reserved for primary conversion events ("Add to Library",
  /// "Join Circle"). Not wired as a theme default, because Material picks
  /// button hierarchy for us; ask for it explicitly:
  ///
  /// ```dart
  /// FilledButton(style: BooklyTheme.accent(context), onPressed: ..., child: ...);
  /// ```
  static ButtonStyle accent(BuildContext context) => _accent(context.colors);

  static ButtonStyle _accent(BooklyColors c) => FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: BooklyBrand.ink,
        disabledBackgroundColor: c.surfaceSunken,
        disabledForegroundColor: c.textDisabled,
        side: BorderSide(color: c.accentHover, width: BooklyBorder.thin),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: BooklySpace.lg,
          vertical: BooklySpace.sm,
        ),
        minimumSize: const Size(0, BooklySpace.tapMin),
        textStyle: BooklyType.button,
        shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.rSm),
      );

  static ThemeData _build(Brightness b, BooklyColors c) {
    final onSurface = b == Brightness.light ? BooklyBrand.ink : BooklyBrand.ivory;

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: b,
        primary: c.accent,
        onPrimary: BooklyBrand.ink,
        secondary: c.accent,
        surface: c.surface,
        onSurface: onSurface,
        error: c.danger,
        outline: c.border,
        outlineVariant: c.borderStrong,
      ),
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      extensions: [c],
      textTheme: BooklyType.textTheme().apply(
        bodyColor: c.text,
        displayColor: c.text,
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: c.accent.withValues(alpha: 0.08),
      hoverColor: c.accent.withValues(alpha: 0.05),
      focusColor: c.accent.withValues(alpha: 0.10),
      dividerColor: c.border,
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: BooklyBorder.thin,
        space: BooklyBorder.thin,
      ),
      iconTheme: IconThemeData(color: c.text, size: 24),
      primaryIconTheme: IconThemeData(color: c.accent, size: 24),

      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: c.text,
        titleTextStyle: BooklyType.headlineSm.copyWith(color: c.text),
        iconTheme: IconThemeData(color: c.text, size: 24),
      ),

      // Book jacket cards: flat, hairline-bound, sharp corners.
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.border, width: BooklyBorder.thin),
          borderRadius: BooklyRadius.rSm,
        ),
      ),

      inputDecorationTheme: _input(c),

      filledButtonTheme: FilledButtonThemeData(style: _filled(c)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _filled(c)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _outlined(c)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.text,
          textStyle: BooklyType.button,
          minimumSize: const Size(0, BooklySpace.tapMin),
          padding: const EdgeInsets.symmetric(horizontal: BooklySpace.md),
          shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.rSm),
        ),
      ),

      // Square 16px frames; Burnished Amber core on the radio.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.accent : Colors.transparent),
        checkColor: WidgetStateProperty.all(BooklyBrand.ink),
        side: BorderSide(color: c.borderStrong, width: BooklyBorder.thin),
        shape: RoundedRectangleBorder(borderRadius: BooklyRadius.rXs),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.accent : c.textSecondary),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.accent : c.surfaceSunken),
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? BooklyBrand.ink : c.textSecondary),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceSunken,
        circularTrackColor: c.surfaceSunken,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.text,
        contentPadding: const EdgeInsets.symmetric(horizontal: BooklySpace.md),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: BooklyType.bodySm.copyWith(color: c.text),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.rSm),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.sheet),
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.rSm),
        titleTextStyle: BooklyType.headlineMd.copyWith(color: c.text),
        contentTextStyle: BooklyType.bodyMd.copyWith(color: c.text),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.30),
        selectionHandleColor: c.accent,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: c.text,
        unselectedLabelColor: c.textSecondary,
        labelStyle: BooklyType.labelLg,
        unselectedLabelStyle: BooklyType.labelLg,
        indicatorColor: c.accent,
        dividerColor: c.border,
      ),
    );

    return base;
  }
}
