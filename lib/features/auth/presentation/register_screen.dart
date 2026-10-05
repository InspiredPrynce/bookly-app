import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design_system/bookly_design_system.dart';
import '../../../core/errors/failure_code.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/failure_surface.dart';
import '../../../core/snackbar/present_failure.dart';
import '../../../core/utils/avatar_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/avatar_field.dart';
import '../../../core/widgets/bookly_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_submit_state.dart';
import '../application/register_controller.dart';
import 'auth_scaffold.dart';

/// §3.1 — name · email · password · optional avatar and bio →
/// `profiles` row → auto sign-in → `/catalog`.
///
/// The only one of the three auth screens with **inline** failures. A
/// password below policy is wrong *inside that field*, so it is rendered
/// there; everything else this form can fail with — taken address,
/// offline, throttle, unknown — names no field and goes up top. The
/// listener skips the inline ones deliberately, so a weak password is
/// never announced twice: once under the field where it can be fixed,
/// and again as a bar where it cannot.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _bio = TextEditingController();

  /// Mirror of what the controller holds, kept here only so the preview
  /// rebuilds — the controller's field is not observable, and a chosen
  /// photo that fails to appear the instant it is picked reads as a
  /// failed pick.
  Uint8List? _avatar;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final bytes = await pickAndCompressAvatar();
    if (bytes == null || !mounted) return; // cancelled is not a failure
    ref.read(registerControllerProvider.notifier).setAvatar(bytes);
    setState(() => _avatar = bytes);
  }

  void _clearAvatar() {
    ref.read(registerControllerProvider.notifier).setAvatar(null);
    setState(() => _avatar = null);
  }

  /// The message for the field [code] owns, when the outstanding failure
  /// is one that belongs under a field at all.
  ///
  /// Resolved through a method rather than a promoted local because the
  /// answer depends on two things — the code being an inline one, and it
  /// being *this* field's code — and each `build` needs both answers
  /// independently for the email and password inputs.
  String? _inlineFor(FailureCode code) {
    final failure = state.failure;
    if (failure == null) return null;
    if (FailureMapper.surface(failure.code) != FailureSurface.inline) {
      return null;
    }
    return failure.code == code ? failure.message : null;
  }

  AuthSubmitState get state => ref.watch(registerControllerProvider);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bio = _bio.text.trim();

    final ok = await ref.read(registerControllerProvider.notifier).submit(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          bio: bio.isEmpty ? null : bio,
        );

    // `go`, not `push`: the account exists, so the sign-up stack must not
    // survive a system back gesture.
    if (!ok || !mounted) return;
    context.go(Routes.catalog);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    ref.listen(registerControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || identical(failure, previous?.failure)) return;
      if (FailureMapper.surface(failure.code) == FailureSurface.inline) return;
      presentFailure(failure);
    });

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'A name, an email, a password — and the shelf is yours.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: BooklyType.bodySm.copyWith(color: colors.textSecondary),
          ),
          TextButton(
            onPressed: () => context.go(Routes.login),
            child: const Text('Sign in'),
          ),
        ],
      ),
      children: [
        AvatarField(
          bytes: _avatar,
          onPick: _pickAvatar,
          onClear: _clearAvatar,
        ),
        const SizedBox(height: BooklySpace.lg),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BooklyTextField(
                label: 'Name',
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  final empty = Validators.notEmpty(
                    v,
                    message: 'Enter the name your circle will see.',
                  );
                  if (empty != null) return empty;
                  if ((v ?? '').trim().length > Validators.nameMaxLength) {
                    return 'Keep it to ${Validators.nameMaxLength} '
                        'characters or fewer.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: BooklySpace.lg),
              BooklyTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                errorText: _inlineFor(FailureCode.noAccount),
                validator: Validators.email,
              ),
              const SizedBox(height: BooklySpace.lg),
              BooklyTextField(
                label: 'Password',
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                helperText:
                    'At least ${Validators.passwordMinLength} characters.',
                errorText: _inlineFor(FailureCode.weakPassword),
                validator: Validators.password,
              ),
              const SizedBox(height: BooklySpace.lg),
              BooklyTextField(
                label: 'Bio (optional)',
                controller: _bio,
                hint: 'What do you like to read?',
                maxLines: 3,
                validator: (v) =>
                    (v ?? '').trim().length > Validators.bioMaxLength
                        ? 'Keep it to ${Validators.bioMaxLength} characters.'
                        : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: BooklySpace.xl),
        PrimaryButton(
          label: 'Create account',
          submitting: state.submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

