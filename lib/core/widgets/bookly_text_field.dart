import 'package:flutter/material.dart';

import '../design_system/bookly_design_system.dart';

/// The card-catalog input: a stamped uppercase label over a single bottom
/// rule, never a four-sided box (PLAN.md §4.2, `BooklyBorder.inputBottom`).
///
/// The label is built as a [Text] above the field rather than through
/// `InputDecoration.labelText`, for two reasons. The Literary Clothbound
/// convention is that every label token is rendered **uppercase at the
/// call site** — `TextStyle` has no case property, so the conversion has to
/// happen where the label is built anyway. And it makes the field's
/// geometry fixed: the rule sits in the same place whether the field is
/// empty, filled or in error, so a column of them lines up like entries on
/// a catalogue card instead of reflowing as the reader types.
///
/// Errors render inline beneath the rule (§3.2 "danger, inline under
/// field"), never as a toast — a toast tells you something went wrong
/// somewhere, and a field error tells you *which field*.
class BooklyTextField extends StatefulWidget {
  const BooklyTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.autocorrect = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.validator,
  });

  /// Rendered above the rule, uppercased here as the spec requires.
  final String label;

  final TextEditingController? controller;

  /// Placeholder shown while empty. Defaults to [label] at reduced weight.
  final String? hint;

  /// Inline failure copy. Non-null puts the rule and text into `danger`.
  final String? errorText;

  /// Optional guidance under the rule, hidden while [errorText] is set.
  final String? helperText;

  /// Password entry. Adds a Show/Hide toggle rather than leaving the
  /// reader to retype — visible text is the cheaper error to make.
  final bool obscure;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  /// Client-side validation (PLAN.md §3.2: a password below policy is
  /// wrong *inside its field*, so it is reported there).
  ///
  /// Separate from [errorText] on purpose: `validator` is what the form
  /// asks for on submit, `errorText` is what the repository answered
  /// afterwards. Conflating them would make a field the reader has
  /// already corrected keep showing a server rejection, and would make a
  /// server rejection disappear the moment they typed a character.
  final FormFieldValidator<String>? validator;

  @override
  State<BooklyTextField> createState() => _BooklyTextFieldState();
}

class _BooklyTextFieldState extends State<BooklyTextField> {
  late bool _obscured = widget.obscure;

  bool get _hasError => widget.errorText != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hint = widget.hint ?? widget.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: BooklyType.labelMd.copyWith(
            color: _hasError ? colors.danger : colors.textSecondary,
          ),
        ),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          autocorrect: widget.autocorrect,
          enableSuggestions: !widget.obscure,
          textCapitalization: widget.textCapitalization,
          maxLines: widget.maxLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          style: BooklyType.bodyMd.copyWith(color: colors.text),
          decoration: InputDecoration(
            hintText: hint,
            errorText: widget.errorText,
            helperText: widget.errorText == null ? widget.helperText : null,
            suffixIcon: widget.obscure ? _buildReveal(context) : null,
            suffixIconConstraints: const BoxConstraints(
              minHeight: BooklySpace.tapMin,
            ),
          ),
        ),
      ],
    );
  }

  /// Show/Hide for password fields.
  ///
  /// A text toggle rather than an eye icon: Bookly vendors six Lucide
  /// glyphs (PLAN.md §4.3) and `eye` is not among them, and a word needs
  /// no glyph to be understood. Set in the bibliographic label voice so it
  /// reads as an instruction, not a button.
  ///
  /// Lives on this State rather than as a sibling widget so the rebuild
  /// runs through its own `setState` — reaching into a State from outside
  /// is a protected member, and fragile besides.
  Widget _buildReveal(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _obscured = !_obscured),
      style: TextButton.styleFrom(
        minimumSize: const Size(BooklySpace.tapMin, BooklySpace.tapMin),
        padding: const EdgeInsets.symmetric(horizontal: BooklySpace.sm),
        foregroundColor: context.colors.textSecondary,
        textStyle: BooklyType.labelSm,
      ),
      child: Text(_obscured ? 'SHOW' : 'HIDE'),
    );
  }
}
