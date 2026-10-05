import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../data/auth_repository_impl.dart';
import 'auth_submit_state.dart';

final signInControllerProvider =
    NotifierProvider<SignInController, AuthSubmitState>(
  SignInController.new,
);

/// Owns the sign-in attempt (PLAN.md §3.1).
///
/// The form's text lives in its own `TextEditingController`s — that is
/// view state, and moving it here would mean every keystroke crossing a
/// provider boundary to reach the field the reader is typing in. What
/// belongs here is the *attempt*: its in-flight flag, its outcome, and the
/// guarantee that a second submit while the first is running is dropped
/// rather than sent.
class SignInController extends Notifier<AuthSubmitState> {
  @override
  AuthSubmitState build() => AuthSubmitState.initial;

  /// Returns `true` when the session was established, which is the
  /// screen's cue to navigate. A failure never throws at the caller: it
  /// is captured in [AuthSubmitState.failure] for the screen to render.
  Future<bool> submit({
    required String email,
    required String password,
  }) async {
    if (state.submitting) return false;
    state = const AuthSubmitState(submitting: true);

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      state = AuthSubmitState.initial;
      return true;
    } on Failure catch (f) {
      state = AuthSubmitState(failure: f);
      return false;
    } catch (_) {
      // The repository maps everything it can; this is the belt for
      // whatever it could not recognise, so a reader never sees an
      // unhandled exception surface (§3.2 "unknown").
      state = const AuthSubmitState(
        failure: Failure(
          code: FailureCode.unknown,
          message: 'Something went wrong. Please try again.',
        ),
      );
      return false;
    }
  }

  /// Clears a failure the reader has acknowledged or corrected.
  void reset() {
    if (state.hasFailure) state = AuthSubmitState.initial;
  }
}
