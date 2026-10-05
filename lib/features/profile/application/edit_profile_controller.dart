import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../data/profile_repository_impl.dart';
import 'edit_profile_state.dart';

final editProfileControllerProvider =
    NotifierProvider<EditProfileController, EditProfileState>(
  EditProfileController.new,
);

/// Drives `EditProfileScreen` (PLAN.md §3.3).
///
/// The `TextField`s keep their own controllers on the screen: moving
/// every keystroke across a provider boundary to reach the field the
/// reader is typing in buys nothing and costs a rebuild. What belongs
/// here is what outlives a keystroke — reading the row, holding the
/// committed portrait, running the save, and rolling the portrait back
/// when the save fails.
class EditProfileController extends Notifier<EditProfileState> {
  @override
  EditProfileState build() => const EditProfileState();

  /// Reads the signed-in reader's row, replacing whatever was here.
  ///
  /// Replacing rather than reusing is deliberate. Returning to an edit
  /// screen should show what the database holds *now*, not a draft from a
  /// visit that was walked away from — abandoning an edit form discards
  /// it everywhere else too, and a stale portrait would be worse than
  /// none because it looks like the truth.
  Future<void> load() async {
    state = const EditProfileState();

    try {
      final profile = await ref.read(profileRepositoryProvider).fetchCurrent();
      state = state.copyWith(
        loading: false,
        name: profile.name,
        bio: profile.bio,
        avatarPath: profile.avatarPath,
        avatarUrl: profile.avatarUrl,
      );
    } on Failure catch (f) {
      state = state.copyWith(loading: false, loadFailed: true, failure: f);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        loadFailed: true,
        failure: const Failure(
          code: FailureCode.unknown,
          message: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  void setName(String value) => state = state.copyWith(
        name: value,
        nameDirty: true,
        saved: false,
        clearFailure: true,
      );

  void setBio(String value) => state = state.copyWith(
        bio: value,
        bioDirty: true,
        saved: false,
        clearFailure: true,
      );

  /// Shows [bytes] immediately — the upload it implies runs only on save.
  ///
  /// Optimism has a limit here: nothing is written yet, so this is a
  /// preview of an intent, not of an outcome. It becomes a claim about
  /// the server at save time, and is withdrawn then if it does not hold.
  void chooseAvatar(Uint8List bytes) => state = state.copyWith(
        pendingAvatar: bytes,
        removeAvatar: false,
        saved: false,
        clearFailure: true,
      );

  void removeAvatar() => state = state.copyWith(
        clearPendingAvatar: true,
        removeAvatar: true,
        saved: false,
        clearFailure: true,
      );

  /// Attempts the save. Returns `true` when it landed.
  ///
  /// A second tap while one is in flight is dropped rather than sent:
  /// two concurrent updates to one row would race, and the reader would
  /// see whichever finished last — possibly not the one they last asked
  /// for.
  Future<bool> save() async {
    if (state.saving) return false;

    if (!state.isValid) {
      // Live validation only surfaces an error once a field has been
      // touched, so an invalid-but-untouched form has to be marked dirty
      // here. Otherwise the button silently does nothing and the reader
      // is left guessing which field is at fault.
      state = state.copyWith(nameDirty: true, bioDirty: true);
      return false;
    }

    state = state.copyWith(saving: true, clearFailure: true);

    try {
      final updated = await ref.read(profileRepositoryProvider).update(
            name: state.name.trim(),
            bio: state.bio.trim(),
            avatarBytes: state.pendingAvatar,
            removeAvatar: state.removeAvatar,
          );

      state = state.copyWith(
        loading: false,
        saving: false,
        saved: true,
        name: updated.name,
        bio: updated.bio,
        avatarPath: updated.avatarPath,
        avatarUrl: updated.avatarUrl,
        clearPendingAvatar: true,
        removeAvatar: false,
        nameDirty: false,
        bioDirty: false,
      );
      return true;
    } on Failure catch (f) {
      _rollback(f);
      return false;
    } catch (_) {
      _rollback(const Failure(
        code: FailureCode.unknown,
        message: 'Something went wrong. Please try again.',
      ));
      return false;
    }
  }

  /// Withdraws the portrait the save was meant to land and reports why.
  ///
  /// [EditProfileState]'s typed fields are *not* restored. They were
  /// never presented as saved — they are the form, still open, still
  /// editable — whereas the chosen portrait was presented as the reader's
  /// and is now known not to exist. Restoring one and keeping the other
  /// is the difference between not lying about the server and destroying
  /// the reader's work.
  void _rollback(Failure failure) {
    state = state.copyWith(
      saving: false,
      saved: false,
      clearPendingAvatar: true,
      removeAvatar: false,
      failure: failure,
    );
  }

  /// Clears a presented failure so returning to the screen does not
  /// replay it.
  void acknowledgeFailure() => state = state.copyWith(clearFailure: true);
}
