import 'package:flutter/material.dart';

/// Brand constants — Literary Clothbound.
///
/// Derived from classical publishing materials: rag paper, oak gall ink,
/// bookbinder's gold leaf, crushed madder cloth.
///
/// Never use these in widgets directly; read [BooklyColors] from context so
/// dark mode is handled for you.
abstract final class BooklyBrand {
  /// Warm Charcoal — letterpress ink absorbed into rag paper.
  static const ink = Color(0xFF1C1A17);

  /// Warm Paper — uncoated heavy stock (Light canvas).
  static const paper = Color(0xFFF6F1E7);

  /// Deep Ink — dark canvas, deliberately free of cold blue undertones.
  static const deepInk = Color(0xFF12100E);

  /// Soft Ivory — dark-mode primary text.
  static const ivory = Color(0xFFF4EFE6);

  /// Burnished Amber — gilt edges and spine foil. The primary mark of
  /// distinction: active progress, bookmarks, highlights, focus.
  static const gilt = Color(0xFFC8913D);
  static const giltDark = Color(0xFFDFAC56);

  /// Muted Oxblood — an editorial stamp of finality: reading-status seals,
  /// critical notices, destructive actions.
  static const oxblood = Color(0xFF7A2E2E);
  static const oxbloodLight = Color(0xFFC66966);
}

/// Semantic color tokens. Light + dark. Read with `context.colors`.
@immutable
class BooklyColors extends ThemeExtension<BooklyColors> {
  const BooklyColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.scrim,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textOnAccent,
    required this.textLink,
    required this.border,
    required this.borderStrong,
    required this.focusRing,
    required this.accent,
    required this.accentHover,
    required this.accentPressed,
    required this.accentSubtle,
    required this.accentSubtleText,
    required this.success,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.danger,
    required this.dangerSubtle,
    required this.info,
    required this.infoSubtle,
    required this.aiSurface,
    required this.aiBorder,
    required this.aiText,
    required this.members,
    required this.imageDim,
  });

  final Color bg, surface, surfaceRaised, surfaceSunken, scrim;
  final Color text, textSecondary, textTertiary, textDisabled, textOnAccent, textLink;
  final Color border, borderStrong, focusRing;
  final Color accent, accentHover, accentPressed, accentSubtle, accentSubtleText;
  final Color success, successSubtle, warning, warningSubtle;
  final Color danger, dangerSubtle, info, infoSubtle;
  final Color aiSurface, aiBorder, aiText;

  /// 6 circle-member identity colors, assigned in join order.
  final List<Color> members;

  /// Brightness multiplier for covers/photos (dark = 0.92).
  final double imageDim;

  Color member(int index) => members[index % members.length];

  /// Light Mode — "The Reading Desk".
  static const light = BooklyColors(
    bg: Color(0xFFF6F1E7), // Warm Paper
    surface: Color(0xFFFEF9EF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEDE8DE), // surface-container-high
    scrim: Color(0x731C1A17), // overlay shroud, 45%
    text: Color(0xFF1C1A17), // Warm Charcoal
    textSecondary: Color(0xFF6A645A), // Weathered Vellum
    textTertiary: Color(0xFF7C766E), // outline
    textDisabled: Color(0xFFB5AFA3),
    textOnAccent: Color(0xFFF4EFE6), // Soft Ivory, on Cloth & Foil
    textLink: Color(0xFF7A2E2E), // oxblood reads ~7:1 on Warm Paper
    border: Color(0xFFE6DEC9), // Muted Rule
    borderStrong: Color(0xFFCDC5BC), // outline-variant
    focusRing: Color(0xFFC8913D), // Burnished Amber, no halo
    accent: Color(0xFFC8913D), // Burnished Amber
    accentHover: Color(0xFFB07E30),
    accentPressed: Color(0xFF986B28),
    accentSubtle: Color(0xFFF7E9CE),
    accentSubtleText: Color(0xFF624000),
    success: Color(0xFF3E6B4A),
    successSubtle: Color(0xFFDFE9DF),
    warning: Color(0xFF8A5A00),
    warningSubtle: Color(0xFFF5E7C8),
    danger: Color(0xFFBA1A1A),
    dangerSubtle: Color(0xFFFFDAD6),
    info: Color(0xFF2C5A7A),
    infoSubtle: Color(0xFFD9E6EE),
    // Gilt-edged paper: Gemini output is framed as an inserted plate.
    aiSurface: Color(0xFFFCF7EC),
    aiBorder: Color(0xFFDCC591),
    aiText: Color(0xFF1C1A17),
    members: [
      Color(0xFFA9741B), Color(0xFF2E6E63), Color(0xFF8E3E63),
      Color(0xFF5E7A2E), Color(0xFF3F5A8A), Color(0xFFB4533A),
    ],
    imageDim: 1.0,
  );

  /// Dark Mode — "The Night Salon".
  static const dark = BooklyColors(
    bg: Color(0xFF12100E), // Deep Ink
    surface: Color(0xFF181512), // Surface Dark
    surfaceRaised: Color(0xFF1F1B17),
    surfaceSunken: Color(0xFF0D0B09),
    scrim: Color(0x73000000),
    text: Color(0xFFF4EFE6), // Soft Ivory
    textSecondary: Color(0xFFA89E8D), // Muted Subtitle
    textTertiary: Color(0xFF8C8375),
    textDisabled: Color(0xFF5E574C),
    textOnAccent: Color(0xFF12100E), // on Gilt Gold
    textLink: Color(0xFFC66966), // light oxblood clears 4.5:1 on Deep Ink
    border: Color(0xFF2E2720), // Dark Rule
    borderStrong: Color(0xFF453C33),
    focusRing: Color(0xFFDFAC56),
    accent: Color(0xFFDFAC56),
    accentHover: Color(0xFFE8BC6D),
    accentPressed: Color(0xFFC99A47),
    accentSubtle: Color(0xFF2E2417),
    accentSubtleText: Color(0xFFF0C778),
    success: Color(0xFF7FBF98),
    successSubtle: Color(0xFF16241A),
    warning: Color(0xFFE0B04A),
    warningSubtle: Color(0xFF2A2210),
    danger: Color(0xFFF0786C),
    dangerSubtle: Color(0xFF33171A),
    info: Color(0xFF7FB3D6),
    infoSubtle: Color(0xFF132230),
    aiSurface: Color(0xFF1A1613),
    aiBorder: Color(0xFF3E3323),
    aiText: Color(0xFFF4EFE6),
    members: [
      Color(0xFFE0A04A), Color(0xFF5FBFAE), Color(0xFFD489AC),
      Color(0xFFA9C266), Color(0xFF8FA8E6), Color(0xFFE68A72),
    ],
    imageDim: 0.92,
  );

  @override
  BooklyColors copyWith() => this;

  @override
  BooklyColors lerp(ThemeExtension<BooklyColors>? other, double t) {
    if (other is! BooklyColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return BooklyColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      scrim: l(scrim, other.scrim),
      text: l(text, other.text),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textDisabled: l(textDisabled, other.textDisabled),
      textOnAccent: l(textOnAccent, other.textOnAccent),
      textLink: l(textLink, other.textLink),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      focusRing: l(focusRing, other.focusRing),
      accent: l(accent, other.accent),
      accentHover: l(accentHover, other.accentHover),
      accentPressed: l(accentPressed, other.accentPressed),
      accentSubtle: l(accentSubtle, other.accentSubtle),
      accentSubtleText: l(accentSubtleText, other.accentSubtleText),
      success: l(success, other.success),
      successSubtle: l(successSubtle, other.successSubtle),
      warning: l(warning, other.warning),
      warningSubtle: l(warningSubtle, other.warningSubtle),
      danger: l(danger, other.danger),
      dangerSubtle: l(dangerSubtle, other.dangerSubtle),
      info: l(info, other.info),
      infoSubtle: l(infoSubtle, other.infoSubtle),
      aiSurface: l(aiSurface, other.aiSurface),
      aiBorder: l(aiBorder, other.aiBorder),
      aiText: l(aiText, other.aiText),
      members: [for (var i = 0; i < members.length; i++) l(members[i], other.members[i])],
      imageDim: imageDim + (other.imageDim - imageDim) * t,
    );
  }
}
