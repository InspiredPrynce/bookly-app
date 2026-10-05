import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Raleway scale. Medium (500) for UI; 400 only for long reading.
/// Raleway defaults to old-style figures: [lining] / [numeric] fix that.
abstract final class BooklyType {
  static const lining = [FontFeature.liningFigures()];
  static const numeric = [FontFeature.liningFigures(), FontFeature.tabularFigures()];

  static TextStyle _s(double size, double lineHeightPx, FontWeight w,
          {double ls = 0, bool upper = false}) =>
      GoogleFonts.raleway(
        fontSize: size,
        height: lineHeightPx / size,
        fontWeight: w,
        letterSpacing: ls,
        fontFeatures: lining,
      );

  static final display = _s(56, 60, FontWeight.w700, ls: -56 * 0.02);
  static final h1 = _s(40, 48, FontWeight.w700, ls: -40 * 0.01);
  static final h2 = _s(32, 38, FontWeight.w700, ls: -32 * 0.01);
  static final h3 = _s(24, 29, FontWeight.w600, ls: -24 * 0.01);
  static final h4 = _s(20, 26, FontWeight.w600);
  static final bodyLg = _s(18, 29, FontWeight.w500);
  static final body = _s(16, 26, FontWeight.w500);
  static final bodySm = _s(14, 20, FontWeight.w500);
  static final caption = _s(12, 17, FontWeight.w500, ls: 0.12);
  static final overline = _s(12, 16, FontWeight.w600, ls: 12 * 0.14);
  static final button = _s(15, 20, FontWeight.w600);

  /// Long-form chapter notes + Gemini answers. Max line ~62 chars.
  static final reading = GoogleFonts.raleway(
    fontSize: 18,
    height: 1.7,
    fontWeight: FontWeight.w400,
    fontFeatures: lining,
  );

  /// Mobile display overrides (screens < 640 dp wide).
  static final displayMobile = _s(40, 44, FontWeight.w700, ls: -40 * 0.02);
  static final h1Mobile = _s(32, 38, FontWeight.w700, ls: -32 * 0.01);
  static final h2Mobile = _s(28, 34, FontWeight.w700, ls: -28 * 0.01);
  static final h3Mobile = _s(22, 27, FontWeight.w600, ls: -22 * 0.01);

  /// Material TextTheme mapping. Colors applied by ThemeData.
  static TextTheme textTheme() => TextTheme(
        displayLarge: display,
        displayMedium: h1,
        displaySmall: h2,
        headlineLarge: h2,
        headlineMedium: h3,
        headlineSmall: h4,
        titleLarge: h3,
        titleMedium: h4,
        titleSmall: bodySm.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: bodyLg,
        bodyMedium: body,
        bodySmall: bodySm,
        labelLarge: button,
        labelMedium: caption,
        labelSmall: overline,
      );
}
