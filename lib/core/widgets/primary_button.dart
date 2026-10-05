import 'package:flutter/material.dart';

import '../design_system/bookly_design_system.dart';

/// Bookly's one primary action.
///
/// Deliberately behaviour-only: colour, radius, type and the 44pt minimum
/// tap target all come from `BooklyTheme`'s `filledButtonTheme`, so every
/// primary button in the app is identical without each call site restyling
/// it. What this adds is the *submitting* state a form needs and a bare
/// `FilledButton` has no opinion about:
///
/// * a second tap must not fire a second request — the button disables
///   itself while in flight, not merely when the caller says so;
/// * progress appears **in place of** the label, so the layout the reader
///   is aiming at does not shift under their thumb mid-tap;
/// * the label survives into semantics while it is gone visually, because
///   a spinner has no accessible name of its own.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.submitting = false,
    this.accent = false,
  });

  /// The action's wording. Also its accessible name while submitting.
  final String label;

  /// `null` disables the button — a caller uses this for "form incomplete".
  final VoidCallback? onPressed;

  /// Shows progress and blocks further taps.
  final bool submitting;

  /// Gilt Gold rather than the default cloth (`BooklyTheme.accent`), for
  /// primary conversion events.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final blocked = submitting || onPressed == null;

    return FilledButton(
      style: accent ? BooklyTheme.accent(context) : null,
      onPressed: blocked ? null : onPressed,
      child: submitting
          ? Semantics(
              label: '$label — in progress',
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    accent
                        ? BooklyBrand.ink
                        : context.colors.textOnAccent,
                  ),
                ),
              ),
            )
          : Text(label),
    );
  }
}
