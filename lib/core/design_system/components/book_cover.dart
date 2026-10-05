import 'package:flutter/material.dart';

import '../bookly_theme.dart';
import '../bookly_tokens.dart';

/// Book jacket card — 2:3 portrait, a 2px hinge strip on the spine edge, and
/// the directional clothbound spine shadow (DESIGN.md §Components · Cards).
class BookCover extends StatelessWidget {
  const BookCover({super.key, this.image, this.width = 120});

  /// The jacket. Null for a book whose creator never uploaded one — which
  /// still renders as a bound book in cloth rather than as a hole in the
  /// grid, because "no cover" is the ordinary case for a personal shelf
  /// and not an error worth announcing.
  final ImageProvider? image;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: width,
      height: width * 1.5,
      decoration: BoxDecoration(
        borderRadius: BooklyRadius.cover,
        boxShadow: BooklyElevation.level(context, 2),
      ),
      child: ClipRRect(
        borderRadius: BooklyRadius.cover,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image == null)
              // Blind-stamped cloth: no jacket, but the hinge and the
              // spine shadow below still fall across it, so the shape
              // reads as a book rather than as a placeholder.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.surfaceRaised, c.surfaceSunken],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: BooklyBorder.strong,
                    height: double.infinity,
                    color: c.accent.withValues(alpha: 0.4),
                  ),
                ),
              )
            else
              ColorFiltered(
                colorFilter: ColorFilter.matrix(<double>[
                  c.imageDim, 0, 0, 0, 0,
                  0, c.imageDim, 0, 0, 0,
                  0, 0, c.imageDim, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Image(image: image!, fit: BoxFit.cover),
              ),
            // The fold and hinge of a bound hardcover, catching the light.
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: BooklyBorder.strong,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0x66000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
