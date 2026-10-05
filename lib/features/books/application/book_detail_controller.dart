import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../data/book_repository_impl.dart';
import '../domain/book_repository.dart';
import 'book_detail_state.dart';

final bookDetailControllerProvider =
    NotifierProvider.family<BookDetailController, BookDetailState, String>(
  BookDetailController.new,
);

/// Loads one book together with its chapters and links (PLAN.md §5.7).
///
/// A family rather than a plain notifier because the identity of the
/// thing being loaded *is* the provider's argument. Folding the id into
/// a single notifier would make every book screen read from one place —
/// correct while only one is on screen, and wrong the moment two are,
/// because the lower one would rebuild against the upper one's data.
///
/// The screen drives [load], same as the catalog: a notifier that
/// fetched in [build] would re-fetch whenever anything invalidated it,
/// including changes the reader made on a different screen.
class BookDetailController extends Notifier<BookDetailState> {
  /// Riverpod 3 hands a family notifier its argument at construction
  /// rather than as a parameter of [build].
  ///
  /// That is why this is a field and not something derived: [build] runs
  /// again whenever anything this state watches changes, and asking each
  /// fresh [build] to re-derive which book it is would mean trusting it
  /// to reach the same answer as the one that came before.
  BookDetailController(this._bookId);

  final String _bookId;

  @override
  BookDetailState build() => BookDetailState.initial;

  Future<void> load() async {
    if (state.loading) return;

    // Whatever is on screen survives the fetch, so a reload renders
    // under a spinner instead of blinking to nothing.
    state = BookDetailState(loading: true, detail: state.detail);

    try {
      final detail = await _repo.detail(_bookId);
      state = BookDetailState(detail: detail);
    } on Failure catch (f) {
      state = BookDetailState(failure: f, detail: state.detail);
    } catch (_) {
      state = BookDetailState(
        failure: const Failure(
          code: FailureCode.unknown,
          message: 'Something went wrong. Please try again.',
        ),
        detail: state.detail,
      );
    }
  }

  BookRepository get _repo => ref.read(bookRepositoryProvider);

  /// Signs the book's own PDF/EPUB so it can be handed to whatever
  /// opens documents on this device (§5.1's optional upload).
  ///
  /// A pass-through, and deliberately still a pass-through: the screen
  /// gets at it *through here* because the dependency direction §1.1
  /// asks for is presentation → application → data, and a screen that
  /// reached past this layer for a repository provider would be the one
  /// call site that could not be swapped. It does not touch [state] —
  /// signing a URL is a one-shot answer for a single tap, not a fact
  /// about the book, and caching a link whose whole point is that it
  /// expires would be storing the one thing that must not be kept.
  Future<String> uploadUrl(String uploadPath) => _repo.uploadUrl(uploadPath);
}
