import 'package:flutter/material.dart';

import '../errors/failure.dart';
import '../design_system/bookly_design_system.dart';
import 'primary_button.dart';

/// A whole screen given over to one failure (PLAN.md §3.2).
///
/// The surface, not the toast: `FailureMapper` routes only
/// `FailureSurface.inline` codes here, and every message it can carry
/// is already the single sentence §3.2 allows — so nothing is shortened,
/// retried silently or replaced with a generic one on the way in. The
/// reader sees exactly what went wrong and, when the screen knows how to
/// try again, one button that does.
///
/// Used instead of a toast deliberately. A toast is a thing that
/// happened to a screen still sitting there; this *is* the screen now,
/// and pretending otherwise would leave the reader looking at an empty
/// page with a message sliding away at the top of it.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;

  /// Supplying this is how a screen says the operation is repeatable.
  ///
  /// Absent, the view renders no button rather than one that does
  /// nothing — a "Try again" that cannot is worse than no affordance,
  /// because the reader presses it and waits.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(BooklySpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BooklyIcon(
                BooklyIconKind.circleAlert,
                size: 40,
                color: colors.danger,
              ),
              const SizedBox(height: BooklySpace.lg),
              Text(
                failure.message,
                textAlign: TextAlign.center,
                style: BooklyType.bodyMd.copyWith(color: colors.text),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: BooklySpace.xl),
                PrimaryButton(label: 'Try again', onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
