import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/routes.dart';
import '../../../core/design_system/bookly_design_system.dart';
import '../../../core/errors/failure.dart';
import '../../../core/snackbar/bookly_toast.dart';
import '../../../core/snackbar/present_failure.dart';
import '../../../core/widgets/error_view.dart';
import '../application/book_detail_controller.dart';
import '../application/book_detail_state.dart';
import '../domain/book.dart';
import '../domain/book_link.dart';
import '../domain/chapter.dart';
import '../domain/link_kind.dart';

/// One book, with whichever of §5.7's two branches it actually has.
///
/// ## What this screen is for, by book
///
/// A **chapter book** is a way in: every row here leads to
/// `ReadingScreen`, which is where the reading happens (§5.7 puts the
/// slider, the notes and Ask Gemini there, not here).
///
/// A **link book** is its own consumption surface — §5.7 says so
/// plainly, because a `ReadingScreen` for a book with zero chapters
/// would be empty. Watching or listening happens *through* this screen:
/// [BookDetail.isLinkOnly] is the branch where that is not an
/// accommodation but the whole design.
///
/// A **hybrid** shows both, chapters first: §5.6 calls links
/// "supplementary", and the order says so without a word of copy.
///
/// There is deliberately no header chrome here — no `AppScaffold`
/// lockup. A reader who tapped a book is one level deep and going
/// *somewhere*; the masthead's job (§1.3) is to say "you are signed in,
/// this is the app", which is already settled by the time this builds.
/// What they need instead is a way back, which is the first thing on
/// the page.
class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  @override
  void initState() {
    super.initState();

    // Past the first frame so `ref` is usable, and only when there is
    // nothing yet. Coming back from `ReadingScreen` must not re-fetch a
    // book the reader is already looking at, and a book that failed
    // once keeps its Try again rather than being retried underneath
    // them — the retry is [ErrorView]'s button, not a background loop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(_provider);
      if (s.detail == null && !s.loading && s.failure == null) {
        ref.read(_provider.notifier).load();
      }
    });
  }

  /// The provider for *this* book — one per family argument, so a
  /// second book on the stack cannot borrow the first one's state.
  NotifierProvider<BookDetailController, BookDetailState> get _provider =>
      bookDetailControllerProvider(widget.bookId);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(_provider);

    // Exactly one surface reports a failure: the ErrorView below when
    // there is no book to show, this toast when there is. Both at once
    // would leave a reader staring at a perfectly good book while being
    // told it is broken.
    ref.listen(_provider, (previous, next) {
      final failure = next.failure;
      if (failure == null) return;
      if (previous?.failure == failure) return;
      if (!next.hasBook) return;
      presentFailure(failure);
    });

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: BooklySpace.screenMobile,
                vertical: BooklySpace.lg,
              ),
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back'),
                    ),
                  ],
                ),
                if (!state.hasBook && state.failure != null)
                  ErrorView(failure: state.failure!, onRetry: _retry)
                else if (!state.hasBook)
                  const Padding(
                    padding: EdgeInsets.only(top: BooklySpace.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ..._body(context, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────────────────────

  List<Widget> _body(BuildContext context, BookDetailState state) {
    final colors = context.colors;
    final detail = state.detail!;
    final book = detail.book;

    // [BookCover] takes a nullable jacket precisely so that a book with
    // no uploaded cover — the ordinary case — renders blind-stamped
    // cloth rather than an error. Same book, same row, no announcement.
    final image = book.coverUrl == null
        ? null
        : NetworkImage(book.coverUrl!) as ImageProvider;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(image: image, width: 112),
          const SizedBox(width: BooklySpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: BooklyType.headlineMd.copyWith(color: colors.text),
                ),
                const SizedBox(height: BooklySpace.sm),
                Text(
                  book.authors.join(', '),
                  style:
                      BooklyType.bodySm.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      if (book.about != null) ...[
        const SizedBox(height: BooklySpace.lg),
        Text(
          book.about!,
          style: BooklyType.bodyMd
              .copyWith(color: colors.textSecondary, height: 1.6),
        ),
      ],
      const SizedBox(height: BooklySpace.xl),
      Container(height: BooklyBorder.thin, color: colors.border),

      // Chapters before links in a hybrid — §5.6 calls links
      // supplementary, and the order says so without a word of copy.
      if (detail.hasChapters) ...[
        const SizedBox(height: BooklySpace.lg),
        _section('Chapters', colors.textSecondary),
        const SizedBox(height: BooklySpace.xs),
        for (final chapter in detail.chapters)
          _ChapterRow(
            key: ValueKey(chapter.id),
            chapter: chapter,
            onTap: () =>
                context.push(Routes.chapter(widget.bookId, chapter.id)),
          ),
      ],

      if (detail.hasLinks) ...[
        if (detail.hasChapters) const SizedBox(height: BooklySpace.xl),
        const SizedBox(height: BooklySpace.lg),
        _section('Links', colors.textSecondary),
        const SizedBox(height: BooklySpace.xs),
        for (final link in detail.links)
          _LinkRow(
            key: ValueKey(link.id),
            link: link,
            onTap: () => _open(link),
          ),
      ],

      if (book.uploadPath != null) ...[
        const SizedBox(height: BooklySpace.xl),
        Container(height: BooklyBorder.thin, color: colors.border),
        const SizedBox(height: BooklySpace.lg),
        _section('The file itself', colors.textSecondary),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _openFile,
            child: Text(_fileLabel(book)),
          ),
        ),
      ],
    ];
  }

  /// Section eyebrow. Uppercase because `BooklyType.label*` is the
  /// bibliographic voice and the type scale says the casing happens at
  /// the call site — putting `.toUpperCase()` in the style would apply
  /// it to places that have not asked for it.
  Text _section(String title, Color color) => Text(
        title.toUpperCase(),
        style: BooklyType.labelLg.copyWith(color: color),
      );

  // ── Actions ──────────────────────────────────────────────────────────────

  void _retry() => ref.read(_provider.notifier).load();

  /// §5.7: **Open** → `url_launcher`.
  ///
  /// No progress write here. Opening is a *transition* (`item_progress =
  /// reading`, `circle_events.started_link`) and those writes belong to
  /// their own task — putting half of them here would leave the link row
  /// claiming a status the database has not recorded, which is exactly
  /// the kind of drift §5.6's derived-rule argument is about.
  Future<void> _open(BookLink link) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null || !uri.hasScheme) {
      // Caught before `launchUrl` rather than after: an unparsable URL
      // throws a `FormatException` there, and the reader would get
      // "something went wrong" for a link that was never going anywhere.
      BooklyToast.error('That link could not be opened.');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened && mounted) BooklyToast.error('That link could not be opened.');
    } catch (_) {
      if (mounted) BooklyToast.error('That link could not be opened.');
    }
  }

  /// Signs the book's own PDF/EPUB and hands it to whatever opens
  /// documents on this device.
  ///
  /// Signed rather than public because `book-uploads` is a private
  /// bucket on purpose (migration 000008): the file is reachable only
  /// by a signed-in account, and a permanent URL would turn that bucket
  /// public the moment someone pasted the link.
  Future<void> _openFile() async {
    final book = ref.read(_provider).detail?.book;
    final path = book?.uploadPath;
    if (book == null || path == null) return;

    try {
      final url = await ref.read(_provider.notifier).uploadUrl(path);
      final uri = Uri.tryParse(url);
      if (uri == null) return;

      final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened && mounted) {
        BooklyToast.error('That file could not be opened.');
      }
    } on Failure catch (f) {
      if (mounted) presentFailure(f);
    } catch (_) {
      if (mounted) BooklyToast.error('That file could not be opened.');
    }
  }

  /// Named from the path rather than stored: T6 sniffed the extension
  /// out of the bytes and named the object after it, so it is already
  /// there — and a column that records what a filename already says
  /// would be a second place for the two to disagree.
  String _fileLabel(Book book) {
    final path = book.uploadPath ?? '';
    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();

    if (ext == 'pdf') return 'Open the PDF';
    if (ext == 'epub') return 'Open the EPUB';
    return 'Open the book file';
  }
}

/// One chapter, in the order the reader walks them.
///
/// Flat with a rule under it rather than a card, matching the catalog:
/// a chapter list is a *table of contents*, and boxing each entry would
/// say each one is an offer rather than a place on the way through.
///
/// The trailing **Read** label is not decoration. There is no chevron
/// glyph vendored (§4.3 keeps the set tiny), and a row with no visible
/// affordance is a row a reader has to be told is tappable.
class _ChapterRow extends StatelessWidget {
  const _ChapterRow({super.key, required this.chapter, required this.onTap});

  final Chapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border, width: BooklyBorder.thin),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: BooklySpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${chapter.position}',
                    style: BooklyType.labelLg
                        .copyWith(color: colors.textTertiary),
                  ),
                ),
                const SizedBox(width: BooklySpace.sm),
                Expanded(
                  child: Text(
                    chapter.title,
                    style: BooklyType.bodyMd.copyWith(color: colors.text),
                  ),
                ),
                const SizedBox(width: BooklySpace.sm),
                Text(
                  'Read',
                  style: BooklyType.button.copyWith(color: colors.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One link, ready to open (§5.7).
///
/// The glyph says what *kind* of thing it is before the title is read —
/// a reader scanning for "the podcast one" should not have to parse a
/// word to find it. `circle-play` and `mic-vocal` rather than the brand
/// marks §5.7 named: Lucide deleted every logo upstream, and a glyph
/// that depicts *playing* and *recording* ages better than one that
/// spells a company (see `assets/icons/README.md`).
///
/// Like [_ChapterRow], the trailing label exists because no chevron is
/// vendored and the row has to advertise its own affordance.
class _LinkRow extends StatelessWidget {
  const _LinkRow({super.key, required this.link, required this.onTap});

  final BookLink link;
  final VoidCallback onTap;

  BooklyIconKind get _glyph => switch (link.kind) {
        LinkKind.youtube => BooklyIconKind.circlePlay,
        LinkKind.podcast => BooklyIconKind.micVocal,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
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
            padding: const EdgeInsets.symmetric(vertical: BooklySpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BooklyIcon(_glyph, size: 20, color: colors.textSecondary),
                const SizedBox(width: BooklySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        style:
                            BooklyType.bodyMd.copyWith(color: colors.text),
                      ),
                      const SizedBox(height: BooklySpace.xs),
                      Text(
                        link.kind.label.toUpperCase(),
                        style: BooklyType.labelSm
                            .copyWith(color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BooklySpace.sm),
                Text(
                  'Open',
                  style: BooklyType.button.copyWith(color: colors.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
