import 'dart:typed_data';

import 'profile.dart';

/// Reading and changing the signed-in reader's `profiles` row.
///
/// Presentation calls this and renders the result (PLAN.md §1.1). Every
/// method throws a `Failure` with presentable copy — never a raw
/// Postgres or Storage payload (§3.2).
///
/// The avatar upload is *inside* [update] rather than a step the screen
/// performs first, because §3.3 specifies one path — pick → compress →
/// Storage → row update — and a screen that uploads and then forgets to
/// write the row would leave an orphaned object with no reference to it
/// anywhere in the database.
abstract interface class ProfileRepository {
  /// Loads the signed-in reader's profile.
  Future<Profile> fetchCurrent();

  /// Applies [name] and [bio], optionally replacing the portrait.
  ///
  /// [avatarBytes] uploads a freshly chosen image; [removeAvatar] clears
  /// the stored path. Both false/absent means the portrait is left
  /// alone — which is the ordinary case, and must not silently delete.
  ///
  /// Returns the profile as the database now has it, so the caller can
  /// commit real values rather than its own guesses.
  Future<Profile> update({
    required String name,
    required String bio,
    Uint8List? avatarBytes,
    bool removeAvatar = false,
  });
}
