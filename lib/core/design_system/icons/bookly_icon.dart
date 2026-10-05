import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'bookly_icon_kind.dart';

/// The only way Bookly draws an icon.
///
/// ```dart
/// const BooklyIcon(BooklyIconKind.circleCheck, size: 20, color: mark);
/// ```
///
/// This replaces `Icon(Icons.*)`, and that is not a like-for-like swap —
/// which is the reason this widget exists rather than `SvgPicture.asset`
/// being spelled out at every call site:
///
/// * **Stroke weight.** PLAN.md §4.3 asks for 1.75px on the 24px grid. An
///   `IconData` glyph cannot honour that: the weight is cut into the font
///   and no argument changes it. The vendored SVG carries it, and
///   [BooklyIconKind.assetPath] is the only place a filename is written
///   down, so a weight change is one asset edit rather than N call sites.
/// * **Colour.** `currentColor` inside the SVG resolves from `SvgTheme`
///   (default black), not from the widget's arguments, and flutter_svg's
///   `color` parameter is deprecated in 2.x in favour of `colorFilter`.
///   Resolving the colour here and applying it as one [ColorFilter] with
///   [BlendMode.srcIn] sidesteps both: it replaces every painted pixel's
///   colour while keeping its alpha, so the stroke takes the resolved colour
///   whatever the file happens to say.
/// * **Semantics.** A screen reader sees a picture unless told otherwise.
///   [semanticLabel] opts in. Without it the glyph is excluded from the
///   semantics tree outright, rather than surfacing as an unlabelled node
///   that reads as nothing.
///
/// Defaults deliberately mirror `Icon` — [size] 24 and [color] inherited
/// from the ambient [IconTheme] — so converting a call site is a rename
/// rather than a re-audit of every value.
class BooklyIcon extends StatelessWidget {
  const BooklyIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  /// Which glyph to draw.
  final BooklyIconKind icon;

  /// Edge length in logical pixels.
  ///
  /// The authored grid is 24, so 24 renders at exactly the weight the asset
  /// was cut for. Any other size scales the stroke along with the box —
  /// there is no optical compensation, because none of these are set at
  /// text sizes where it would show.
  final double size;

  /// Stroke colour; falls back to the ambient [IconTheme].
  final Color? color;

  /// Text assistive technology reads in place of the picture.
  ///
  /// Null means the icon is decorative — whatever it marks is already
  /// spelled out by the text beside it — and the glyph is then kept out of
  /// the semantics tree entirely instead of being announced as blank.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    /// [Icon] reaches the same value as `color ?? iconTheme.color!`. The
    /// trailing default here exists only because the assertion would turn a
    /// missing theme colour into a crash on the frame that draws an icon,
    /// and a black glyph beats a red screen.
    final resolved =
        color ?? IconTheme.of(context).color ?? const Color(0xFF000000);

    return SvgPicture.asset(
      icon.assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
