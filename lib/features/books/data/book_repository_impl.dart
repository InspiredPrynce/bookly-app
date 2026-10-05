import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../../../core/supabase/storage_uploader.dart';
import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/book.dart';
import '../domain/book_link_draft.dart';
import '../domain/book_repository.dart';
import '../domain/chapter_draft.dart';

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepositoryImpl(
    ref.watch(supabaseClientProvider),
    ref.watch(storageUploaderProvider),
  ),
);

/// Supabase implementation of [BookRepository].
///
/// The order of operations is the whole design of this file:
///
/// 1. **insert the book** — so its id exists and the cover can be named
///    after it. Two books by the same author would otherwise share a
///    path, and `upsert: true` would have the second silently overwrite
///    the first's jacket.
/// 2. **upload the cover**, then write `cover_path`; the optional
///    PDF/EPUB follows the same two steps into `upload_path`, and its
///    extension is sniffed from the bytes rather than trusted from the
///    filename the picker returned.
/// 3. **insert chapters**, then **links** — positions come from each
///    list's final order.
///
/// Anything after step 1 that fails removes the book again. Supabase's
/// client cannot span several statements in one transaction, so without
/// that compensation a failed create leaves a phantom book in a catalog
/// the reader will search later — a book with no chapters, no links, and
/// no screen that explains it. The compensation is best-effort and
/// silent: the original failure is the only one worth reporting, and
/// §3.2 allows exactly one sentence.
class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl(this._client, this._uploader);

  final SupabaseClient _client;
  final StorageUploader _uploader;

  @override
  Future<Book> create({
    required String title,
    required List<String> authors,
    String? about,
    Uint8List? coverBytes,
    Uint8List? uploadBytes,
    required List<ChapterDraft> chapters,
    required List<BookLinkDraft> links,
  }) =>
      _guard(() async {
        final userId = _userId;

        final row = await _client
            .from('books')
            .insert({
              'created_by': userId,
              'title': title.trim(),
              'authors': authors,
              // Omitted rather than sent as '' — the column is nullable
              // and an absent optional field reads as absent everywhere
              // downstream, while an empty string has to be special-cased
              // by every reader.
              if (about != null && about.trim().isNotEmpty)
                'about': about.trim(),
            })
            .select(_bookColumns)
            .single();

        final bookId = row['id'] as String;
        String? coverPath;
        String? uploadPath;

        try {
          if (coverBytes != null) {
            coverPath = await _uploader.upload(
              bucket: StorageUploader.bookCovers,
              filename: '$bookId.${StorageUploader.imageExtension(coverBytes)}',
              bytes: coverBytes,
            );
            await _client
                .from('books')
                .update({'cover_path': coverPath})
                .eq('id', bookId);
            // So the returned [Book] carries what was just written rather
            // than the null the insert selected.
            row['cover_path'] = coverPath;
          }

          if (uploadBytes != null) {
            final ext = StorageUploader.documentExtension(uploadBytes);
            if (ext == null) {
              // Refused rather than renamed. The picker has already
              // narrowed this to `.pdf` and `.epub` by name, so a file
              // whose bytes are neither has been mislabelled by whoever
              // sent it — and uploading it under a matching name would
              // produce a book whose file does not open, months later,
              // with nothing to connect it back to this moment.
              throw const Failure(
                code: FailureCode.unknown,
                message: 'That file is not a PDF or an EPUB.',
              );
            }
            uploadPath = await _uploader.upload(
              bucket: StorageUploader.bookUploads,
              filename: '$bookId.$ext',
              bytes: uploadBytes,
            );
            await _client
                .from('books')
                .update({'upload_path': uploadPath})
                .eq('id', bookId);
            row['upload_path'] = uploadPath;
          }

          if (chapters.isNotEmpty) {
            await _client.from('chapters').insert([
              for (var i = 0; i < chapters.length; i++)
                {
                  'book_id': bookId,
                  'position': i + 1,
                  'title': chapters[i].title.trim(),
                },
            ]);
          }

          if (links.isNotEmpty) {
            await _client.from('book_links').insert([
              for (var i = 0; i < links.length; i++)
                {
                  'book_id': bookId,
                  'type': links[i].kind.dbValue,
                  'title': links[i].title.trim(),
                  'url': links[i].url.trim(),
                  'position': i + 1,
                },
            ]);
          }
        } catch (_) {
          await _undo(bookId, coverPath: coverPath, uploadPath: uploadPath);
          rethrow;
        }

        return _toBook(row);
      });

  // ── Internals ───────────────────────────────────────────────────────────

  static const _bookColumns = 'id, created_by, title, authors, about, '
      'cover_path, upload_path, created_at, updated_at';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      // `books.created_by` is `not null` and points at `profiles`, so
      // there is no row to write without a session — and RLS would
      // refuse the insert anyway.
      throw const Failure(
        code: FailureCode.unauthorised,
        message: 'Please sign in again to continue.',
      );
    }
    return id;
  }

  /// Removes a half-created book. Best effort, and deliberately silent.
  ///
  /// The row goes first because that is the defect the reader would
  /// actually see; the objects go second because an orphaned jacket or
  /// a stray PDF costs a few bytes and is invisible to them. `chapters`
  /// and `book_links` need no separate cleanup — both cascade from
  /// `books`.
  Future<void> _undo(
    String bookId, {
    String? coverPath,
    String? uploadPath,
  }) async {
    try {
      await _client.from('books').delete().eq('id', bookId);
    } catch (_) {
      // Swallowed: reporting it would replace the real failure with a
      // message about bookkeeping the reader never asked about.
    }

    await _remove(StorageUploader.bookCovers, coverPath);
    await _remove(StorageUploader.bookUploads, uploadPath);
  }

  /// Deletes [path] from [bucket] when there is one to delete.
  ///
  /// Swallowed on failure for the same reason everything in [_undo] is:
  /// this is cleanup, not the operation, and the object is invisible to
  /// the reader either way.
  Future<void> _remove(String bucket, String? path) async {
    if (path == null) return;
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (_) {
      // See above.
    }
  }

  Book _toBook(Map<String, dynamic> row) {
    final path = row['cover_path'] as String?;
    return Book(
      id: row['id'] as String,
      createdBy: row['created_by'] as String,
      title: row['title'] as String,
      authors: (row['authors'] as List).cast<String>(),
      about: row['about'] as String?,
      coverPath: path,
      coverUrl: path == null
          ? null
          : _uploader.publicUrl(
              bucket: StorageUploader.bookCovers,
              path: path,
            ),
      uploadPath: row['upload_path'] as String?,
      createdAt: _timestamp(row['created_at']),
      updatedAt: _timestamp(row['updated_at']),
    );
  }

  /// `timestamptz` arrives as an ISO-8601 string over PostgREST's JSON,
  /// and as a parsed `DateTime` if the client ever starts decoding it —
  /// both are handled so a client upgrade does not turn every catalog
  /// read into a cast error. Anything else means the column is not what
  /// this model expects, which is a bug and is allowed to say so.
  static DateTime _timestamp(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw StateError('Unreadable timestamp: $value');
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

    if (code == 'PGRST116' || code == '42501') {
      return Failure(
        code: FailureCode.unauthorised,
        message: 'Please sign in again to continue.',
        cause: e,
      );
    }

    // `chapters` and `book_links` both carry
    // `unique (book_id, position)`, and `books.title` is 1–300. Live
    // validation on screen should make these unreachable; if one is
    // reached, the reader's input was accepted here and rejected on
    // return, so say that rather than accusing the field they are
    // looking at.
    if (code == '23505' || code == '23514') {
      return const Failure(
        code: FailureCode.conflict,
        message: 'That book could not be saved as entered. '
            'Check the titles and try again.',
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
