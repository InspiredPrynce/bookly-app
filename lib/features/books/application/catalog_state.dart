import '../../../core/errors/failure.dart';
import '../domain/book.dart';

/// What the catalog currently knows (PLAN.md §1.3 option C).
///
/// Not an `AsyncValue`: this app reports failures as `Failure`s with
/// presentable copy (§3.2), and an `AsyncValue.error` would force every
/// screen to re-derive which of its errors is a sentence and which is a
/// stack trace.
///
/// [books] deliberately survives a failed reload. Losing a shelf the
/// reader was looking at because a refresh could not complete is a
/// worse answer than showing them what you already have — the list is
/// stale, not wrong, and the failure beside it says so.
class CatalogState {
  const CatalogState({this.loading = false, this.failure, this.books = const []});

  final bool loading;

  /// Null while healthy. Set for as long as the last attempt failed —
  /// cleared by the next success rather than by being read.
  final Failure? failure;

  /// Never emptied by a failure.
  final List<Book> books;

  static const initial = CatalogState();

  bool get isEmpty => books.isEmpty;
}
