import 'package:flutter/material.dart';

import '../bookly_theme.dart';
import '../bookly_typography.dart';
import 'bookly_mark.dart';

/// Mark + "Bookly" wordmark (Playfair Display 600, -0.02em).
///
/// Minimum lockup width ~96; below that use [BooklyMark] alone.
///
/// Horizontal, for app bars and footers. Where the design stacks the mark
/// above the wordmark — the splash masthead — compose [BooklyMark] and the
/// wordmark directly rather than rotating this.
class BooklyLockup extends StatelessWidget {
  const BooklyLockup({super.key, this.markSize = 40, this.color});

  /// Mark box size in logical px. Wordmark scales with it (0.59x).
  final double markSize;

  /// Override wordmark + ring colour.
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
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
