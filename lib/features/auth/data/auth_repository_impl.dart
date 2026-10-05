import 'dart:io' show SocketException;

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(supabaseClientProvider)),
);

/// Supabase implementation of [AuthRepository].
///
/// Two responsibilities beyond forwarding calls: choosing which metadata
/// keys Supabase receives (the profile trigger reads `name`, and only
/// `name`), and translating `AuthException` into a `Failure` whose copy is
/// safe to show. The translation lives here rather than at the call site
/// because the raw message must never escape this file — "Invalid login
/// credentials" becomes `invalidCredentials` with Bookly's wording, and
/// anything unrecognised becomes a deliberately vague `unknown`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<bool> watchSignedIn() =>
      _client.auth.onAuthStateChange.map((state) => state.session != null);

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
      });

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? bio,
    Uint8List? avatarBytes,
  }) =>
      _guard(() async {
        final normalizedEmail = email.trim();

        // `handle_new_user()` creates the profiles row from these
        // credentials, reading `name` (falling back to `full_name`, then
        // the email local-part). Nothing here INSERTs a profile.
        final auth = await _client.auth.signUp(
          email: normalizedEmail,
          password: password,
          data: {'name': name.trim()},
        );

        final user = auth.user;
        if (user == null) {
          // Only reachable if the project's confirmations were re-enabled:
          // signUp then returns no session and no user to update.
          throw const Failure(
            code: FailureCode.unknown,
            message: 'Your account was created. Check your email to '
                'finish signing in.',
          );
        }

        // The trigger ignores `bio`, so everything it did not set is
        // written here — after the session exists, which is also when
        // Storage will accept an avatar upload.
        final avatarPath = avatarBytes == null
            ? null
            : await _uploadAvatar(user.id, avatarBytes);

        if ((bio?.trim().isNotEmpty ?? false) || avatarPath != null) {
          await _updateProfile(user.id, bio: bio, avatarPath: avatarPath);
        }
      });

  @override
  Future<void> sendPasswordReset({required String email}) =>
      _guard(() => _client.auth.resetPasswordForEmail(email.trim()));

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut());

  // ── Profile completion ────────────────────────────────────────────────

  /// Returns the path *within* the avatars bucket, which is what
  /// `profiles.avatar_path` stores — a storage policy authorises a path,
  /// while a URL would embed the project ref instead.
  Future<String> _uploadAvatar(String userId, Uint8List bytes) async {
    final ext = _sniffExtension(bytes);
    final path = '$userId/avatar.$ext';

    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return path;
  }

  Future<void> _updateProfile(
    String userId, {
    String? bio,
    String? avatarPath,
  }) =>
      _guard(() async {
        final patch = <String, dynamic>{};
        final trimmedBio = bio?.trim();
        if (trimmedBio != null && trimmedBio.isNotEmpty) {
          patch['bio'] = trimmedBio;
        }
        if (avatarPath != null) {
          patch['avatar_path'] = avatarPath;
        }
        if (patch.isEmpty) return;

        await _client
            .from('profiles')
            .update(patch)
            .eq('id', userId)
            .single();
      });

  /// The upload is already authenticated by this point, so the only real
  /// failure here is the reader's image being neither JPEG nor PNG —
  /// rather than a sniffer that guesses from magic bytes, take the type
  /// the decoder is most likely to have produced and fall back to PNG.
  static String _sniffExtension(Uint8List bytes) {
    if (bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) return 'jpg';
    if (bytes.length > 3 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    return 'png';
  }

  // ── Error translation ─────────────────────────────────────────────────

  /// Runs [body], converting anything thrown into a `Failure`.
  ///
  /// `cause` is retained for debug builds only; `Failure.toString`
  /// already omits it, so an unrecognised auth message cannot reach a
  /// log line through here (§3.2 "no raw payloads").
  Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } on Failure {
      rethrow;
    } on AuthException catch (e) {
      throw _mapAuth(e);
    } on StorageException catch (e) {
      throw Failure(
        code: FailureCode.unknown,
        message: 'That file could not be uploaded. Please try again.',
        cause: e,
      );
    } catch (e) {
      throw _mapGeneric(e);
    }
  }

  static Failure _mapAuth(AuthException e) {
    final m = e.message.toLowerCase();

    if (m.contains('invalid login credentials')) {
      return Failure(
        code: FailureCode.invalidCredentials,
        // §3.2: never says which of email or password was wrong.
        message: 'Email or password is incorrect.',
        cause: e,
      );
    }
    if (m.contains('already registered') || m.contains('already been registered')) {
      return const Failure(
        code: FailureCode.emailAlreadyRegistered,
        message: 'An account already exists for that email.',
      );
    }
    if (m.contains('password') && (m.contains('at least') || m.contains('weak'))) {
      return Failure(
        code: FailureCode.weakPassword,
        message: 'Choose a password of at least 8 characters.',
        cause: e,
      );
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return const Failure(
        code: FailureCode.rateLimited,
        message: 'Too many attempts. Please wait a moment and try again.',
      );
    }
    if (m.contains('network') || m.contains('socket')) {
      return const Failure(
        code: FailureCode.networkOffline,
        message: "You're offline. Check your connection and try again.",
      );
    }
    if (m.contains('email not confirmed')) {
      // Confirmation is off by project setting; this only appears if a
      // future change re-enables it, and the copy must not blame.
      return const Failure(
        code: FailureCode.unauthorised,
        message: 'Confirm your email address, then try signing in again.',
      );
    }

    return Failure(
      code: FailureCode.unknown,
      message: 'Something went wrong. Please try again.',
      cause: e,
    );
  }

  static Failure _mapGeneric(Object e) {
    // The concrete type differs by which layer gave up first — dart:io,
    // package:http, or Supabase's own wrapper — so the name is matched as
    // well as the type. Whether the reader is told "you're offline" should
    // not depend on which of them happened to surface the failure.
    final text = e.toString().toLowerCase();
    final offline = e is SocketException ||
        text.contains('socket') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection closed') ||
        text.contains('connection refused');

    if (offline) {
      return Failure(
        code: FailureCode.networkOffline,
        message: "You're offline. Check your connection and try again.",
        cause: e,
      );
    }
    return Failure(
      code: FailureCode.unknown,
      message: 'Something went wrong. Please try again.',
      cause: e,
    );
  }
}
