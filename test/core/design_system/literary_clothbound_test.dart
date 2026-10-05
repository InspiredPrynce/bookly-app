import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookly/core/design_system/bookly_design_system.dart';

/// WCAG 2.x relative luminance.
double _luminance(Color color) {
  final argb = color.toARGB32();

  double channel(int shift) {
    final c = ((argb >> shift) & 0xFF) / 255.0;
    return c <= 0.04045
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}

/// WCAG contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// The font stack Google Fonts resolved onto, whatever exact spelling it uses.
String _stackOf(TextStyle style) =>
    [style.fontFamily, ...?style.fontFamilyFallback]
        .whereType<String>()
        .join(' ')
        .toLowerCase();

/// Pins Literary Clothbound as the system of record, so a silent regression
/// back to the superseded Raleway/oxblood kit fails loudly.
///
/// Spec: `branding/flows/*/literary_clothbound/DESIGN.md`.
void main() {
  group('palette', () {
    test('light canvas is Warm Paper, dark canvas is Deep Ink', () {
      expect(BooklyColors.light.bg, const Color(0xFFF6F1E7));
      expect(BooklyColors.dark.bg, const Color(0xFF12100E));
      expect(BooklyColors.light.text, const Color(0xFF1C1A17));
      expect(BooklyColors.dark.text, const Color(0xFFF4EFE6));
    });

    test('Burnished Amber is the accent — not the superseded oxblood', () {
      expect(BooklyColors.light.accent, BooklyBrand.gilt);
      expect(BooklyColors.light.accent, const Color(0xFFC8913D));
      expect(BooklyColors.dark.accent, BooklyBrand.giltDark);
      expect(BooklyColors.dark.accent, const Color(0xFFDFAC56));

      // Oxblood survives only as the editorial stamp of finality.
      expect(BooklyBrand.oxblood, const Color(0xFF7A2E2E));
      expect(BooklyColors.light.accent, isNot(BooklyBrand.oxblood));
    });

    test('primary text clears 7:1 on its own canvas in both modes', () {
      expect(contrast(BooklyColors.light.text, BooklyColors.light.bg),
          greaterThan(7.0));
      expect(
          contrast(BooklyColors.dark.text, BooklyColors.dark.bg), greaterThan(7.0));
    });

    test('the muted rule reads as a hairline, not a divider bar', () {
      // Muted Rule / Dark Rule — whisper-thin deckled-edge separators.
      expect(BooklyColors.light.border, const Color(0xFFE6DEC9));
      expect(BooklyColors.dark.border, const Color(0xFF2E2720));
    });
  });

  group('typography', () {
    test('display is Playfair Display, body is Literata, labels are Inter', () {
      expect(_stackOf(BooklyType.display), contains('playfair'));
      expect(_stackOf(BooklyType.headlineSm), contains('playfair'));
      expect(_stackOf(BooklyType.bodyMd), contains('literata'));
      expect(_stackOf(BooklyType.reading), contains('literata'));
      expect(_stackOf(BooklyType.labelMd), contains('inter'));
      expect(_stackOf(BooklyType.button), contains('inter'));
    });

    test('Raleway is gone from every tier', () {
      for (final style in <TextStyle>[
        BooklyType.display,
        BooklyType.displayMobile,
        BooklyType.headlineLg,
        BooklyType.headlineMd,
        BooklyType.headlineSm,
        BooklyType.bodyLg,
        BooklyType.bodyMd,
        BooklyType.bodySm,
        BooklyType.reading,
        BooklyType.labelLg,
        BooklyType.labelMd,
        BooklyType.labelSm,
        BooklyType.button,
      ]) {
        expect(
          _stackOf(style),
          isNot(contains('raleway')),
          reason: 'Literary Clothbound superseded the Raleway system',
        );
      }
    });

    test('labels are tracked wide for book-spine stamping', () {
      expect(BooklyType.labelLg.letterSpacing!, greaterThan(0));
      expect(BooklyType.labelMd.letterSpacing!,
          greaterThan(BooklyType.labelLg.letterSpacing!));
      expect(BooklyType.labelSm.letterSpacing!,
          greaterThan(BooklyType.labelMd.letterSpacing!));
    });

    test('reading sits at the night-paper line height of 1.75', () {
      expect(BooklyType.reading.height, closeTo(1.75, 0.001));
    });
  });

  group('shape discipline', () {
    test('base radius is the 0.25rem the spec insists on', () {
      expect(BooklyRadius.base, 4.0);
      expect(BooklyRadius.sm, 4.0);
      expect(BooklyRadius.xs, 2.0);
    });

    test('no container radius exceeds the 0.5rem ceiling', () {
      expect(BooklyRadius.lg, 8.0);
      expect(BooklyRadius.cover.topRight, const Radius.circular(4.0));
      expect(BooklyRadius.sheet.topLeft, const Radius.circular(8.0));
    });
  });

  testWidgets('depth is flat at level 1 and directional at level 2',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: BooklyTheme.light,
        home: Builder(builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        }),
      ),
    );

    // Surface layer: hierarchy from tone, never a floating shadow.
    expect(BooklyElevation.level(ctx, 0), isEmpty);
    expect(BooklyElevation.level(ctx, 1), isEmpty);

    // Clothbound spine: asymmetric, cast toward the hinge (-x, +y).
    final spine = BooklyElevation.level(ctx, 2);
    expect(spine, hasLength(2));
    expect(spine.first.offset.dx, lessThan(0));
    expect(spine.first.offset.dy, greaterThan(0));
  });

  testWidgets('button treatments resolve to the speced grounds',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: BooklyTheme.light,
        home: Builder(builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        }),
      ),
    );
    final style = Theme.of(ctx).filledButtonTheme.style!;

    // Cloth & Foil: Warm Charcoal ground, Soft Ivory type, gilt hairline.
    expect(style.backgroundColor?.resolve(const {}),
        const Color(0xFF1C1A17));
    expect(style.foregroundColor?.resolve(const {}),
        const Color(0xFFF4EFE6));
    expect(style.side?.resolve(const {})?.color, BooklyBrand.gilt);

    // Gilt Gold: burnished amber ground, deep ink type.
    final gilt = BooklyTheme.accent(ctx);
    expect(gilt.backgroundColor?.resolve(const {}), BooklyBrand.gilt);
    expect(gilt.foregroundColor?.resolve(const {}), BooklyBrand.ink);
  });

  testWidgets('inputs are a card-catalog bottom rule, not a four-sided box',
      (tester) async {
    await tester.pumpWidget(MaterialApp(theme: BooklyTheme.light, home: const Scaffold()));
    final input = Theme.of(tester.element(find.byType(Scaffold)))
        .inputDecorationTheme;

    expect(input.border, isA<UnderlineInputBorder>());
    expect(input.enabledBorder, isA<UnderlineInputBorder>());
    expect(
      (input.focusedBorder as UnderlineInputBorder).borderSide.color,
      BooklyColors.light.focusRing,
      reason: 'focus elevates the rule to Burnished Amber',
    );
    expect(
      (input.focusedBorder as UnderlineInputBorder).borderSide.width,
      BooklyBorder.inputBottom,
    );
  });
}
