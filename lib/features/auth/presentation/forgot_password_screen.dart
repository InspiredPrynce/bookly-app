import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design_system/bookly_design_system.dart';
import '../../../core/snackbar/bookly_toast.dart';
import '../../../core/snackbar/present_failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bookly_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/password_reset_controller.dart';
import 'auth_scaffold.dart';

/// §3.1 — **email-only, no OTP screen.** Enter email → confirmation copy →
/// done.
///
/// There is no code to type because the reader never sees one: the mail
/// carries a link, and the link does the work. That makes this the only
/// auth screen whose *success* is the interesting state rather than its
/// failure, so the confirmation is rendered persistently as well as
/// toasted — a bar disappears after four seconds, and a reader who looks
/// away has then lost the only evidence the request worked.
///
/// The copy never says whether an account exists. Answering that would
/// turn this endpoint into an oracle for anyone who wants to know who has
/// signed up, and §3.2 asks for confirmation with no blame regardless.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok =
        await ref.read(passwordResetControllerProvider.notifier).submit(
              email: _email.text,
            );
    if (!ok || !mounted) return;

    setState(() => _sent = true);
    BooklyToast.success('Check your email for a link to reset your password.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(passwordResetControllerProvider);

    ref.listen(passwordResetControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure != null && !identical(failure, previous?.failure)) {
        presentFailure(failure);
      }
    });

    return AuthScaffold(
      title: 'Reset your password',
      subtitle:
          "Enter the address you signed up with and we'll send a link. "
          'There is no code to copy.',
      footer: TextButton(
        onPressed: () => context.go(Routes.login),
        child: const Text('Back to sign in'),
      ),
      children: [
        Form(
          key: _formKey,
          child: BooklyTextField(
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _submit(),
            validator: Validators.email,
          ),
        ),
        const SizedBox(height: BooklySpace.xl),
        PrimaryButton(
          label: 'Send reset link',
          submitting: state.submitting,
          onPressed: _submit,
        ),
        if (_sent) ...[
          const SizedBox(height: BooklySpace.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(BooklySpace.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BooklyRadius.rSm,
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'On its way. It may take a minute to arrive — and if it '
              'has not, check the address above before sending again.',
              style: BooklyType.bodySm.copyWith(
                color: colors.textSecondary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
