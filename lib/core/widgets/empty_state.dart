import 'package:flutter/material.dart';

import '../design_system/bookly_design_system.dart';

/// A screen that loaded correctly and has nothing in it.
///
/// Deliberately *not* an [ErrorView]: those differ on the question that
/// matters to the reader — should they try again? This one says no, and
/// a Retry button on top of "there is nothing here" would be asking them
/// to do something with no chance of a different answer.
///
/// No icon by default. An absence is not a state of the world that
/// needs a glyph, and the title and sentence carry it; [icon] is there
/// for the screens where a picture genuinely helps say what kind of
/// emptiness this is.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.action,
  });

  final String title;
  final String message;

  final BooklyIconKind? icon;

  /// The one thing a reader can do about an empty list — create the
  /// first item, or clear a filter. Absent when there is nothing
  /// sensible to offer, for the same reason [ErrorView] omits its
  /// button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(BooklySpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                BooklyIcon(icon!, size: 36, color: colors.textTertiary),
                const SizedBox(height: BooklySpace.lg),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: BooklyType.headlineSm.copyWith(color: colors.text),
              ),
              const SizedBox(height: BooklySpace.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: BooklyType.bodySm.copyWith(
                  color: colors.textSecondary,
                  height: 1.55,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: BooklySpace.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
