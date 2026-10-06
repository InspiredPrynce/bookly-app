import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../data/progress_repository_impl.dart';
import '../domain/book_progress.dart';
import '../domain/item_status.dart';
import '../domain/progress_repository.dart';
import 'book_progress_state.dart';

final bookProgressControllerProvider =
    NotifierProvider.family<BookProgressController, BookProgressState, String>(
  BookProgressController.new,
);

/// Reads and writes the reader's own `item_progress` rows (§5.4, §5.7).
///
/// A family keyed by `bookId`, for the reason `BookDetailController` is:
/// the identity of the thing being tracked *is* the provider's argument,
/// and folding the id into one notifier would have every book screen
/// reading the same map.
///
/// The screen drives [load], same as the others. A notifier that
/// fetched in [build] would re-fetch whenever anything invalidated it —
/// including a change the reader made on another screen while this one
/// was sitting underneath it.
class BookProgressController extends Notifier<BookProgressState> {
  /// Riverpod 3 hands a family notifier its argument at construction
  /// rather than as a parameter of [build], which is why this is a field
  /// and not something re-derived: [build] runs again whenever anything
  /// this state watches changes, and each fresh run would have to reach
  /// the same answer as the one before it.
  BookProgressController(this._bookId);

  final String _bookId;

  @override
  BookProgressState build() => BookProgressState.initial;

  Future<void> load() async {
    if (state.loading) return;

    state = BookProgressState(
      loading: true,
      progress: state.progress,
      pending: state.pending,
    );

    try {
      state = BookProgressState(
        progress: await _repo.load(_bookId),
        pending: state.pending,
      );
    } on Failure catch (f) {
      state = BookProgressState(
        progress: state.progress,
        failure: f,
        pending: state.pending,
      );
    } catch (_) {
      state = BookProgressState(
        progress: state.progress,
        failure: const Failure(
          code: FailureCode.unknown,
          message: 'Your progress could not be loaded. Please try again.',
        ),
        pending: state.pending,
      );
    }
  }

  // ── The four transitions (§5.7) ─────────────────────────────────────────

  Future<void> startChapter(String chapterId) => _write(
        chapterId,
        () => _repo.startChapter(bookId: _bookId, chapterId: chapterId),
        (progress, status) => progress.withChapter(chapterId, status),
      );

  Future<void> finishChapter(String chapterId) => _write(
        chapterId,
        () => _repo.finishChapter(bookId: _bookId, chapterId: chapterId),
        (progress, status) => progress.withChapter(chapterId, status),
      );

  Future<void> startLink(String linkId) => _write(
        linkId,
        () => _repo.startLink(bookId: _bookId, linkId: linkId),
        (progress, status) => progress.withLink(linkId, status),
      );

  Future<void> finishLink(String linkId) => _write(
        linkId,
        () => _repo.finishLink(bookId: _bookId, linkId: linkId),
        (progress, status) => progress.withLink(linkId, status),
      );

  /// One row, at most one in-flight write, one recorded answer.
  ///
  /// The answer recorded is *the repository's*, not the one that was
  /// asked for: starting something already finished returns `finished`,
  /// and storing the request instead would have the row on screen
  /// claiming a status the database does not hold. See
  /// `ProgressRepository` on that contract.
  ///
  /// There is no success toast. The status line changing to
  /// `▸ Watched ✓` in front of the reader *is* the confirmation, and a
  /// toast would also ring the chime — a notification sound for a tick
  /// the reader just placed themselves is noise where there was
  /// meaning.
  Future<void> _write(
    String itemId,
    Future<ItemStatus> Function() write,
    BookProgress Function(BookProgress, ItemStatus) apply,
  ) async {
    if (state.pending.contains(itemId)) return;

    state = BookProgressState(
      progress: state.progress,
      failure: state.failure,
      pending: {...state.pending, itemId},
    );

    try {
      final status = await write();
      state = BookProgressState(
        progress: apply(state.shown, status),
        pending: {...state.pending}..remove(itemId),
      );
    } on Failure catch (f) {
      state = BookProgressState(
        progress: state.progress,
        failure: f,
        pending: {...state.pending}..remove(itemId),
      );
    } catch (_) {
      state = BookProgressState(
        progress: state.progress,
        failure: const Failure(
          code: FailureCode.unknown,
          message: 'Your progress could not be saved. Please try again.',
        ),
        pending: {...state.pending}..remove(itemId),
      );
    }
  }

  ProgressRepository get _repo => ref.read(progressRepositoryProvider);
}
