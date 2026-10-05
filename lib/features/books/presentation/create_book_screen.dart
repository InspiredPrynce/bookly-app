import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/bookly_design_system.dart';
import '../../../core/snackbar/bookly_toast.dart';
import '../../../core/snackbar/present_failure.dart';
import '../../../core/utils/avatar_image.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bookly_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/create_book_controller.dart';
import '../domain/book_link_draft.dart';
import '../domain/book_publish_rule.dart';
import '../domain/chapter_draft.dart';
import 'chapter_list_editor.dart';
import 'link_list_editor.dart';

/// Building a book from nothing (PLAN.md §5.1–5.3).
///
/// Four sections in one scroll — details, cover, chapters, links —
/// because §5.3 makes chapters and links interchangeable ways of
/// satisfying the publish rule, and a form that hid one of them behind
/// a later step would be quietly telling the reader which kind of book
/// is the real one.
///
/// The *shape* of this screen is `EditProfileScreen`'s: the form's text
/// belongs to the screen's controllers, the attempt belongs to the
/// provider. What differs is the cover — it is held by the provider,
/// not here, because a jacket chosen and then lost to a failed submit
/// is the same cost as an avatar, and `CreateBookController` documents
/// why that is the one input worth holding onto.
class CreateBookScreen extends ConsumerStatefulWidget {
  const CreateBookScreen({super.key});

  @override
  ConsumerState<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends ConsumerState<CreateBookScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _authors = TextEditingController();
  final TextEditingController _about = TextEditingController();

  List<ChapterDraft> _chapters = [];
  List<BookLinkDraft> _links = [];

  /// Gates only §5.3's rule. Field errors are driven by
  /// `Form.validate()`, so a form the reader has not yet tried to save
  /// opens complete rather than already complaining about a title they
  /// have not finished typing.
  bool _showErrors = false;

  CreateBookController get _controller =>
      ref.read(createBookControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Unconditional: a `createdBookId` from the book made a moment ago
    // must not read as success for the next one, and a jacket chosen
    // and abandoned is not a jacket this form should still be holding.
    _controller.reset();
  }

  @override
  void dispose() {
    _title.dispose();
    _authors.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    // A dismissed picker stays null and is never a failure (§3.3's
    // rule, which applies to any image Bookly lets a reader choose).
    final bytes = await pickAndCompressImage(maxWidth: 900, maxHeight: 1350);
    if (bytes == null || !mounted) return;
    setState(() => _controller.setCover(bytes));
  }

  void _clearCover() => setState(() => _controller.setCover(null));

  /// Rows the reader added and never typed into are not rows.
  ///
  /// Pruned *before* validating so an abandoned "+ Add chapter" is not
  /// an error they have to undo by hand. A half-filled link is kept and
  /// will fail its own field: that one they did start.
  void _prune() {
    _chapters = [for (final c in _chapters) if (c.title.trim().isNotEmpty) c];
    _links = [
      for (final l in _links)
        if (l.title.trim().isNotEmpty || l.url.trim().isNotEmpty) l,
    ];
  }

  Future<void> _save() async {
    _prune();
    setState(() {});

    // The pruned rows are still mounted until this frame lands, and
    // asking them now would consult `TextFormFields` that are about to
    // be unmounted.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final formOk = _formKey.currentState?.validate() ?? false;
    final publishable = BookPublishRule.isPublishable(
      chapterCount: _chapters.length,
      linkCount: _links.length,
    );

    if (!publishable) setState(() => _showErrors = true);
    if (!formOk || !publishable) return;

    final id = await _controller.create(
      title: _title.text,
      authorsRaw: _authors.text,
      about: _about.text,
      chapters: _chapters,
      links: _links,
    );

    if (!mounted) return;
    if (id != null) {
      BooklyToast.success('Book created.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(createBookControllerProvider);

    // Side effects belong in a listener, never in `build` — raising a
    // toast from here would fire again on every re-render while the
    // failure sits there.
    ref.listen(createBookControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure != null && !identical(failure, previous?.failure)) {
        presentFailure(failure);
      }
    });

    final cover = _controller.coverBytes;
    final publishable = BookPublishRule.isPublishable(
      chapterCount: _chapters.length,
      linkCount: _links.length,
    );

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
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
                  Text(
                    'New book',
                    style: BooklyType.headlineMd.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: BooklySpace.xs),
                  Text(
                    'Books are written by the readers who keep them.',
                    style: BooklyType.bodySm.copyWith(
                      color: colors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: BooklySpace.xl),

                  // ── Details ────────────────────────────────────────────
                  _Section(
                    title: 'Details',
                    subtitle: 'What the catalog shows first.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BooklyTextField(
                          controller: _title,
                          label: 'Title',
                          validator: (v) => Validators.title(
                            v,
                            message: 'Enter a title.',
                          ),
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: BooklySpace.lg),
                        BooklyTextField(
                          controller: _authors,
                          label: 'Authors',
                          hint: 'Ursula K. Le Guin, Terry Pratchett',
                          helperText: 'Separate several with commas.',
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: BooklySpace.lg),
                        BooklyTextField(
                          controller: _about,
                          label: 'About (optional)',
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BooklySpace.xl),

                  // ── Cover ──────────────────────────────────────────────
                  _Section(
                    title: 'Cover',
                    subtitle: 'A jacket, not a requirement.',
                    child: Center(
                      child: cover == null
                          ? TextButton(
                              onPressed: _pickCover,
                              child: const Text('+ Add cover'),
                            )
                          : Column(
                              children: [
                                BookCover(
                                  image: MemoryImage(cover),
                                  width: 96,
                                ),
                                const SizedBox(height: BooklySpace.sm),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: _pickCover,
                                      child: const Text('Change cover'),
                                    ),
                                    TextButton(
                                      onPressed: _clearCover,
                                      style: TextButton.styleFrom(
                                        foregroundColor: colors.danger,
                                      ),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: BooklySpace.xl),

                  // ── Chapters ───────────────────────────────────────────
                  _Section(
                    title: 'Chapters',
                    subtitle: 'Ordered as they will be read.',
                    child: ChapterListEditor(
                      value: _chapters,
                      onChanged: (next) => setState(() => _chapters = next),
                    ),
                  ),
                  const SizedBox(height: BooklySpace.xl),

                  // ── Links ──────────────────────────────────────────────
                  _Section(
                    title: 'Links',
                    subtitle: 'YouTube and podcast episodes this book '
                        'points at.',
                    child: LinkListEditor(
                      value: _links,
                      onChanged: (next) => setState(() => _links = next),
                    ),
                  ),

                  // ── §5.3 ───────────────────────────────────────────────
                  const SizedBox(height: BooklySpace.sm),
                  Text(
                    _showErrors && !publishable
                        ? BookPublishRule.missingContentMessage
                        : BookPublishRule.hint,
                    style: BooklyType.bodySm.copyWith(
                      color: _showErrors && !publishable
                          ? colors.danger
                          : colors.textTertiary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: BooklySpace.xl),
                  PrimaryButton(
                    label: 'Create book',
                    submitting: state.saving,
                    onPressed: _save,
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

/// A titled group with a line explaining what belongs in it.
///
/// The subtitle is not decoration: "chapters" and "links" are two
/// equally valid answers to §5.3, and a bare heading would leave the
/// reader guessing which of them Bookly actually wants.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: BooklyType.headlineSm.copyWith(color: colors.text),
        ),
        const SizedBox(height: BooklySpace.xs),
        Text(
          subtitle,
          style: BooklyType.bodySm.copyWith(
            color: colors.textSecondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: BooklySpace.md),
        child,
      ],
    );
  }
}
