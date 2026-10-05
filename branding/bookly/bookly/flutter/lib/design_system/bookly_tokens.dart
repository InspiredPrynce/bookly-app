import 'package:flutter/material.dart';

/// 4pt spacing scale.
abstract final class BooklySpace {
  static const s0 = 0.0;
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;
  static const s12 = 48.0;
  static const s16 = 64.0;
  static const s20 = 80.0;
  static const s24 = 96.0;

  /// Screen horizontal padding.
  static const screenMobile = 20.0;
  static const screenWide = 32.0;
  static const tapMin = 44.0;
}

abstract final class BooklyRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 9999.0;

  static const rXs = BorderRadius.all(Radius.circular(xs));
  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
  static const rFull = BorderRadius.all(Radius.circular(full));

  /// Book cover: tight on spine side, soft on page edge.
  static const cover = BorderRadius.only(
    topLeft: Radius.circular(xs),
    bottomLeft: Radius.circular(xs),
    topRight: Radius.circular(sm),
    bottomRight: Radius.circular(sm),
  );

  /// Bottom sheet.
  static const sheet = BorderRadius.vertical(top: Radius.circular(xl));
}

abstract final class BooklyMotion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);

  static const standard = Cubic(0.2, 0, 0, 1);
  static const enter = Cubic(0, 0, 0, 1);
  static const exit = Cubic(0.3, 0, 1, 1);

  /// Honors OS reduce-motion. Use for every animation duration.
  static Duration of(BuildContext c, Duration d) =>
      MediaQuery.disableAnimationsOf(c) ? Duration.zero : d;
}

abstract final class BooklyBreakpoint {
  static const sm = 640.0;
  static const md = 768.0;
  static const lg = 1024.0;
  static const xl = 1280.0;
  static const readingMaxWidth = 640.0;
}

abstract final class BooklyBorder {
  static const thin = 1.0;
  static const strong = 2.0;
}

/// Elevation. Light = soft shadow. Dark = border ring + lighter surface.
abstract final class BooklyElevation {
  static List<BoxShadow> level(BuildContext c, int n) {
    final dark = Theme.of(c).brightness == Brightness.dark;
    if (n <= 0) return const [];
    if (dark) {
      switch (n) {
        case 1:
          return const [BoxShadow(color: Color(0xFF2E2823), spreadRadius: 1)];
        case 2:
          return const [
            BoxShadow(color: Color(0xFF3A332C), spreadRadius: 1),
            BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
          ];
        default:
          return const [
            BoxShadow(color: Color(0xFF4A4239), spreadRadius: 1),
            BoxShadow(color: Color(0x8C000000), blurRadius: 32, offset: Offset(0, 12)),
          ];
      }
    }
    switch (n) {
      case 1:
        return const [BoxShadow(color: Color(0x141B1714), blurRadius: 2, offset: Offset(0, 1))];
      case 2:
        return const [BoxShadow(color: Color(0x1A1B1714), blurRadius: 12, offset: Offset(0, 4))];
      default:
        return const [BoxShadow(color: Color(0x241B1714), blurRadius: 32, offset: Offset(0, 12))];
    }
  }
}
