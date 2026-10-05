import 'package:flutter/material.dart';

import '../../../core/design_system/bookly_design_system.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bookly_text_field.dart';
import '../domain/book_link_draft.dart';
import '../domain/link_kind.dart';

/// The links section of `CreateBookScreen` (PLAN.md §5.1–5.2).
///
/// Same split as [ChapterListEditor]: the rows belong to the screen and
/// the text belongs to this widget, keyed by [BookLinkDraft.key] so a
/// field stays with its row through a reorder.
///
/// A book with zero chapters and at least one of these is a link-only
/// book, and §5.7 says its `BookDetailScreen` *is* the consumption
/// surface — there is nothing to read, so there is no `ReadingScreen`.
/// That is why this section is a full equal of chapters rather than a
/// supplement to them: §5.3 makes either one sufficient.
class LinkListEditor extends StatefulWidget {
  const LinkListEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  /// The screen's list, in display order — which is `position`.
  final List<BookLinkDraft> value;
  final ValueChanged<List<BookLinkDraft>> onChanged;

  /// Whether §5.3's "nothing to read" rule should be shown.
  final bool showError;

  @override
  State<LinkListEditor> createState() => _LinkListEditorState();
}

class _LinkListEditorState extends State<LinkListEditor> {
  final Map<int, TextEditingController> _titles = {};
  final Map<int, TextEditingController> _urls = {};

  /// Monotonic, never rewound — see `ChapterListEditor` for why.
  int? _cursor;

  @override
  void dispose() {
    for (final controller in _titles.values) {
      controller.dispose();
    }
    for (final controller in _urls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _allocateKey() {
    final seeded = _cursor;
    if (seeded != null) {
      _cursor = seeded + 1;
      return seeded;
    }

    // First call: start above anything already in the list, in case this
    // State was recreated over rows that outlived its predecessor.
    var highest = -1;
    for (final draft in widget.value) {
      if (draft.key > highest) highest = draft.key;
    }

    final key = highest + 1;
    _cursor = key + 1;
    return key;
  }

  TextEditingController _titleFor(BookLinkDraft draft) => _titles.putIfAbsent(
      draft.key, () => TextEditingController(text: draft.title));

  TextEditingController _urlFor(BookLinkDraft draft) => _urls.putIfAbsent(
      draft.key, () => TextEditingController(text: draft.url));

  void _replace(List<BookLinkDraft> next) {
    widget.onChanged(next);
    setState(() {});
  }

  void _addLink() => _replace([
        ...widget.value,
        BookLinkDraft(key: _allocateKey(), kind: LinkKind.youtube, title: '', url: ''),
      ]);

  void _removeAt(int index) => _replace([...widget.value]..removeAt(index));

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= widget.value.length) return;

    final next = [...widget.value];
    final row = next.removeAt(index);
    next.insert(target, row);
    _replace(next);
  }

  void _patch(int index, BookLinkDraft Function(BookLinkDraft) patch) =>
      _replace([
        for (var i = 0; i < widget.value.length; i++)
          i == index ? patch(widget.value[i]) : widget.value[i],
      ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.value.length; i++) ...[
          if (i > 0) const SizedBox(height: BooklySpace.sm),
          _LinkRow(
            index: i,
            draft: widget.value[i],
            titleController: _titleFor(widget.value[i]),
            urlController: _urlFor(widget.value[i]),
            canMoveUp: i > 0,
            canMoveDown: i < widget.value.length - 1,
            onKindChanged: (kind) => _patch(i, (d) => d.copyWith(kind: kind)),
            onTitleChanged: (v) => _patch(i, (d) => d.copyWith(title: v)),
            onUrlChanged: (v) => _patch(i, (d) => d.copyWith(url: v)),
            onMoveUp: () => _move(i, -1),
            onMoveDown: () => _move(i, 1),
            onRemove: () => _removeAt(i),
          ),
        ],
        if (widget.value.isNotEmpty) const SizedBox(height: BooklySpace.sm),
        TextButton(
          onPressed: _addLink,
          child: const Text('+ Add link'),
        ),
        if (widget.showError && widget.value.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: BooklySpace.xs),
            child: Text(
              'Add at least one link, or write some chapters.',
              style: BooklyType.bodySm.copyWith(color: colors.danger),
            ),
          ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.index,
    required this.draft,
    required this.titleController,
    required this.urlController,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onKindChanged,
    required this.onTitleChanged,
    required this.onUrlChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final int index;
  final BookLinkDraft draft;
  final TextEditingController titleController;
  final TextEditingController urlController;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<LinkKind> onKindChanged;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onUrlChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(BooklySpace.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BooklyRadius.rSm,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KindSelector(value: draft.kind, onChanged: onKindChanged),
          const SizedBox(height: BooklySpace.md),
          BooklyTextField(
            controller: titleController,
            label: 'Title',
            hint: 'What is this?',
            onChanged: onTitleChanged,
          ),
          const SizedBox(height: BooklySpace.md),
          BooklyTextField(
            controller: urlController,
            label: 'Link',
            hint: 'https://',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            validator: Validators.url,
            onChanged: onUrlChanged,
          ),
          const SizedBox(height: BooklySpace.xs),
          Row(
            children: [
              TextButton(
                onPressed: canMoveUp ? onMoveUp : null,
                child: const Text('Move up'),
              ),
              TextButton(
                onPressed: canMoveDown ? onMoveDown : null,
                child: const Text('Move down'),
              ),
              const Spacer(),
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(foregroundColor: colors.danger),
                child: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The link type as a two-way switch (§5.2).
///
/// Chosen rather than inferred from the URL: a "guess the kind" helper
/// would be right often enough to be trusted and wrong often enough to
/// file a podcast under YouTube, with no visible consequence until
/// someone else reads the row and sees the wrong glyph.
class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.value, required this.onChanged});

  final LinkKind value;
  final ValueChanged<LinkKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final kind in LinkKind.values) ...[
          if (kind != LinkKind.values.first)
            const SizedBox(width: BooklySpace.sm),
          Expanded(
            child: _KindOption(
              label: kind.label,
              selected: kind == value,
              onTap: () => onChanged(kind),
            ),
          ),
        ],
      ],
    );
  }
}

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BooklyRadius.rSm,
        child: AnimatedContainer(
          duration: BooklyMotion.of(context, BooklyMotion.fast),
          curve: BooklyMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: BooklySpace.sm),
          decoration: BoxDecoration(
            color: selected ? colors.accentSubtle : colors.surface,
            borderRadius: BooklyRadius.rSm,
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: selected ? BooklyBorder.strong : BooklyBorder.thin,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: BooklyType.button.copyWith(
              color: selected ? colors.accentSubtleText : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
