import '../../../core/errors/failure.dart';
import '../domain/book_detail.dart';

/// What one book-detail screen is holding (PLAN.md §5.7).
///
/// The provider is keyed by `bookId`, so two book screens on the stack
/// each get their own state. That is not a hypothetical: going from one
/// book back to another would otherwise have the lower screen re-render
/// against the upper one's data, and the reader would watch a cover
/// change underneath a title they did not navigate away from.
class BookDetailState {
  const BookDetailState({this.detail, this.failure, this.loading = false});

  /// Null until the first load lands.
  ///
  /// Never torn back down by a *failed* reload: a refresh that could
  /// not complete leaves the reader looking at the book they already
  /// had, with [failure] beside it. Losing a whole book because a
  /// refresh could not complete is a worse answer than showing what is
  /// already on screen.
  final BookDetail? detail;

  /// Non-null after any attempt that did not produce a result. Replaced
  /// rather than cleared by the next attempt — a retry that fails is a
  /// new failure, not the absence of one.
  final Failure? failure;

  /// True only while there is nothing to show. A reload of a book the
  /// reader can already see would be a spinner over a book that is
  /// still there.
  final bool loading;

  static const initial = BookDetailState();

  /// Whether there is a book to render — the screen's branch between
  /// ErrorView and the actual page.
  bool get hasBook => detail != null;
}
