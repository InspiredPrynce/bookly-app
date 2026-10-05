import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'bookly_colors.dart';
import 'bookly_theme.dart';
import 'bookly_typography.dart';

/// Vector Bookly mark. Crisp at any size, theme-aware, no asset needed.
///
/// Two circles = private circle. Lens = shared page. Spine = open book.
/// Below 32 logical px: spine dropped, stroke thickened (small cut).
class BooklyMark extends StatelessWidget {
  const BooklyMark({super.key, this.size = 48, this.ringColor, this.lensColor});

  final double size;

  /// Override ring color. Defaults: ink (light) / paper (dark).
  final Color? ringColor;

  /// Override lens color. Defaults: oxblood (light) / #C0525E (dark).
  final Color? lensColor;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Semantics(
      label: 'Bookly',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(
          ring: ringColor ?? (dark ? BooklyBrand.paper : BooklyBrand.ink),
          lens: lensColor ?? (dark ? BooklyBrand.oxbloodDarkLens : BooklyBrand.oxblood),
          size: size,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.ring, required this.lens, required this.size});
  final Color ring, lens;
  final double size;

  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 120; // 120-unit design grid
    const r = 34.0;
    final a = Offset(46 * k, 60 * k);
    final b = Offset(74 * k, 60 * k);
    final small = size < 32;
    // ~1.6 logical px hairline at small sizes, 3 units at large.
    final strokeUnits = math.max(3.0, 192 / size);

    final pa = Path()..addOval(Rect.fromCircle(center: a, radius: r * k));
    final pb = Path()..addOval(Rect.fromCircle(center: b, radius: r * k));

    var lensPath = Path.combine(PathOperation.intersect, pa, pb);
    if (!small) {
      // Spine = true knockout (transparent), works on any ground.
      final spine = Path()
        ..addRect(Rect.fromLTWH(59 * k, 38 * k, 2 * k, 44 * k));
      lensPath = Path.combine(PathOperation.difference, lensPath, spine);
    }

    canvas.drawPath(lensPath, Paint()..color = lens..isAntiAlias = true);

    final stroke = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeUnits * k
      ..isAntiAlias = true;
    canvas.drawCircle(a, r * k, stroke);
    canvas.drawCircle(b, r * k, stroke);
  }

  @override
  bool shouldRepaint(_MarkPainter o) =>
      o.ring != ring || o.lens != lens || o.size != size;
}

/// Mark + "Bookly" wordmark (Raleway 700, -0.02em).
/// Minimum lockup width ~96; below that use [BooklyMark] alone.
class BooklyLockup extends StatelessWidget {
  const BooklyLockup({super.key, this.markSize = 40, this.color});

  /// Mark box size in logical px. Wordmark scales with it (0.59x).
  final double markSize;

  /// Override wordmark + ring color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.text;
    final fs = markSize * 0.59;
    return Semantics(
      label: 'Bookly',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BooklyMark(size: markSize, ringColor: color),
            SizedBox(width: markSize * 0.12),
            Text(
              'Bookly',
              style: BooklyType.display.copyWith(
                fontSize: fs,
                height: 1.0,
                letterSpacing: -fs * 0.02,
                fontWeight: FontWeight.w700,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
