import 'package:flutter/material.dart';

/// Brand constants. Never use in widgets directly; use [BooklyColors] via context.
abstract final class BooklyBrand {
  static const ink = Color(0xFF1B1714);
  static const paper = Color(0xFFF4EEE3);
  static const oxblood = Color(0xFF7A1F2B);
  // Graphic-only lens color on dark grounds (never for text).
  static const oxbloodDarkLens = Color(0xFFC0525E);
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

  static const light = BooklyColors(
    bg: Color(0xFFF4EEE3),
    surface: Color(0xFFFBF8F2),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEBE3D5),
    scrim: Color(0x7A1B1714),
    text: Color(0xFF1B1714),
    textSecondary: Color(0xFF5C534A),
    textTertiary: Color(0xFF6B6258),
    textDisabled: Color(0xFFA89D8D),
    textOnAccent: Color(0xFFFBF8F2),
    textLink: Color(0xFF7A1F2B),
    border: Color(0xFFD9CFBD),
    borderStrong: Color(0xFFB9AD98),
    focusRing: Color(0xFF7A1F2B),
    accent: Color(0xFF7A1F2B),
    accentHover: Color(0xFF651823),
    accentPressed: Color(0xFF52121C),
    accentSubtle: Color(0xFFEFDCD9),
    accentSubtleText: Color(0xFF5A1520),
    success: Color(0xFF2F6B4F),
    successSubtle: Color(0xFFDCEBE2),
    warning: Color(0xFF8A5A00),
    warningSubtle: Color(0xFFF3E5C6),
    danger: Color(0xFFC42B1C),
    dangerSubtle: Color(0xFFF6D9D4),
    info: Color(0xFF2C5A7A),
    infoSubtle: Color(0xFFD9E6EE),
    aiSurface: Color(0xFFEBE7F0),
    aiBorder: Color(0xFFCFC7DA),
    aiText: Color(0xFF3B2F4F),
    members: [
      Color(0xFFB4741C), Color(0xFF1F7A74), Color(0xFF7A3F7E),
      Color(0xFF5B7A2A), Color(0xFF3F5F9A), Color(0xFFB4533A),
    ],
    imageDim: 1.0,
  );

  static const dark = BooklyColors(
    bg: Color(0xFF14110F),
    surface: Color(0xFF1B1714),
    surfaceRaised: Color(0xFF241F1B),
    surfaceSunken: Color(0xFF0F0D0B),
    scrim: Color(0xA3000000),
    text: Color(0xFFF4EEE3),
    textSecondary: Color(0xFFBDB2A3),
    textTertiary: Color(0xFF968B7D),
    textDisabled: Color(0xFF5E564C),
    textOnAccent: Color(0xFFF4EEE3),
    textLink: Color(0xFFDE7B85),
    border: Color(0xFF2E2823),
    borderStrong: Color(0xFF4A4239),
    focusRing: Color(0xFFDE7B85),
    accent: Color(0xFFB8434F),
    accentHover: Color(0xFFC5525E),
    accentPressed: Color(0xFFA63844),
    accentSubtle: Color(0xFF3A1A1E),
    accentSubtleText: Color(0xFFF0B4BA),
    success: Color(0xFF6FBF98),
    successSubtle: Color(0xFF17291F),
    warning: Color(0xFFE0B04A),
    warningSubtle: Color(0xFF2C2410),
    danger: Color(0xFFF0786C),
    dangerSubtle: Color(0xFF321815),
    info: Color(0xFF7FB3D6),
    infoSubtle: Color(0xFF132230),
    aiSurface: Color(0xFF221D2B),
    aiBorder: Color(0xFF3A3149),
    aiText: Color(0xFFD8CDEA),
    members: [
      Color(0xFFE0A04A), Color(0xFF55C4BB), Color(0xFFC58AC9),
      Color(0xFF9CC25A), Color(0xFF8AA8E6), Color(0xFFE68A72),
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
