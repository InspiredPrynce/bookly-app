import 'package:flutter/material.dart';

import '../bookly_theme.dart';
import '../bookly_tokens.dart';

/// One reader's position, for [ReadingProgressBar].
///
/// Kept beside the bar that consumes it — there is no other reader of this
/// type (PLAN.md §0.1: no two *unrelated* classes in one file).
class ReaderProgress {
  const ReaderProgress({required this.memberIndex, required this.progress, this.name});

  final int memberIndex;

  /// 0..1
  final double progress;

  final String? name;
}

/// One track, one marker per reader in member colour. Max 6 readers.
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
