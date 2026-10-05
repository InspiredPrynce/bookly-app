import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design_system/bookly_design_system.dart';
import '../../../core/snackbar/present_failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bookly_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/sign_in_controller.dart';
import 'auth_scaffold.dart';

/// §3.1 — email · password → `/catalog`.
///
/// Every failure this screen can produce is toast-surface by
/// construction: Supabase never tells us whether an address exists, so
/// "no account" and "wrong password" both arrive as `invalidCredentials`,
/// which §3.2 puts in a bar rather than under a field. Hence no field
/// error plumbing here — a wrong password is wrong *for the pair*, and
/// accusing one half would accuse the wrong one half the time.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(signInControllerProvider.notifier).submit(
          email: _email.text,
          password: _password.text,
        );

    // `go`, not `push`: the account exists now, so the sign-in stack must
    // not be reachable by the system back gesture.
    if (!ok || !mounted) return;
    context.go(Routes.catalog);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(signInControllerProvider);

    /// Side effects belong in a listener, never in `build` — raising a
    /// toast from the build method would fire again on every re-render
    /// of this screen while the failure sits there.
    ref.listen(signInControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure != null && !identical(failure, previous?.failure)) {
        presentFailure(failure);
      }
    });

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to reach your reading circles.',
      footer: Column(
        children: [
          TextButton(
            onPressed: () => context.push(Routes.forgotPassword),
            child: const Text('Forgot your password?'),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'New to Bookly?',
                style: BooklyType.bodySm.copyWith(color: colors.textSecondary),
              ),
              TextButton(
                onPressed: () => context.push(Routes.register),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BooklyTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: BooklySpace.lg),
              BooklyTextField(
                label: 'Password',
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                validator: (v) => Validators.notEmpty(
                  v,
                  message: 'Enter your password.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BooklySpace.xl),
        PrimaryButton(
          label: 'Sign in',
          submitting: state.submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
