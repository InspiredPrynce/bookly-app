import 'package:flutter/material.dart';
import 'bookly_colors.dart';
import 'bookly_tokens.dart';
import 'bookly_typography.dart';

extension BooklyContext on BuildContext {
  /// Semantic colors for the active theme.
  BooklyColors get colors => Theme.of(this).extension<BooklyColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

abstract final class BooklyTheme {
  static ThemeData get light => _build(Brightness.light, BooklyColors.light);
  static ThemeData get dark => _build(Brightness.dark, BooklyColors.dark);

  static ThemeData _build(Brightness b, BooklyColors c) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.accent,
      onPrimary: c.textOnAccent,
      primaryContainer: c.accentSubtle,
      onPrimaryContainer: c.accentSubtleText,
      secondary: c.textLink,
      onSecondary: c.bg,
      error: c.danger,
      onError: b == Brightness.dark ? c.bg : Colors.white,
      errorContainer: c.dangerSubtle,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surfaceSunken,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.borderStrong,
      outlineVariant: c.border,
      scrim: c.scrim,
      shadow: Colors.black,
    );

    final text = BooklyType.textTheme().apply(
      bodyColor: c.text,
      displayColor: c.text,
    );

    OutlineInputBorder inputBorder(Color color, [double w = BooklyBorder.thin]) =>
        OutlineInputBorder(
          borderRadius: BooklyRadius.rSm,
          borderSide: BorderSide(color: color, width: w),
        );

    final buttonShape =
        RoundedRectangleBorder(borderRadius: BooklyRadius.rMd);
    const buttonPad = EdgeInsets.symmetric(horizontal: BooklySpace.s5);

    WidgetStateProperty<Color?> fill(Color base, Color hover, Color pressed) =>
        WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return c.surfaceSunken;
          if (s.contains(WidgetState.pressed)) return pressed;
          if (s.contains(WidgetState.hovered)) return hover;
          return base;
        });

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      textTheme: text,
      primaryTextTheme: text,
      extensions: [c],
      dividerTheme: DividerThemeData(color: c.border, thickness: BooklyBorder.thin, space: 1),
      iconTheme: IconThemeData(color: c.text, size: 24),
      focusColor: c.focusRing.withValues(alpha: 0.2),
      hoverColor: c.accentSubtle.withValues(alpha: 0.5),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: BooklyType.h4.copyWith(color: c.text),
        shape: Border(bottom: BorderSide(color: c.border)),
      ),

      // Primary button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          padding: const WidgetStatePropertyAll(buttonPad),
          shape: WidgetStatePropertyAll(buttonShape),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: WidgetStatePropertyAll(BooklyType.button),
          backgroundColor: fill(c.accent, c.accentHover, c.accentPressed),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.textDisabled : c.textOnAccent),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          padding: const WidgetStatePropertyAll(buttonPad),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(BooklyType.button),
          backgroundColor: fill(c.accent, c.accentHover, c.accentPressed),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.textDisabled : c.textOnAccent),
        ),
      ),
      // Secondary
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          padding: const WidgetStatePropertyAll(buttonPad),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(BooklyType.button),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.textDisabled : c.text),
          side: WidgetStateProperty.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.disabled) ? c.border : c.borderStrong)),
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.pressed) ? c.surfaceSunken : Colors.transparent),
        ),
      ),
      // Tertiary
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(BooklyType.button),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.textDisabled : c.textLink),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: BooklySpace.s4, vertical: BooklySpace.s3 + 2),
        hintStyle: BooklyType.body.copyWith(color: c.textTertiary),
        labelStyle: BooklyType.bodySm.copyWith(
            color: c.textSecondary, fontWeight: FontWeight.w600),
        helperStyle: BooklyType.caption.copyWith(color: c.textTertiary),
        errorStyle: BooklyType.caption.copyWith(color: c.danger),
        border: inputBorder(c.borderStrong),
        enabledBorder: inputBorder(c.borderStrong),
        focusedBorder: inputBorder(c.focusRing, BooklyBorder.strong),
        errorBorder: inputBorder(c.danger),
        focusedErrorBorder: inputBorder(c.danger, BooklyBorder.strong),
        disabledBorder: inputBorder(c.border),
      ),

      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BooklyRadius.rMd,
          side: BorderSide(color: c.border),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: c.accentSubtle,
        disabledColor: c.surfaceSunken,
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
        labelStyle: BooklyType.bodySm.copyWith(color: c.text),
        secondaryLabelStyle: BooklyType.bodySm.copyWith(color: c.accentSubtleText),
        padding: const EdgeInsets.symmetric(horizontal: BooklySpace.s2),
        checkmarkColor: c.accentSubtleText,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? c.textLink : c.textSecondary,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => BooklyType.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: s.contains(WidgetState.selected) ? c.textLink : c.textSecondary,
            )),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: c.text,
        unselectedLabelColor: c.textSecondary,
        labelStyle: BooklyType.button,
        unselectedLabelStyle: BooklyType.button,
        indicatorColor: c.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: c.border,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surfaceRaised,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.sheet),
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        dragHandleSize: const Size(36, 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.rXl),
        titleTextStyle: BooklyType.h3.copyWith(color: c.text),
        contentTextStyle: BooklyType.body.copyWith(color: c.textSecondary),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceRaised,
        contentTextStyle: BooklyType.bodySm.copyWith(color: c.text),
        actionTextColor: c.textLink,
        shape: const RoundedRectangleBorder(borderRadius: BooklyRadius.rMd),
        elevation: 0,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceSunken,
        circularTrackColor: c.surfaceSunken,
        linearMinHeight: 6,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.textOnAccent : c.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? c.accent : c.surfaceSunken),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.transparent : c.borderStrong),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.text,
        titleTextStyle: BooklyType.body.copyWith(color: c.text),
        subtitleTextStyle: BooklyType.bodySm.copyWith(color: c.textSecondary),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.28),
        selectionHandleColor: c.accent,
      ),
    );
  }
}
