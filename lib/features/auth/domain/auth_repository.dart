import 'dart:typed_data';

/// Creating, entering and leaving a Bookly account.
///
/// Presentation never touches Supabase: it calls this and renders the
/// result (PLAN.md §1.1). Every method throws a `Failure` carrying
/// presentable copy — never a raw auth payload, never a stack trace
/// (PLAN.md §3.2).
///
/// **Email confirmation is off** on the live project (ruled 2026-10-05),
/// so [signUp] hands back an established session and the register flow can
/// walk straight to the catalog as §3.1 specifies. If confirmation is ever
/// re-enabled, [signUp] will succeed without a session and that navigation
/// becomes wrong — this interface would need a "pending confirmation" state.
abstract interface class AuthRepository {
  /// Emits `true` the moment a session exists and `false` when it is gone.
  ///
  /// One stream rather than a "refresh me" call per screen: splash,
  /// router-guard and every signed-in screen need the same answer, and
  /// polling it from each would let them disagree.
  Stream<bool> watchSignedIn();

  /// Whether a session exists right now.
  bool get isSignedIn;

  /// The signed-in reader's id, or `null`.
  String? get currentUserId;

  /// §3.1 — email + password → session. `invalidCredentials` never says
  /// which of the two was wrong.
  Future<void> signIn({required String email, required String password});

  /// §3.1 — name + email + password (+ optional bio and avatar) →
  /// `profiles` row → session.
  ///
  /// The `name` travels as Supabase auth metadata because
  /// `handle_new_user()` (migration `20261005000002`) is what creates the
  /// profile row, reading only that key. The trigger ignores `bio`, so the
  /// remainder is written by an `UPDATE` after the session exists — the
  /// app never `INSERT`s a profile itself.
  ///
  /// [avatarBytes] is uploaded before that `UPDATE`, since a storage path
  /// is what `profiles.avatar_path` stores, not a URL (migration
  /// `20261005000002`, column comment).
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? bio,
    Uint8List? avatarBytes,
  });

  /// §3.1 — **email-only, no OTP screen.** Sends the recovery mail and
  /// returns; the reader never types a code. Copy on success is a
  /// confirmation with no blame (§3.2).
  Future<void> sendPasswordReset({required String email});

  /// §3.1 — clear session → `/login`.
  ///
  /// In Phase 1 this is the whole job. Later phases add cancelling local
  /// reminder schedules, deleting the `device_tokens` row and invalidating
  /// every provider before the same navigation (§3.1).
  Future<void> signOut();
}
