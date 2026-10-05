import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../design_system/bookly_design_system.dart';

/// The circular portrait slot used wherever a reader chooses an avatar.
///
/// Two call sites by design: register (§3.1, optional at sign-up) and
/// `EditProfileScreen` (§3.3). It was written inside the register screen
/// first and lifted here the moment the second caller appeared, because
/// two copies of a picker drift — one grows a "Remove" button and the
/// other does not, and the reader meets both.
///
/// ## Precedence
///
/// [bytes] (just picked, not yet uploaded) beats [imageUrl] (already
/// stored). That is what makes an optimistic save work: the portrait the
/// reader chose appears instantly, before the upload has finished, and
/// falls back to the stored one if the save is rolled back (§3.3).
///
/// ## No camera glyph
///
/// Bookly vendors six Lucide icons (§4.3) and a camera is not among
/// them — and a word is clearer than a glyph here anyway. The `+` in an
/// empty circle is the printed convention for "affix portrait", not an
/// icon.
class AvatarField extends StatelessWidget {
  const AvatarField({
    super.key,
    this.bytes,
    this.imageUrl,
    required this.onPick,
    this.onClear,
  });

  /// A newly chosen image, still local.
  final Uint8List? bytes;

  /// The stored portrait's public URL, if one exists.
  final String? imageUrl;

  final VoidCallback onPick;

  /// Omitted where removing a portrait is not offered.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasImage = bytes != null || (imageUrl?.isNotEmpty ?? false);

    return Column(
      children: [
        InkWell(
          onTap: onPick,
          customBorder: const CircleBorder(),
          child: Container(
            width: 96,
            height: 96,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceSunken,
              border: Border.all(color: colors.borderStrong),
            ),
            child: bytes != null
                ? Image.memory(bytes!, fit: BoxFit.cover)
                : hasImage
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        // A portrait that fails to load falls back to the
                        // empty slot rather than to a broken-image glyph:
                        // the reader still has a name and a bio, and a
                        // red cross beside them reads as an account
                        // problem when it is only a CDN hiccup.
                        errorBuilder: (_, _, _) =>
                            const _PlaceholderGlyph(),
                      )
                    : const _PlaceholderGlyph(),
          ),
        ),
        const SizedBox(height: BooklySpace.xs),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: onPick,
              child: Text(hasImage ? 'Change photo' : 'Add a photo'),
            ),
            if (hasImage && onClear != null)
              TextButton(onPressed: onClear, child: const Text('Remove')),
          ],
        ),
      ],
    );
  }
}

class _PlaceholderGlyph extends StatelessWidget {
  const _PlaceholderGlyph();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '+',
        style: BooklyType.headlineLg.copyWith(
          color: context.colors.textTertiary,
        ),
      ),
    );
  }
}
