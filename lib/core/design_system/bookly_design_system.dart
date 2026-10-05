/// Bookly design system barrel.
///
/// ```dart
/// import 'package:bookly/core/design_system/bookly_design_system.dart';
/// ```
///
/// Import this for everything at once, or a single file when only one piece
/// is needed — the split files are the source of truth, this is a convenience
/// only.
///
/// Source: `branding/DESIGN.md`. Where this code and DESIGN.md disagree,
/// DESIGN.md wins — except where PLAN.md records an explicit user override
/// (top-anchored toast, single chime, Lucide icons).
library;

// Foundations
export 'bookly_colors.dart';
export 'bookly_theme.dart';
export 'bookly_theme_mode.dart';
export 'bookly_tokens.dart';
export 'bookly_typography.dart';

// Components — split per PLAN.md §0.1 (one enum per file, no unrelated
// classes sharing a file).
export 'components/book_cover.dart';
export 'components/bookly_chat_bubble.dart';
export 'components/bubble_kind.dart';
export 'components/member_avatar.dart';
export 'components/reading_progress_bar.dart';

// Logo — one lockup construction per file.
export 'logo/bookly_lockup.dart';
export 'logo/bookly_mark.dart';
