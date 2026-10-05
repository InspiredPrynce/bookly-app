import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../data/auth_repository_impl.dart';
import 'auth_submit_state.dart';

final passwordResetControllerProvider =
    NotifierProvider<PasswordResetController, AuthSubmitState>(
  PasswordResetController.new,
);

/// Owns the password-reset request (PLAN.md §3.1).
///
/// **Email-only, no OTP screen.** This sends the mail and stops — the
/// reader never types a code, so there is no second step to own here, and
/// success is reported as a plain confirmation with no blame (§3.2).
///
/// On success the form is *not* reset: the reader stays on the screen
/// reading the confirmation, so wiping the address they just used would
/// only cost them a retype if they mean to send it again.
class PasswordResetController extends Notifier<AuthSubmitState> {
  @override
  AuthSubmitState build() => AuthSubmitState.initial;

  /// `true` when the mail was accepted — whether or not an account exists
  /// for it. Answering otherwise would turn this endpoint into an account
  /// oracle.
  Future<bool> submit({required String email}) async {
    if (state.submitting) return false;
    state = const AuthSubmitState(submitting: true);

    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email: email);
      state = AuthSubmitState.initial;
      return true;
    } on Failure catch (f) {
      state = AuthSubmitState(failure: f);
      return false;
    } catch (_) {
      state = const AuthSubmitState(
        failure: Failure(
          code: FailureCode.unknown,
          message: 'Something went wrong. Please try again.',
        ),
      );
      return false;
    }
  }

  void reset() {
    if (state.hasFailure) state = AuthSubmitState.initial;
  }
}
