import 'package:flutter/material.dart';

import '../bookly_theme.dart';
import '../bookly_tokens.dart';

/// Book cover with brand radii, elevation, and dark-mode dimming.
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
        boxShadow: BooklyElevation.level(context, 1),
      ),
      child: ClipRRect(
        borderRadius: BooklyRadius.cover,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(<double>[
            c.imageDim, 0, 0, 0, 0,
            0, c.imageDim, 0, 0, 0,
            0, 0, c.imageDim, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Image(image: image, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
