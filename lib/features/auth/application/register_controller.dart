import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../data/auth_repository_impl.dart';
import 'auth_submit_state.dart';

final registerControllerProvider =
    NotifierProvider<RegisterController, AuthSubmitState>(
  RegisterController.new,
);

/// Owns the register attempt (PLAN.md §3.1).
///
/// [avatarBytes] is held here rather than in the form because it is the
/// one input the reader can submit without being able to re-enter cheaply:
/// dismissing the picker to retry a failed submit would lose the image
/// they chose. Everything else on the form is text they can retype.
class RegisterController extends Notifier<AuthSubmitState> {
  @override
  AuthSubmitState build() => AuthSubmitState.initial;

  Uint8List? avatarBytes;

  /// `true` when the account exists *and* a session was established —
  /// which, with email confirmation off, is the §3.1 path straight to
  /// the catalog.
  Future<bool> submit({
    required String name,
    required String email,
    required String password,
    String? bio,
  }) async {
    if (state.submitting) return false;
    state = const AuthSubmitState(submitting: true);

    try {
      await ref.read(authRepositoryProvider).signUp(
            name: name,
            email: email,
            password: password,
            bio: bio,
            avatarBytes: avatarBytes,
          );
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

  /// Called by the avatar picker. Null clears a chosen-but-rejected image.
  void setAvatar(Uint8List? bytes) => avatarBytes = bytes;

  void reset() {
    avatarBytes = null;
    if (state.hasFailure) state = AuthSubmitState.initial;
  }
}
