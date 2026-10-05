import 'package:flutter/material.dart';

import '../../../core/design_system/bookly_design_system.dart';

/// The chrome shared by all three auth destinations (PLAN.md §3.1).
///
/// Sign in, create account and reset password are one surface with three
/// contents: they have the same background, the same masthead, the same
/// gutters, and the same rule for where the primary action sits. Written
/// three times, those would drift — one screen would gain a wider gutter
/// and the reader crossing from register to sign in would feel the app
/// move under them.
///
/// Deliberately *not* `core/widgets/app_scaffold`: that one is the
/// signed-in shell's navigation frame, and an auth screen that has no
/// account yet must not render the chrome that belongs to having one.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  /// Headline, in the literary serif.
  final String title;

  /// One line of plain body copy saying what this screen is for.
  final String subtitle;

  /// The form itself, in order. Stretched to the column's width so every
  /// field and button share one left edge.
  final List<Widget> children;

  /// Links to the sibling screens — sign in ↔ register ↔ reset.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            /// Capped rather than fixed: the form reads comfortably at
            /// 480, and on a phone this resolves to the screen minus its
            /// gutters instead of fighting them.
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: BooklySpace.screenMobile,
                vertical: BooklySpace.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BooklyLockup(markSize: 36),
                    const SizedBox(height: BooklySpace.xl),
                    Text(
                      title,
                      style: BooklyType.headlineMd.copyWith(color: colors.text),
                    ),
                    const SizedBox(height: BooklySpace.sm),
                    Text(
                      subtitle,
                      style: BooklyType.bodySm.copyWith(
                        color: colors.textSecondary,
                        height: 1.55,
                      ),
                    ),
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
        ),
      ),
    );
  }
}
