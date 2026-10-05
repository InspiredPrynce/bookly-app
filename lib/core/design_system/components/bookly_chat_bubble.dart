import 'package:flutter/material.dart';

import '../bookly_theme.dart';
import '../bookly_tokens.dart';
import '../bookly_typography.dart';
import 'bubble_kind.dart';

/// Chat bubble: own / friend / Gemini.
///
/// Gemini bubbles are labelled **in text** ("GEMINI" set as a `labelLg`
/// caption), never distinguished by colour alone (DESIGN.md §11).
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
    // Literary Clothbound §Shapes: 0.25rem base, no bubbly forms. The tail
    // corner drops to 0.125rem so the bubble reads as a card, not a balloon.
    const big = BooklyRadius.rSm;
    const tight = BooklyRadius.rXs;
    final radius = BorderRadius.only(
      topLeft: big.topLeft,
      topRight: big.topRight,
      bottomLeft: isOwn ? big.bottomLeft : tight.bottomLeft,
      bottomRight: isOwn ? tight.bottomRight : big.bottomRight,
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
                    Text(
                      label.toUpperCase(),
                      style: BooklyType.labelLg.copyWith(color: fg.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: BooklySpace.xs),
                  ],
                  Text(text, style: BooklyType.bodyMd.copyWith(color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
