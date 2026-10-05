import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/failure.dart';
import '../errors/failure_code.dart';
import 'supabase_client_provider.dart';

final storageUploaderProvider = Provider<StorageUploader>(
  (ref) => StorageUploader(ref.watch(supabaseClientProvider)),
);

/// Writing files into Bookly's Storage buckets.
///
/// One helper for all three kinds of upload — avatar (§3.3), book cover
/// (§5.1) and the optional PDF/EPUB (§5.1) — because every bucket's
/// policy authorises only `{auth.uid()}/{file}`
/// (`supabase/migrations/20261005000008_storage.sql`). A caller that
/// assembled its own path would be one forgotten prefix away from a 403,
/// and three callers would each derive it slightly differently.
///
/// ## Returns a path, never a URL
///
/// That is what the columns store — `profiles.avatar_path` says so in its
/// own comment — because a storage policy authorises a path, while a URL
/// embeds the project ref. [publicUrl] exists for the two *public*
/// buckets where rendering needs one.
class StorageUploader {
  StorageUploader(this._client);

  final SupabaseClient _client;

  /// Bucket ids, named once. Public (`avatars`, `book-covers`) unless
  /// noted — `book-uploads` holds a PDF or EPUB and must not be reachable
  /// by a URL anyone could paste to a stranger.
  static const avatars = 'avatars';
  static const bookCovers = 'book-covers';
  static const bookUploads = 'book-uploads';

  /// Uploads [bytes] at `{currentUserId}/{filename}` and returns that
  /// path for storage in the corresponding column.
  ///
  /// `upsert: true` so replacing an avatar is a write to a stable path
  /// rather than a new object every time — otherwise each portrait would
  /// leave the previous one behind, unreachable but still billed, with no
  /// reference to it anywhere in the database.
  Future<String> upload({
    required String bucket,
    required String filename,
    required Uint8List bytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      // Storage policies compare the first path segment to `auth.uid()`,
      // so an anonymous upload could not land anywhere anyway.
      throw const Failure(
        code: FailureCode.unauthorised,
        message: 'Please sign in again to continue.',
      );
    }

    final path = '$userId/$filename';

    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
    } on StorageException catch (e) {
      // Translated here rather than left for each consumer: the raw
      // Supabase message ("Invalid JPEG byte sequence…") is not copy a
      // reader should see (§3.2 "no raw payloads"), and every caller
      // wants the same sentence anyway.
      throw Failure(
        code: FailureCode.unknown,
        message: 'That file could not be uploaded. Please try again.',
        cause: e,
      );
    }

    return path;
  }

  /// A renderable URL for [path].
  ///
  /// Meaningful only in a public bucket. `avatars` and `book-covers` are;
  /// `book-uploads` deliberately is not, and asking it for a URL produces
  /// one that will 403 — hence the bucket being a required argument, so
  /// the mistake has to be made explicitly.
  String publicUrl({required String bucket, required String path}) =>
      _client.storage.from(bucket).getPublicUrl(path);

  /// The extension implied by [bytes], for an image a decoder produced.
  ///
  /// Sniffed rather than told, because `XFile` extension and actual
  /// bytes disagree often enough on Android (a `.png` that is really a
  /// re-encoded JPEG) that trusting the name uploads a file the bucket's
  /// `allowed_mime_types` will reject.
  static String imageExtension(Uint8List bytes) {
    if (bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) return 'jpg';

    if (bytes.length > 12 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46 && // F
        bytes[8] == 0x57 && // W
        bytes[9] == 0x45 && // E
        bytes[10] == 0x42 && // B
        bytes[11] == 0x50) {
      return 'webp';
    }

    if (bytes.length > 3 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 && // P
        bytes[2] == 0x4E && // N
        bytes[3] == 0x47) {
      return 'png';
    }

    // PNG is both the commonest fallback and the safest: it is lossless,
    // so a mislabelled image degrades to something still renderable.
    return 'png';
  }

  /// The extension implied by [bytes] for a document (§5.1), or null
  /// when Bookly cannot say what it is.
  ///
  /// Sniffed for the same reason [imageExtension] is: the name the
  /// picker hands back is the name the *file's sender* used, while
  /// `allowed_mime_types` on `book-uploads` admits only
  /// `application/pdf` and `application/epub+zip`. A file whose bytes
  /// are neither is one Bookly should not label, so this returns nothing
  /// and lets the caller decide — guessing `pdf` would upload a file the
  /// bucket may accept under a name that is wrong.
  ///
  /// EPUB is a ZIP container, which is what the `PK` signature says. A
  /// bare ZIP would also pass, but the picker has already narrowed the
  /// choice to these two extensions before anything reaches here.
  static String? documentExtension(Uint8List bytes) {
    // '%PDF-' is the only magic number a PDF has.
    if (bytes.length > 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D) {
      return 'pdf';
    }

    if (bytes.length > 1 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
      return 'epub';
    }

    return null;
  }
}
