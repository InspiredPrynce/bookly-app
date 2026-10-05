import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../../../core/supabase/storage_uploader.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(storageUploaderProvider),
  ),
);

/// Supabase implementation of [ProfileRepository].
///
/// The only translation work here is turning Postgres and network
/// failures into a `Failure` whose copy is safe to show — the raw
/// message must never escape this file (§3.2 "no stack traces, no raw
/// payloads").
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._client, this._uploader);

  final SupabaseClient _client;
  final StorageUploader _uploader;

  @override
  Future<Profile> fetchCurrent() => _guard(() async {
        final row = await _client
            .from('profiles')
            .select('id, name, bio, avatar_path')
            .eq('id', _userId)
            .single();
        return _toProfile(row);
      });

  @override
  Future<Profile> update({
    required String name,
    required String bio,
    Uint8List? avatarBytes,
    bool removeAvatar = false,
  }) =>
      _guard(() async {
        // Upload before writing the row: `profiles.avatar_path` stores a
        // path, so committing it first would point at an object that does
        // not exist yet — and if the upload then failed, the portrait
        // would be missing from both places instead of only one.
        String? uploadedPath;
        if (avatarBytes != null) {
          uploadedPath = await _uploader.upload(
            bucket: StorageUploader.avatars,
            filename: 'avatar.${StorageUploader.imageExtension(avatarBytes)}',
            bytes: avatarBytes,
          );
        }

        final patch = <String, dynamic>{
          'name': name.trim(),
          // Written as '' rather than null: the column accepts both, and
          // an empty string keeps every reader of this row in one shape
          // instead of teaching each consumer a null case.
          'bio': bio.trim(),
        };
        if (removeAvatar) {
          patch['avatar_path'] = null;
        } else if (uploadedPath != null) {
          patch['avatar_path'] = uploadedPath;
        }

        final row = await _client
            .from('profiles')
            .update(patch)
            .eq('id', _userId)
            .select('id, name, bio, avatar_path')
            .single();

        return _toProfile(row);
      });

  // ── Internals ───────────────────────────────────────────────────────────

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      // `profiles.id` is a primary key onto `auth.users`, so there is no
      // profile to read without a session — and RLS would refuse anyway.
      throw const Failure(
        code: FailureCode.unauthorised,
        message: 'Please sign in again to continue.',
      );
    }
    return id;
  }

  Profile _toProfile(Map<String, dynamic> row) {
    final path = row['avatar_path'] as String?;
    return Profile(
      id: row['id'] as String,
      name: (row['name'] as String?) ?? '',
      bio: (row['bio'] as String?) ?? '',
      avatarPath: path,
      avatarUrl: path == null
          ? null
          : _uploader.publicUrl(bucket: StorageUploader.avatars, path: path),
    );
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (e) {
      throw _mapOffline(e);
    }
  }

  static Failure _mapPostgrest(PostgrestException e) {
    final code = e.code?.toUpperCase() ?? '';

    // `.single()` after an UPDATE yields this when zero rows matched —
    // which under RLS means the session could not see its own row. It is
    // an access problem, not a "not found" the reader can act on.
    if (code == 'PGRST116' || code == '42501') {
      return Failure(
        code: FailureCode.unauthorised,
        message: 'Please sign in again to continue.',
        cause: e,
      );
    }

    // The bio (≤160) and name (1–60) checks. Live validation should make
    // this unreachable; if it is ever reached, the reader's input was
    // accepted on screen and rejected on return, so say so plainly
    // rather than blaming the field they are looking at.
    if (code == '23514') {
      return const Failure(
        code: FailureCode.conflict,
        message: 'That name or bio is too long. Shorten it and try again.',
      );
    }

    return Failure(
      code: FailureCode.unknown,
      message: 'Something went wrong. Please try again.',
      cause: e,
    );
  }

  /// The concrete type differs by which layer gave up first — dart:io or
  /// Supabase's own wrapper — so both the type and the wording are
  /// checked. Whether the reader is told "you're offline" should not
  /// depend on which of them happened to surface it.
  static Failure _mapOffline(Object e) {
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
