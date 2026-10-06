import '../../../core/errors/failure.dart';
import '../domain/book_progress.dart';

/// What one book-progress provider is holding (PLAN.md §5.4, §5.7).
///
/// The provider is keyed by `bookId` for the same reason
/// `BookDetailController` is: two books on the stack must not share a
/// progress map, or the lower screen would render the upper one's ticks
/// against chapters it is not showing.
class BookProgressState {
  const BookProgressState({
    this.progress,
    this.failure,
    this.loading = false,
    this.pending = const {},
  });

  /// Null until the first load lands — render against [shown] until it
  /// does. Never torn down by a *failed* reload: a refresh that could
  /// not complete leaves the ticks already on screen, with [failure]
  /// beside them. Losing every status because one refresh failed would
  /// be a worse answer than showing what is already known.
  final BookProgress? progress;

  /// Non-null after any attempt that did not produce a result. Cleared
  /// by the next attempt that *does* — a failure replaced by an answer
  /// is no longer what the screen should be saying.
  final Failure? failure;

  /// True only while there is nothing to show. A reload of progress the
  /// reader can already see would be a spinner over ticks that are
  /// still there.
  final bool loading;

  /// Item ids whose write is in flight.
  ///
  /// Keyed by id rather than a single flag so marking one link does not
  /// disable a row the reader is looking at elsewhere on the same
  /// screen.
  final Set<String> pending;

  static const initial = BookProgressState();

  /// What the rows render against, and never null.
  ///
  /// "Not started" and "not loaded yet" render the same `▸ Start ▶`.
  /// Telling them apart would need a fourth status for a distinction
  /// the reader does not make — and the honest half of it, a failure to
  /// load, is already reported through [failure].
  BookProgress get shown => progress ?? BookProgress.empty;

  bool isPending(String itemId) => pending.contains(itemId);
}
