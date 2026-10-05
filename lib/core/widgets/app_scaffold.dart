import 'package:flutter/material.dart';

import '../design_system/bookly_design_system.dart';

/// The frame every signed-in screen shares (PLAN.md §1.3).
///
/// Background, safe area, the 480 cap, the masthead and the gutters —
/// the things a reader crossing from Catalog to Settings should not
/// notice have changed. Written per screen, one would gain a different
/// gutter and the app would appear to move under them.
///
/// The distinction from `AuthScaffold` is not cosmetic: that one stacks
/// the lockup above the headline with no actions, because a reader who
/// has not signed in has nowhere to go *to*. Here the lockup and the
/// screen's own actions sit on one line — a masthead with a way out of
/// it — which is what makes these screens read as one place rather than
/// a sequence of pages.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.children,
    this.footer,
    this.floatingActionButton,
  });

  /// Screen headline, in the literary serif.
  final String title;

  /// One line of plain body copy saying what this screen is for.
  final String? subtitle;

  /// Trailing, right-aligned, on the masthead line — the screen's own
  /// primary action ("New book") rather than navigation, which lives in
  /// the route table and arrives with the screens themselves.
  final List<Widget> actions;

  /// The screen's body, in order. Stretched to the column's width so
  /// every row and field shares one left edge.
  final List<Widget> children;

  /// Links to sibling screens, pinned after the body — the counterpart
  /// to `AuthScaffold`'s footer, for screens whose action is a way out
  /// rather than a thing to fill in.
  final Widget? footer;

  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            /// Capped rather than fixed: reads comfortably at 480 and, on
            /// a phone, resolves to the screen minus its gutters.
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: BooklySpace.screenMobile,
                vertical: BooklySpace.lg,
              ),
              children: [
                Row(
                  children: [
                    const BooklyLockup(markSize: 28),
                    const Spacer(),
                    if (actions.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ),
                const SizedBox(height: BooklySpace.xl),
                Text(
                  title,
                  style: BooklyType.headlineMd.copyWith(color: colors.text),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: BooklySpace.sm),
                  Text(
                    subtitle!,
                    style: BooklyType.bodySm.copyWith(
                      color: colors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
                const SizedBox(height: BooklySpace.xl),
                ...children,
                if (footer != null) ...[
                  const SizedBox(height: BooklySpace.lg),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
