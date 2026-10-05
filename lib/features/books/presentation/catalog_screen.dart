import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design_system/bookly_design_system.dart';
import '../../../core/snackbar/present_failure.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/catalog_controller.dart';
import '../domain/book.dart';

/// The signed-in home: every book any reader has made public
/// (PLAN.md §1.3 option C).
///
/// Catalog rather than dashboard — the first thing a reader sees after
/// signing in is a shelf, not a summary of themselves. §5's whole
/// premise is that books are created by the people reading them, so
/// what there is to look at is what other people have written down.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  @override
  void initState() {
    super.initState();

    // Past the first frame so `ref` is usable, and only when there is
    // nothing yet: coming back to the catalog must not re-fetch a shelf
    // the reader is already holding, and a shelf that failed once is
    // left with its Try again rather than being retried underneath them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(catalogControllerProvider);
      if (s.books.isEmpty && !s.loading && s.failure == null) {
        ref.read(catalogControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(catalogControllerProvider);

    // Exactly one surface reports a failure: the ErrorView below when
    // the shelf is empty, this toast when there is a shelf to keep
    // showing. Reporting both would leave a reader looking at a
    // perfectly good list while told the catalog is broken.
    ref.listen(catalogControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null) return;

      // Same failure object means the same failed attempt — it has
      // already been reported once and must not be reported again on
      // the next rebuild.
      if (previous?.failure == failure) return;

      if (next.books.isEmpty) return;
      presentFailure(failure);
    });

    return AppScaffold(
      title: 'Catalog',
      subtitle: 'Every book any reader has made public.',
      actions: [
        TextButton(
          onPressed: () => context.push(Routes.newBook),
          child: const Text('New book'),
        ),
      ],
      children: [
        if (state.loading && state.books.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: BooklySpace.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.failure != null && state.books.isEmpty)
          ErrorView(failure: state.failure!, onRetry: _retry)
        else if (state.books.isEmpty)
          EmptyState(
            title: 'No books yet',
            message: 'Books appear here the moment someone makes one '
                'public. Yours would be the first.',
            action: PrimaryButton(label: 'Create a book', onPressed: _create),
          )
        else
          ...[
            for (final book in state.books)
              _BookRow(
                key: ValueKey(book.id),
                book: book,
                onTap: () => context.push(Routes.book(book.id)),
              ),
          ],
        if (state.loading && state.books.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: BooklySpace.md),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _retry() => ref.read(catalogControllerProvider.notifier).load();

  void _create() => context.push(Routes.newBook);
}

/// One shelf entry: jacket, title, authors, and however much of the
/// blurb fits.
///
/// Flat with a rule under it rather than a raised card — a catalog is
/// a list of things in a row, and a card would put each one in its own
/// box, quietly arguing that they are separate offers rather than one
/// shelf.
class _BookRow extends StatelessWidget {
  const _BookRow({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final image =
        book.coverUrl == null ? null : NetworkImage(book.coverUrl!) as ImageProvider;

    return Padding(
      padding: const EdgeInsets.only(bottom: BooklySpace.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.border, width: BooklyBorder.thin),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BooklyRadius.rSm,
            child: Padding(
              padding: const EdgeInsets.only(bottom: BooklySpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(image: image, width: 88),
                  const SizedBox(width: BooklySpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BooklyType.headlineSm
                              .copyWith(color: colors.text),
                        ),
                        const SizedBox(height: BooklySpace.xs),
                        Text(
                          book.authors.join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BooklyType.bodySm
                              .copyWith(color: colors.textSecondary),
                        ),
                        if (book.about != null) ...[
                          const SizedBox(height: BooklySpace.sm),
                          Text(
                            book.about!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: BooklyType.bodySm.copyWith(
                              color: colors.textTertiary,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
