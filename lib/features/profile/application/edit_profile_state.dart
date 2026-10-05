import 'dart:typed_data';

import '../../../core/errors/failure.dart';
import '../../../core/utils/validators.dart';

/// Everything `EditProfileScreen` is holding (PLAN.md §3.3).
///
/// ## Draft and committed are different things
///
/// Two groups of value live here and they are kept apart on purpose:
///
/// * **Draft** — [name], [bio], [pendingAvatar], [removeAvatar]. What the
///   reader is writing. A failed save never touches them: rolling a
///   person's words back to a state they have already edited past would
///   destroy work the server has merely not received yet.
/// * **Committed** — [avatarPath], [avatarUrl]. What the database holds,
///   and therefore what a rollback restores.
///
/// That split is what "optimistic save with rollback" means on this
/// screen. The portrait the reader chose is shown *at once*, before its
/// upload has finished — and is withdrawn the moment the save is known
/// not to have landed, because from then on it is a claim about the
/// server that is no longer true. Their typing survives, because it was
/// never a claim about the server in the first place.
///
/// ## Validation runs live, but stays quiet until touched
///
/// [nameError] and [bioError] return `null` for a field the reader has
/// not edited yet, so a freshly opened form opens clean instead of
/// shouting at someone who has changed nothing. [isValid] deliberately
/// ignores that courtesy — it is what `save` gates on, so an untouched
/// or half-filled form still cannot be submitted, and [EditProfileController]
/// marks the fields dirty when a blocked submit would otherwise look
/// like a button that does nothing.
class EditProfileState {
  const EditProfileState({
    this.loading = true,
    this.loadFailed = false,
    this.name = '',
    this.bio = '',
    this.avatarPath,
    this.avatarUrl,
    this.pendingAvatar,
    this.removeAvatar = false,
    this.nameDirty = false,
    this.bioDirty = false,
    this.saving = false,
    this.saved = false,
    this.failure,
  });

  /// True until the row has been read — or until reading it failed.
  final bool loading;

  /// Distinguishes "the row arrived empty" from "the row never arrived".
  /// Without it the screen cannot tell an empty profile from a failed
  /// load, and would offer to save against a database it never reached.
  final bool loadFailed;

  // ── Draft ─────────────────────────────────────────────────────────────

  final String name;
  final String bio;

  /// Chosen but not yet uploaded.
  final Uint8List? pendingAvatar;

  /// Chosen to be empty. Separate from "no portrait" so a save that does
  /// not touch the portrait can tell the difference between leaving it
  /// alone and deleting it.
  final bool removeAvatar;

  // ── Committed ─────────────────────────────────────────────────────────

  final String? avatarPath;
  final String? avatarUrl;

  // ── Interaction ───────────────────────────────────────────────────────

  final bool nameDirty;
  final bool bioDirty;
  final bool saving;
  final bool saved;
  final Failure? failure;

  /// null for a field the reader has not edited yet.
  String? get nameError {
    if (!nameDirty) return null;
    final v = name.trim();
    if (v.isEmpty) return 'Enter a display name.';
    if (v.length > Validators.nameMaxLength) {
      return 'Keep it to ${Validators.nameMaxLength} characters or fewer.';
    }
    return null;
  }

  /// null for a field the reader has not edited yet.
  ///
  /// Measured after trimming, because trimming is what the repository
  /// stores — validating the untrimmed string would reject a value the
  /// database would happily take.
  String? get bioError {
    if (!bioDirty) return null;
    if (bio.trim().length > Validators.bioMaxLength) {
      return 'Keep it to ${Validators.bioMaxLength} characters or fewer.';
    }
    return null;
  }

  /// Whether the form may be submitted, regardless of what is on screen.
  bool get isValid =>
      name.trim().isNotEmpty &&
      name.trim().length <= Validators.nameMaxLength &&
      bio.trim().length <= Validators.bioMaxLength;

  EditProfileState copyWith({
    bool? loading,
    bool? loadFailed,
    String? name,
    String? bio,
    String? avatarPath,
    String? avatarUrl,
    Uint8List? pendingAvatar,
    bool clearPendingAvatar = false,
    bool? removeAvatar,
    bool? nameDirty,
    bool? bioDirty,
    bool? saving,
    bool? saved,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      EditProfileState(
        loading: loading ?? this.loading,
        loadFailed: loadFailed ?? this.loadFailed,
        name: name ?? this.name,
        bio: bio ?? this.bio,
        avatarPath: avatarPath ?? this.avatarPath,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        pendingAvatar:
            clearPendingAvatar ? null : (pendingAvatar ?? this.pendingAvatar),
        removeAvatar: removeAvatar ?? this.removeAvatar,
        nameDirty: nameDirty ?? this.nameDirty,
        bioDirty: bioDirty ?? this.bioDirty,
        saving: saving ?? this.saving,
        saved: saved ?? this.saved,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}
