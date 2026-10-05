import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bookly_colors.dart';
import '../bookly_theme.dart';

/// Vector Bookly mark. Crisp at any size, theme-aware, no asset needed.
///
/// Two circles = private circle. Lens = shared page. Spine = open book.
/// Below 32 logical px: spine dropped, stroke thickened (small cut).
///
/// The lens is **Burnished Amber** — Literary Clothbound's primary mark of
/// distinction — rather than the superseded system's oxblood.
class BooklyMark extends StatelessWidget {
  const BooklyMark({super.key, this.size = 48, this.ringColor, this.lensColor});

  final double size;

  /// Override ring colour. Defaults: ink (light) / paper (dark).
  final Color? ringColor;

  /// Override lens colour. Defaults: Burnished Amber (light) / gilt (dark).
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
          lens: lensColor ?? (dark ? BooklyBrand.giltDark : BooklyBrand.gilt),
          size: size,
        ),
      ),
    );
  }
}

/// Painter for [BooklyMark]. Private to this file — it is the mark's
/// implementation, not a sibling type.
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
