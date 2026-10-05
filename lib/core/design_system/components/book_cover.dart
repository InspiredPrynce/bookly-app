import 'package:flutter/material.dart';

import '../bookly_theme.dart';
import '../bookly_tokens.dart';

/// Book jacket card — 2:3 portrait, a 2px hinge strip on the spine edge, and
/// the directional clothbound spine shadow (DESIGN.md §Components · Cards).
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.image, this.width = 120});

  final ImageProvider image;
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
            ColorFiltered(
              colorFilter: ColorFilter.matrix(<double>[
                c.imageDim, 0, 0, 0, 0,
                0, c.imageDim, 0, 0, 0,
                0, 0, c.imageDim, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: Image(image: image, fit: BoxFit.cover),
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
