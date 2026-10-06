import 'dart:async';

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
import '../../progress/application/book_progress_controller.dart';
import '../../progress/application/book_progress_state.dart';
import '../../progress/domain/item_status.dart';
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
/// ## Two providers, because two things can be wrong at once
///
/// The book comes from `BookDetailController`; the ticks beside its
/// rows come from `BookProgressController` — a different feature over a
/// different table (PLAN.md §1.3 gives progress its own folder, and the
/// rule is that cross-feature access goes through providers rather than
/// reaching into another feature's `data/`).
///
/// One state object holding both would make a book whose progress failed
/// to load look like a book that failed to load. Keeping them apart, the
/// page still reads — rows honestly say `▸ Not started` — while the
/// failure is reported beside it.
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

      // Progress starts on the same frame rather than after the book.
      // It is a request over a different table, and gating it behind
      // this one would put a whole round trip between the cover
      // arriving and the ticks being right, for no benefit: neither
      // needs the other, and both are read by the same screen.
      final p = ref.read(_progressProvider);
      if (p.progress == null && !p.loading && p.failure == null) {
        ref.read(_progressProvider.notifier).load();
      }
    });
  }

  /// The provider for *this* book — one per family argument, so a
  /// second book on the stack cannot borrow the first one's state.
  NotifierProvider<BookDetailController, BookDetailState> get _provider =>
      bookDetailControllerProvider(widget.bookId);

  /// Same rule, one family over: the reader's ticks for *this* book.
  NotifierProvider<BookProgressController, BookProgressState>
      get _progressProvider => bookProgressControllerProvider(widget.bookId);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(_provider);
    final progress = ref.watch(_progressProvider);

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

    // The second listener is gated on the same condition for the same
    // reason, reached the other way round: while [ErrorView] is up it
    // is already speaking for the page, and a toast about progress
    // beside a book that never arrived answers a question nobody asked.
    ref.listen(_progressProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null) return;
      if (previous?.failure == failure) return;
      if (!ref.read(_provider).hasBook) return;
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
                  ..._body(context, state, progress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────────────────────

  List<Widget> _body(
    BuildContext context,
    BookDetailState state,
    BookProgressState progress,
  ) {
    final colors = context.colors;
    final detail = state.detail!;
    final book = detail.book;
    final shown = progress.shown;

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
            status: shown.chapterStatus(chapter.id),
            pending: progress.isPending(chapter.id),
            onTap: () => _openChapter(chapter),
            onMark: () => unawaited(
              ref.read(_progressProvider.notifier).finishChapter(chapter.id),
            ),
          ),
      ],

      if (detail.hasLinks) ...[
        if (detail.hasChapters) const SizedBox(height: BooklySpace.xl),
        const SizedBox(height: BooklySpace.lg),
        _section('Links', colors.textSecondary),
        if (detail.links.length > 1) ...[
          const SizedBox(height: BooklySpace.xs),
          _linkProgress(context, detail.links.length, shown.finishedLinkCount),
        ],
        const SizedBox(height: BooklySpace.xs),
        for (final link in detail.links)
          _LinkRow(
            key: ValueKey(link.id),
            link: link,
            status: shown.linkStatus(link.id),
            pending: progress.isPending(link.id),
            onTap: () => _open(link),
            onMark: () => unawaited(
              ref.read(_progressProvider.notifier).finishLink(link.id),
            ),
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

  /// §5.7's "links completed ÷ total": the count in tabular figures,
  /// the bar under it.
  ///
  /// The bar is excluded from semantics because the count above it is
  /// already a sentence — announced as well, a screen reader would hear
  /// the same words twice, once for a number and once for a picture of
  /// it. [CompletionBar] draws; the text speaks.
  ///
  /// Only drawn for more than one link: with a single item, "0 of 1
  /// completed" restates the row a few pixels below it.
  Widget _linkProgress(BuildContext context, int total, int finished) {
    final colors = context.colors;
    final complete = finished >= total;
    final label = '$finished of $total completed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BooklyType.labelSm.copyWith(
            color: complete ? colors.success : colors.textSecondary,
            fontFeatures: BooklyType.numeric,
          ),
        ),
        const SizedBox(height: BooklySpace.xs),
        ExcludeSemantics(
          child: CompletionBar(value: total == 0 ? 0 : finished / total),
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _retry() {
    ref.read(_provider.notifier).load();
    ref.read(_progressProvider.notifier).load();
  }

  /// §5.7: a chapter row **is** the "Open" of a chapter.
  ///
  /// The write starts first and is not awaited: it is a record the
  /// reader made an attempt, not a gate on the attempt succeeding, and
  /// a network that cannot say so must not be the reason they cannot
  /// read. If it does fail, it surfaces through the listener set up in
  /// [build], which is still registered — pushing a route leaves this
  /// screen on the stack underneath it.
  void _openChapter(Chapter chapter) {
    unawaited(
      ref.read(_progressProvider.notifier).startChapter(chapter.id),
    );
    context.push(Routes.chapter(widget.bookId, chapter.id));
  }

  /// §5.7: **Open** → `url_launcher`.
  ///
  /// The progress write happens only once the link actually opened.
  /// Crediting `item_progress = reading` before the launch would record
  /// a transition the reader never made, and the `circle_events` row
  /// that follows from it (migration 000006) is written by a trigger
  /// with no way to find out it was wrong.
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
      if (!mounted) return;

      if (!opened) {
        BooklyToast.error('That link could not be opened.');
        return;
      }

      unawaited(ref.read(_progressProvider.notifier).startLink(link.id));
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

/// Colour a row's status is drawn in.
///
/// Three themes, three answers, all measured against the row's own
/// background (`BooklyColors.bg`) — the status is the only thing on the
/// row that changes meaning, so it is the one thing that cannot be
/// hard to read in whichever theme the reader chose:
///
/// | | Light | Dark | Night-paper |
/// |---|---|---|---|
/// | `notStarted` | 5.21:1 | 7.18:1 | 7.33:1 |
/// | `reading` | 8.28:1 | 11.88:1 | 12.14:1 |
/// | `finished` | 5.47:1 | 8.87:1 | 9.06:1 |
///
/// `accent` is deliberately *not* the "reading" colour: Burnished Amber
/// on Warm Paper is 2.46:1, which is why the design system carries
/// [BooklyColors.accentSubtleText] — the amber meant to be read rather
/// than the amber meant to be filled.
Color _statusColor(BooklyColors colors, ItemStatus status) =>
    switch (status) {
      ItemStatus.notStarted => colors.textSecondary,
      ItemStatus.reading => colors.accentSubtleText,
      ItemStatus.finished => colors.success,
    };

/// The secondary action a row offers — **Mark as read** / **Mark as
/// watched** — as a real tap target rather than another bare `Text`.
///
/// A `TextButton` with its chrome taken off, rather than a
/// `GestureDetector`: the chrome is not what makes it a button, and
/// dropping it would also drop the disabled state, which this row
/// wants, because the control goes inert while its write is in flight.
Widget _rowAction({
  required String label,
  required bool enabled,
  required VoidCallback onPressed,
  required Color color,
}) =>
    TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(
          horizontal: BooklySpace.xs,
          vertical: BooklySpace.xs,
        ),
      ),
      child: Text(
        label,
        style: BooklyType.button.copyWith(
          color: enabled ? color : color.withValues(alpha: 0.4),
        ),
      ),
    );

/// One chapter, in the order the reader walks them.
///
/// Flat with a rule under it rather than a card, matching the catalog:
/// a chapter list is a *table of contents*, and boxing each entry would
/// say each one is an offer rather than a place on the way through.
///
/// The trailing **Read** label is not decoration. There is no chevron
/// glyph vendored (§4.3 keeps the set tiny), and a row with no visible
/// affordance is a row a reader has to be told is tappable.
///
/// **Mark as read** sits under it and only exists while there is
/// something left to mark. §5.7 gives the affordance to link rows,
/// where watching happens off-app; a chapter gets the same one because
/// the reader may well have read it somewhere the app cannot see —
/// their circle's feed is fed by the same `finished_chapter` either
/// way, and asking them to re-read a chapter to say so would be worse
/// than a button.
class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    super.key,
    required this.chapter,
    required this.status,
    required this.pending,
    required this.onTap,
    required this.onMark,
  });

  final Chapter chapter;
  final ItemStatus status;
  final bool pending;
  final VoidCallback onTap;
  final VoidCallback onMark;

  bool get _finished => status == ItemStatus.finished;

  /// §5.7 names the two endpoints; the middle state is left to us, and
  /// "reading" is the verb the reader would use for it.
  String get _statusLine => switch (status) {
        ItemStatus.notStarted => '▸ Not started',
        ItemStatus.reading => '▸ Reading…',
        ItemStatus.finished => '▸ Read ✓',
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: BooklySpace.md),
            child: Row(
              // Top, not centre: the row is now two lines deep on the
              // left and two labels deep on the right, and centring
              // would hang the trailing pair off the middle of a title
              // that may have wrapped to three.
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: BooklyType.bodyMd.copyWith(color: colors.text),
                      ),
                      const SizedBox(height: BooklySpace.xs),
                      Text(
                        _statusLine,
                        style: BooklyType.labelSm
                            .copyWith(color: _statusColor(colors, status)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BooklySpace.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Read',
                      style: BooklyType.button.copyWith(color: colors.textLink),
                    ),
                    if (!_finished) ...[
                      const SizedBox(height: BooklySpace.xs),
                      _rowAction(
                        label: 'Mark as read',
                        enabled: !pending,
                        color: colors.textLink,
                        onPressed: onMark,
                      ),
                    ],
                  ],
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
///
/// The status and the kind share a line rather than stacking, because
/// together they are one fact — "this, in this state" — and three lines
/// per row is a list a reader has to scroll past to reach the link they
/// came for. [Wrap] rather than [Row] so that a narrow screen and a
/// long kind label run on instead of overflowing the row.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    super.key,
    required this.link,
    required this.status,
    required this.pending,
    required this.onTap,
    required this.onMark,
  });

  final BookLink link;
  final ItemStatus status;
  final bool pending;
  final VoidCallback onTap;
  final VoidCallback onMark;

  bool get _finished => status == ItemStatus.finished;

  BooklyIconKind get _glyph => switch (link.kind) {
        LinkKind.youtube => BooklyIconKind.circlePlay,
        LinkKind.podcast => BooklyIconKind.micVocal,
      };

  /// §5.7 spells these as `▸ Start ▶` and `▸ Watched ✓`. The middle
  /// state it does not name, and "started" would be wrong for something
  /// half-watched — so the verb is what the reader is doing.
  String get _statusLine => switch (status) {
        ItemStatus.notStarted => '▸ Start ▶',
        ItemStatus.reading => switch (link.kind) {
            LinkKind.youtube => '▸ Watching…',
            LinkKind.podcast => '▸ Listening…',
          },
        ItemStatus.finished => switch (link.kind) {
            LinkKind.youtube => '▸ Watched ✓',
            LinkKind.podcast => '▸ Listened ✓',
          },
      };

  /// §5.7's words, and they are the right ones: the reader did not read
  /// a video, and saying "finished" would leave them to work out what
  /// was finished.
  String get _markLabel => switch (link.kind) {
        LinkKind.youtube => 'Mark as watched',
        LinkKind.podcast => 'Mark as listened',
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
                      Wrap(
                        spacing: BooklySpace.xs,
                        runSpacing: BooklySpace.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _statusLine,
                            style: BooklyType.labelSm
                                .copyWith(color: _statusColor(colors, status)),
                          ),
                          Text(
                            link.kind.label.toUpperCase(),
                            style: BooklyType.labelSm
                                .copyWith(color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BooklySpace.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Open',
                      style: BooklyType.button.copyWith(color: colors.textLink),
                    ),
                    if (!_finished) ...[
                      const SizedBox(height: BooklySpace.xs),
                      _rowAction(
                        label: _markLabel,
                        enabled: !pending,
                        color: colors.textLink,
                        onPressed: onMark,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
