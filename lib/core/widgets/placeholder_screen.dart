import 'package:flutter/material.dart';

import '../design_system/bookly_design_system.dart';

/// A destination whose screen has not been built yet.
///
/// The route table is complete from the first day (PLAN.md §1.5) because
/// deep-link handling is a *shape*, not a screen: a tapped notification must
/// resolve to a path whether or not the surface behind it exists. Each
/// placeholder is replaced as its feature lands in Phases 1–3, and the route
/// itself never changes.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.phase});

  /// The route's human name — shown verbatim, so the string that identifies
  /// the surface in the table is the string on screen when it is missing.
  final String title;

  /// Which phase supplies the real screen.
  final String? phase;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BooklySpace.screenMobile,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BooklyMark(size: 48),
              const SizedBox(height: BooklySpace.lg),
              Text(
                phase == null ? 'Not built yet' : 'Arrives in $phase',
                style: BooklyType.labelMd.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
