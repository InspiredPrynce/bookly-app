import 'package:flutter/material.dart';
import 'bookly_theme.dart';
import 'bookly_tokens.dart';
import 'bookly_typography.dart';

/// Avatar with 2px member-color ring and 2px gap (gap = scaffold bg).
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
                  style: BooklyType.caption.copyWith(
                      color: c.text, fontWeight: FontWeight.w700, fontSize: size * 0.32),
                )
              : null,
        ),
      ),
    );
  }
}

class ReaderProgress {
  const ReaderProgress({required this.memberIndex, required this.progress, this.name});
  final int memberIndex;

  /// 0..1
  final double progress;
  final String? name;
}

/// One track, one marker per reader in member color. Max 6 readers.
class ReadingProgressBar extends StatelessWidget {
  const ReadingProgressBar({super.key, required this.readers});
  final List<ReaderProgress> readers;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const marker = 14.0;
    final summary = readers
        .map((r) => '${r.name ?? 'Reader ${r.memberIndex + 1}'} ${(r.progress * 100).round()} percent')
        .join(', ');
    return Semantics(
      label: 'Reading progress: $summary',
      child: ExcludeSemantics(
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          return SizedBox(
            height: marker,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.surfaceSunken,
                    borderRadius: BooklyRadius.rFull,
                  ),
                ),
                for (final r in readers.take(6))
                  Positioned(
                    left: (w - marker) * r.progress.clamp(0.0, 1.0),
                    child: Container(
                      width: marker,
                      height: marker,
                      decoration: BoxDecoration(
                        color: c.member(r.memberIndex),
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

enum BubbleKind { own, friend, gemini }

/// Chat bubble: own / friend / Gemini.
class BooklyChatBubble extends StatelessWidget {
  const BooklyChatBubble({super.key, required this.kind, required this.text, this.author});
  final BubbleKind kind;
  final String text;
  final String? author;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isOwn = kind == BubbleKind.own;
    final isAi = kind == BubbleKind.gemini;
    final bg = isAi ? c.aiSurface : (isOwn ? c.accentSubtle : c.surface);
    final fg = isAi ? c.aiText : (isOwn ? c.accentSubtleText : c.text);
    final border = isAi ? Border.all(color: c.aiBorder) : (isOwn ? null : Border.all(color: c.border));
    const big = Radius.circular(16);
    const tight = Radius.circular(4);
    final radius = BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: isOwn ? big : tight,
      bottomRight: isOwn ? tight : big,
    );
    final label = isAi ? 'GEMINI' : author?.toUpperCase();
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Semantics(
          label: '${isAi ? 'Gemini, AI' : (author ?? (isOwn ? 'You' : 'Friend'))}: $text',
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(BooklySpace.s4),
              decoration: BoxDecoration(color: bg, borderRadius: radius, border: border),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) ...[
                    Text(label, style: BooklyType.overline.copyWith(color: fg.withValues(alpha: 0.8))),
                    const SizedBox(height: BooklySpace.s1),
                  ],
                  Text(text, style: BooklyType.body.copyWith(color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
