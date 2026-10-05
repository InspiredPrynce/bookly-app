import 'package:flutter/material.dart';

import '../bookly_theme.dart';
import '../bookly_typography.dart';

/// Avatar with a 2px member-colour ring and a 2px gap (gap = scaffold bg).
///
/// The ring colour is an identity cue, never the only one: [initials] (or a
/// photo) always accompany it, and a [Semantics] label is always present
/// (DESIGN.md §11).
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.memberIndex,
    this.size = 40,
    this.image,
    this.initials,
    this.beyondSix = false,
  });

  final int memberIndex;
  final double size;
  final ImageProvider? image;
  final String? initials;

  /// Circles larger than 6: dashed-style ring cue (placeholder = lighter ring).
  final bool beyondSix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ring = c.member(memberIndex);
    return Semantics(
      label: initials ?? 'Member ${memberIndex + 1}',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: beyondSix ? ring.withValues(alpha: 0.6) : ring, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surfaceSunken,
            image: image == null ? null : DecorationImage(image: image!, fit: BoxFit.cover),
          ),
          alignment: Alignment.center,
          child: image == null
              ? Text(
                  (initials ?? '').toUpperCase(),
                  style: BooklyType.labelMd.copyWith(
                    color: c.text,
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.32,
                    letterSpacing: size * 0.32 * 0.08,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
