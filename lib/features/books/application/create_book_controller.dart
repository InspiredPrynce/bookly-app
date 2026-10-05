import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../data/book_repository_impl.dart';
import '../domain/book_link_draft.dart';
import '../domain/book_repository.dart';
import '../domain/chapter_draft.dart';
import 'create_book_state.dart';

final createBookControllerProvider =
    NotifierProvider<CreateBookController, CreateBookState>(
  CreateBookController.new,
);

/// Owns the create-book attempt (PLAN.md §5.1).
///
/// [coverBytes] and [uploadBytes] are held here for the same reason
/// `RegisterController` holds the avatar: they are the only inputs on
/// this form the reader cannot re-enter cheaply, so a failed submit that
/// made them dismiss a picker would lose a file they had already
/// chosen. Everything else — title, authors, about, every chapter and
/// every link — is text they can retype, and it stays in the screen's
/// controllers where a failed attempt does not disturb it at all.
class CreateBookController extends Notifier<CreateBookState> {
  @override
  CreateBookState build() => CreateBookState.initial;

  Uint8List? coverBytes;

  /// The optional PDF/EPUB, held here for the same reason [coverBytes]
  /// is: a reader who picked a 40 MB file should not have to go and find
  /// it again because a submit failed.
  ///
  /// [uploadName] is display-only. The repository never sees it — the
  /// extension it writes with is sniffed from the bytes, not trusted
  /// from the filename the picker handed back.
  Uint8List? uploadBytes;
  String? uploadName;

  /// Mirrors `file_size_limit` on the `book-uploads` bucket
  /// (migration 20261005000008): 50 MB. Checked before the bytes leave
  /// the device, so a file that cannot land is refused in a sentence
  /// rather than after several minutes of upload and a Storage error.
  static const maxUploadBytes = 52428800;

  void setUpload(Uint8List bytes, String name) {
    uploadBytes = bytes;
    uploadName = name;
  }

  void clearUpload() {
    uploadBytes = null;
    uploadName = null;
  }

  /// Returns the new book's id, or null when the attempt failed — in
  /// which case the failure is in [CreateBookState.failure] and the
  /// form is untouched.
  Future<String?> create({
    required String title,
    required String authorsRaw,
    String? about,
    required List<ChapterDraft> chapters,
    required List<BookLinkDraft> links,
  }) async {
    // Dropped rather than queued: two concurrent creates would race the
    // position indexes and the reader would get two books.
    if (state.saving) return null;
    state = const CreateBookState(saving: true);

    try {
      final book = await _repo.create(
            title: title.trim(),
            authors: _splitAuthors(authorsRaw),
            about: about,
            coverBytes: coverBytes,
            uploadBytes: uploadBytes,
            chapters: chapters,
            links: links,
          );

      state = CreateBookState(createdBookId: book.id);
      return book.id;
    } on Failure catch (f) {
      // `coverBytes` and `uploadBytes` survive deliberately. The form is
      // still showing the file it uploaded or failed to upload, and
      // making the reader pick it again to retry would punish them for
      // the network.
      state = CreateBookState(failure: f);
      return null;
    } catch (_) {
      state = const CreateBookState(
        failure: Failure(
          code: FailureCode.unknown,
          message: 'Something went wrong. Please try again.',
        ),
      );
      return null;
    }
  }

  BookRepository get _repo => ref.read(bookRepositoryProvider);

  /// Called by the cover picker. Null clears a chosen-but-rejected image.
  void setCover(Uint8List? bytes) => coverBytes = bytes;

  /// Clears everything a previous visit left behind.
  ///
  /// Called on entry, unconditionally: a `createdBookId` from the book
  /// created a moment ago must not read as success for the next one, and
  /// a jacket chosen and abandoned is not a jacket this form should
  /// still be holding.
  void reset() {
    coverBytes = null;
    clearUpload();
    state = CreateBookState.initial;
  }

  /// "Ursula K. Le Guin, Terry Pratchett" → two authors.
  ///
  /// Split on commas only, and never on `and` or `&`: "Piper, Heather"
  /// is a real name in a real byline, and guessing at conjunctions would
  /// turn a correct list into a wrong one with no way for the reader to
  /// see what happened.
  static List<String> _splitAuthors(String raw) => raw
      .split(',')
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty)
      .toList(growable: false);
}
