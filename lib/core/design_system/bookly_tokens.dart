import 'package:flutter/material.dart';

/// Spacing — 4pt rhythm plus Literary Clothbound's named steps.
///
/// `space-xs`/`sm`/`md`/`lg`/`xl` are the spec's own tokens; the numeric
/// `s*` set is the same scale spelled out for layout arithmetic.
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

  /// Named steps from the spec.
  static const xs = s1; // 0.25rem
  static const sm = s2; // 0.5rem
  static const md = s4; // 1rem
  static const lg = s6; // 1.5rem
  static const xl = s10; // 2.5rem — section breaks and thematic dividers

  /// Classical book margins.
  static const gutter = 16.0; // 1rem
  static const screenMobile = 20.0; // 1.25rem outer margin
  static const screenTablet = 32.0; // 2rem
  static const screenDesktop = 48.0; // 3rem

  /// Kept for call sites written against the earlier scale.
  static const screenWide = screenTablet;
  static const tapMin = 44.0;
}

/// Shape language: architectural and disciplined. Extreme roundedness and
/// bubbly forms are prohibited — they erode literary authority.
abstract final class BooklyRadius {
  static const xs = 2.0; // 0.125rem
  static const sm = 4.0; // 0.25rem — the spec's base, for cards, inputs, buttons
  static const md = 6.0; // 0.375rem
  static const lg = 8.0; // 0.5rem — the ceiling for sheets
  static const xl = 12.0; // 0.75rem — the ornamental matting frame only
  static const full = 9999.0;

  /// Alias for the 0.25rem base radius the spec calls `rounded`.
  static const base = sm;

  static const rXs = BorderRadius.all(Radius.circular(xs));
  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
  static const rFull = BorderRadius.all(Radius.circular(full));

  /// Book cover: tight at the hinge, softened at the fore-edge — pressed
  /// book-cardstock, not a pill. Circles are reserved for profile portraits,
  /// progress rings and ribbon tags.
  static const cover = BorderRadius.only(
    topLeft: Radius.circular(xs),
    bottomLeft: Radius.circular(xs),
    topRight: Radius.circular(sm),
    bottomRight: Radius.circular(sm),
  );

  /// Full-bleed bottom sheet: 0.5rem, the spec's ceiling.
  static const sheet = BorderRadius.vertical(top: Radius.circular(lg));
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

  /// Long-form mobile reading column (~66 characters in Literata 18).
  static const readingMaxWidth = 640.0;

  /// The desktop library grid's ceiling, keeping copy to 65–75 characters.
  static const libraryMaxWidth = 1140.0;
}

abstract final class BooklyBorder {
  static const thin = 1.0;
  static const strong = 2.0;

  /// Card-catalog input underline (spec: 1.5px, never a four-sided box).
  static const inputBottom = 1.5;
}

/// Depth — tactile and physical, echoing paper, cloth and bookboard.
///
/// No synthetic drop shadows and no diffuse multi-colour blurs. Four levels
/// (DESIGN.md §Elevation):
///
/// 0. nothing
/// 1. **Surface layer** — flat, bounded by a hairline. Hierarchy comes from
///    tonal shift, not floating separation.
/// 2. **Clothbound spine** — a physical volume casting asymmetric,
///    directional light, as if side-lit on a shelf.
/// 3. **Overlay / floating sheet** — spine plus a broader warm ambient.
abstract final class BooklyElevation {
  /// Debossed field inputs: hot-metal press indentation into heavy stock.
  static const List<BoxShadow> inset = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      blurStyle: BlurStyle.inner,
    ),
  ];

  /// The clothbound spine shadow, lifted straight from the spec.
  static const List<BoxShadow> spine = [
    BoxShadow(color: Color(0x1F1C1A17), offset: Offset(-4, 6), blurRadius: 16, spreadRadius: -2),
    BoxShadow(color: Color(0x141C1A17), offset: Offset(-1, 2), blurRadius: 4),
  ];

  static const _darkRule = Color(0xFF2E2720);

  static List<BoxShadow> level(BuildContext c, int n) {
    if (n <= 1) return const [];
    if (Theme.of(c).brightness == Brightness.dark) {
      // Night Salon: separation comes from a hairline ring plus a tonal
      // shift, never a floating shadow.
      return n >= 3
          ? const [
              BoxShadow(color: _darkRule, spreadRadius: 1),
              BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
            ]
          : const [BoxShadow(color: _darkRule, spreadRadius: 1)];
    }
    if (n >= 3) {
      return const [
        ...spine,
        BoxShadow(color: Color(0x291C1A17), offset: Offset(-8, 16), blurRadius: 40, spreadRadius: -8),
      ];
    }
    return spine;
  }
}
