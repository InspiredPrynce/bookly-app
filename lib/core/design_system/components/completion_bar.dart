import 'package:flutter/material.dart';

import '../bookly_theme.dart';
import '../bookly_tokens.dart';

/// How far through a list of things the reader is — §5.7's "links
/// completed ÷ total", and the same shape any other count wants later.
///
/// Deliberately *not* `ReadingProgressBar`: that component draws one
/// marker per **member** on a shared track, which is §6.3's view of a
/// circle and has nothing to say about one reader's own ratio. Reusing
/// it here would mean passing a fake member list to stand in for a
/// single number. One track, one fill.
///
/// ## It says nothing, on purpose
///
/// §5.7 pairs the bar with a count — "3 of 7 completed" — and that
/// sentence is both what a reader reads and what a screen reader should
/// hear. Giving the bar its own label would announce the same words
/// twice, once for the number and once for a picture of it, so the bar
/// carries no semantics and the call site is expected to wrap it in
/// [ExcludeSemantics] beside visible text that does.
///
/// A bar alone would be a shape with no meaning; there is no supported
/// use of one here.
class CompletionBar extends StatelessWidget {
  const CompletionBar({super.key, required this.value});

  /// 0..1.
  ///
  /// Clamped rather than asserted. A count from the server that runs
  /// ahead of the list beside it should render full, not paint over the
  /// edge of the row.
  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return ClipRRect(
      borderRadius: BooklyRadius.rFull,
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.surfaceSunken),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: ColoredBox(color: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}
