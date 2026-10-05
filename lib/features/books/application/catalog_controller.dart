import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_code.dart';
import '../data/book_repository_impl.dart';
import '../domain/book_repository.dart';
import 'catalog_state.dart';

final catalogControllerProvider =
    NotifierProvider<CatalogController, CatalogState>(
  CatalogController.new,
);

/// Loads the public catalog (PLAN.md §1.3 option C).
///
/// One method, because the shelf has exactly one operation. `load` is
/// idempotent and drops re-entry while running: a screen that calls it
/// from `initState` and again from a retry button can otherwise fire
/// twice on a slow first frame, and two identical requests racing would
/// both write the same list.
class CatalogController extends Notifier<CatalogState> {
  @override
  CatalogState build() => CatalogState.initial;

  Future<void> load() async {
    if (state.loading) return;

    // The shelf the reader already has is kept across the fetch, so the
    // screen can render it under a spinner instead of blinking to
    // nothing every time it reloads.
    state = CatalogState(loading: true, books: state.books);

    try {
      final books = await _repo.all();
      state = CatalogState(books: books);
    } on Failure catch (f) {
      state = CatalogState(failure: f, books: state.books);
    } catch (_) {
      state = CatalogState(
        failure: const Failure(
          code: FailureCode.unknown,
          message: 'Something went wrong. Please try again.',
        ),
        books: state.books,
      );
    }
  }

  BookRepository get _repo => ref.read(bookRepositoryProvider);
}
