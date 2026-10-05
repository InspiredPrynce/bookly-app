import 'package:flutter/material.dart';

/// Literary Clothbound type scale — a dual-voiced editorial hierarchy.
///
/// 1. **The Literary Voice** — Playfair Display for display and headlines
///    (high stroke contrast, sweeping terminals); Literata for body copy and
///    sustained reading (humanist warmth, optical comfort).
/// 2. **The Bibliographic Voice** — Inter for labels, metadata, ISBNs,
///    classification badges, reading metrics and triggers: crisp, slightly
///    spaced, small — the archival card-catalog index.
///
/// All three families are **bundled in `assets/fonts/`** and registered in
/// `pubspec.yaml`. Nothing here touches the network, so the first frame is
/// never at the mercy of Google Fonts.
///
/// Rules of usage (DESIGN.md §Typography):
/// - Every `label*` token is rendered **uppercase** at the call site, paired
///   with its expansive tracking, to mimic book-spine stamping. Flutter's
///   [TextStyle] has no case property, so the conversion happens where the
///   `Text` is built; treat that as part of the token.
/// - `display*` and `headline*` are **never** uppercased — preserve sentence
///   and title case so serifs and ligatures show.
/// - Pull-quotes use Playfair Display italic at [pullQuote] /
///   [pullQuoteLg].
abstract final class BooklyType {
  /// The display voice.
  static const playfair = 'Playfair Display';

  /// The reading voice.
  static const literata = 'Literata';

  /// The bibliographic voice.
  static const inter = 'Inter';

  /// Playfair Display's default figures are lining; kept so call sites that
  /// predate Literary Clothbound keep compiling and keep behaving.
  static const lining = <FontFeature>[FontFeature.liningFigures()];

  /// Inter metrics: tabular figures for reading metrics and page indices.
  static const numeric = <FontFeature>[
    FontFeature.liningFigures(),
    FontFeature.tabularFigures(),
  ];

  static TextStyle _serif(
    double size,
    double lineHeightPx,
    FontWeight w, {
    double ls = 0,
    FontStyle style = FontStyle.normal,
  }) =>
      TextStyle(
        fontFamily: playfair,
        fontSize: size,
        height: lineHeightPx / size,
        fontWeight: w,
        letterSpacing: ls,
        fontStyle: style,
        fontFeatures: lining,
      );

  static TextStyle _book(
    double size,
    double lineHeightPx,
    FontWeight w, {
    double ls = 0,
    FontStyle style = FontStyle.normal,
  }) =>
      TextStyle(
        fontFamily: literata,
        fontSize: size,
        height: lineHeightPx / size,
        fontWeight: w,
        letterSpacing: ls,
        fontStyle: style,
        fontFeatures: lining,
      );

  static TextStyle _label(
    double size,
    double lineHeightPx,
    FontWeight w,
    double ls,
  ) =>
      TextStyle(
        fontFamily: inter,
        fontSize: size,
        height: lineHeightPx / size,
        fontWeight: w,
        letterSpacing: ls,
        fontFeatures: numeric,
      );

  // ── Display & headline — Playfair Display ────────────────────────────
  static final display = _serif(40, 48, FontWeight.w600, ls: -40 * 0.02);
  static final displayMobile = _serif(32, 40, FontWeight.w600, ls: -32 * 0.01);
  static final headlineLg = _serif(30, 38, FontWeight.w600, ls: -30 * 0.01);
  static final headlineLgMobile =
      _serif(26, 34, FontWeight.w600, ls: -26 * 0.01);
  static final headlineMd = _serif(22, 30, FontWeight.w500);
  static final headlineSm = _serif(18, 26, FontWeight.w500);

  /// Pull-quote: Playfair Display italic, flanked by ornamental rules in use.
  static final pullQuote = _serif(22, 30, FontWeight.w500,
      style: FontStyle.italic);
  static final pullQuoteLg = _serif(30, 38, FontWeight.w600,
      style: FontStyle.italic);

  // ── Body — Literata ──────────────────────────────────────────────────
  static final bodyLg = _book(18, 30, FontWeight.w400, ls: -18 * 0.005);
  static final bodyMd = _book(16, 26, FontWeight.w400);
  static final bodySm = _book(14, 22, FontWeight.w400);

  /// Long-form reading — chapter notes and Gemini answers.
  /// Line-height 1.75, max line ~66 characters (night-paper spec).
  static final reading = _book(18, 18 * 1.75, FontWeight.w400);

  /// Italic body, for quoted book passages.
  static final bodyMdItalic = _book(16, 26, FontWeight.w400,
      style: FontStyle.italic);

  // ── Labels — Inter (always uppercase at the call site) ───────────────
  static final labelLg = _label(13, 18, FontWeight.w600, 13 * 0.06);
  static final labelMd = _label(11, 16, FontWeight.w500, 11 * 0.08);
  static final labelSm = _label(10, 14, FontWeight.w500, 10 * 0.1);

  /// Button labels: same bibliographic voice as [labelLg], not uppercased by
  /// default so Material's own button components stay idiomatic.
  static final button = _label(13, 18, FontWeight.w600, 13 * 0.04);

  /// Material TextTheme mapping. Colors are applied by `BooklyTheme`.
  static TextTheme textTheme() => TextTheme(
        displayLarge: display,
        displayMedium: headlineLg,
        displaySmall: headlineMd,
        headlineLarge: headlineLgMobile,
        headlineMedium: headlineMd,
        headlineSmall: headlineSm,
        titleLarge: headlineSm.copyWith(fontWeight: FontWeight.w600),
        titleMedium: bodyMd.copyWith(fontWeight: FontWeight.w500),
        titleSmall: bodySm.copyWith(fontWeight: FontWeight.w500),
        bodyLarge: bodyLg,
        bodyMedium: bodyMd,
        bodySmall: bodySm,
        labelLarge: labelLg,
        labelMedium: labelMd,
        labelSmall: labelSm,
      );
}
