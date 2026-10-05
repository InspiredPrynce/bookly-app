import 'package:flutter/material.dart';

import '../../../core/design_system/bookly_design_system.dart';
import '../../../core/widgets/bookly_text_field.dart';
import '../domain/chapter_draft.dart';

/// The chapters section of `CreateBookScreen` (PLAN.md §5.1).
///
/// Owns the `TextField`s but not the list. The order and identity of the
/// rows belong to the screen, because that is what `BookRepository`
/// receives and what §5.3 counts — while the *text* belongs here, keyed
/// by [ChapterDraft.key] rather than by position. That is what keeps a
/// title attached to its own row while a reorder moves the rows
/// underneath it: position changes, key does not.
///
/// Controllers are released when the editor unmounts rather than when a
/// row is removed. Removing one mid-rebuild would dispose a controller
/// its `TextField` has not finished with yet, and the rows in a create
/// form are few and short-lived — holding a removed title until the form
/// closes costs nothing worth the timing hazard.
class ChapterListEditor extends StatefulWidget {
  const ChapterListEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  /// The screen's list, in display order.
  final List<ChapterDraft> value;

  /// Hands the whole list back — never a row, so the caller cannot end
  /// up holding a mutation that did not make it into the order.
  final ValueChanged<List<ChapterDraft>> onChanged;

  /// Whether §5.3's "nothing to read" rule should be shown. Off until
  /// the reader has actually tried to save, so an empty form opens
  /// complete rather than already complaining.
  final bool showError;

  @override
  State<ChapterListEditor> createState() => _ChapterListEditorState();
}

class _ChapterListEditorState extends State<ChapterListEditor> {
  final Map<int, TextEditingController> _controllers = {};

  /// Monotonic, and never rewound when rows are removed — so a key this
  /// editor has handed out is never handed out again, and a removed row
  /// can never come back wearing someone else's text.
  int? _cursor;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
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

  TextEditingController _controllerFor(ChapterDraft draft) => _controllers
      .putIfAbsent(draft.key, () => TextEditingController(text: draft.title));

  void _replace(List<ChapterDraft> next) {
    widget.onChanged(next);
    setState(() {});
  }

  void _addChapter() => _replace([
        ...widget.value,
        ChapterDraft(key: _allocateKey(), title: ''),
      ]);

  void _removeAt(int index) =>
      _replace([...widget.value]..removeAt(index));

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= widget.value.length) return;

    final next = [...widget.value];
    final row = next.removeAt(index);
    next.insert(target, row);
    _replace(next);
  }

  void _retitle(int index, String title) => _replace([
        for (var i = 0; i < widget.value.length; i++)
          i == index ? widget.value[i].copyWith(title: title) : widget.value[i],
      ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.value.length; i++) ...[
          if (i > 0) const SizedBox(height: BooklySpace.sm),
          _ChapterRow(
            index: i,
            draft: widget.value[i],
            controller: _controllerFor(widget.value[i]),
            canMoveUp: i > 0,
            canMoveDown: i < widget.value.length - 1,
            onChanged: (title) => _retitle(i, title),
            onMoveUp: () => _move(i, -1),
            onMoveDown: () => _move(i, 1),
            onRemove: () => _removeAt(i),
          ),
        ],
        if (widget.value.isNotEmpty) const SizedBox(height: BooklySpace.sm),
        TextButton(
          onPressed: _addChapter,
          child: const Text('+ Add chapter'),
        ),
        if (widget.showError && widget.value.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: BooklySpace.xs),
            child: Text(
              'Add at least one chapter, or use links instead.',
              style: BooklyType.bodySm.copyWith(color: colors.danger),
            ),
          ),
      ],
    );
  }
}

/// One chapter as an editable row.
///
/// No icon anywhere: Bookly vendors six Lucide glyphs (§4.3) and none of
/// them is a chevron, and Material's would be a second icon language on
/// a screen that has none. The reordering and removal controls are
/// words instead — slower to read than a glyph, and unambiguous to both
/// a reader and a screen reader, which a bare `↑` is not.
class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.index,
    required this.draft,
    required this.controller,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final int index;
  final ChapterDraft draft;
  final TextEditingController controller;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<String> onChanged;
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
          BooklyTextField(
            controller: controller,
            label: 'Chapter ${index + 1}',
            hint: 'Title',
            textInputAction: TextInputAction.next,
            onChanged: onChanged,
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
