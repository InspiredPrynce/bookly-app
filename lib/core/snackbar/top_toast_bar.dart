import 'dart:async';

import 'package:flutter/material.dart';

import '../design_system/bookly_design_system.dart';
import '../errors/toast_tone.dart';
import 'chime_on_present.dart';
import 'toast_request.dart';

/// The toast bar itself: pinned under the status bar, animated in, and torn
/// down again.
///
/// Owns the exit animation, which is why it is a [StatefulWidget] rather than
/// a stateless `OverlayEntry` builder. A removal has to be *animated* on the
/// way out (timeout, close, swipe) and *instant* on the way in when a newer
/// toast replaces it — two different teardowns, and only something holding a
/// controller can tell them apart. The instant path never enters this widget;
/// it removes the entry, which disposes it.
///
/// ## Anchoring
///
/// [Positioned] at the top of the root overlay behind `SafeArea(bottom:
/// false)`. `ScaffoldMessenger` cannot do this — a `SnackBar` is
/// bottom-anchored with no top option, and `MaterialBanner` is bottom-anchored
/// too while additionally pinning its actions to a fixed height. Owning the
/// presentation outright is the entire cost of the position (PLAN.md §4.5,
/// which overrides DESIGN.md §9 by explicit user instruction).
class TopToastBar extends StatefulWidget {
  const TopToastBar({
    super.key,
    required this.request,
    required this.onDismissed,
  });

  final ToastRequest request;
  final VoidCallback onDismissed;

  @override
  State<TopToastBar> createState() => _TopToastBarState();
}

class _TopToastBarState extends State<TopToastBar>
    with SingleTickerProviderStateMixin {
  /// Entering is `dur-slow` (PLAN.md §4.7); leaving is fast, because
  /// arriving is worth noticing and going is not. Both honour the OS
  /// reduce-motion setting via [BooklyMotion.of].
  late final AnimationController _controller = AnimationController(vsync: this);

  Timer? _timer;

  /// Guards against a double teardown: the timer firing at the same moment
  /// the reader taps close, or a swipe landing on top of a timeout.
  bool _closing = false;

  bool _started = false;

  /// Durations are resolved here and not in `initState`, because reading
  /// `MediaQuery` from `initState` is not allowed — it is a dependency, and
  /// `initState` runs before dependencies may be depended upon.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    _controller.duration = BooklyMotion.of(context, BooklyMotion.slow);
    _controller.reverseDuration = BooklyMotion.of(context, BooklyMotion.fast);
    _controller.forward();

    /// The clock starts when the bar is asked for, not when it finishes
    /// animating in — otherwise a 320ms entrance would eat a meaningful
    /// slice of the time the reader actually gets to read it.
    _timer = Timer(widget.request.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// The animated way out: reverse, then report.
  void _dismiss() {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    _controller.reverse().whenComplete(widget.onDismissed);
  }

  /// The instant way out, for a swipe. [Dismissible] has already carried the
  /// bar off the top by the time this runs, so animating again would be a
  /// second, slower movement of something that is already gone.
  void _dismissNow() {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final request = widget.request;
    final scheme = _schemeFor(colors, request.tone);

    final curved = CurvedAnimation(
      parent: _controller,
      curve: BooklyMotion.standard,
      reverseCurve: BooklyMotion.exit,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BooklySpace.screenMobile,
            vertical: BooklySpace.sm,
          ),
          child: SlideTransition(
            /// Down from above the status bar. A fade alone reads as the bar
            /// blinking into existence; the slide is what makes "it came from
            /// the top" legible rather than assumed.
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: _controller,
              child: Dismissible(
                /// Swipe up to dismiss, as a `SnackBar` did. Losing it would
                /// be a silent regression: it is the fastest way to clear a
                /// toast mid-read and it is muscle memory from every other
                /// Android app.
                key: ValueKey(request),
                direction: DismissDirection.up,
                dismissThresholds: const {DismissDirection.up: 0.4},
                onDismissed: (_) => _dismissNow(),
                child: ChimeOnPresent(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: scheme.ground,

                      /// An editorial rule down the hinge rather than a
                      /// tinted background: the tone is stamped onto the bar
                      /// instead of flooding it, which keeps six tones
                      /// reading as one system.
                      border: Border(
                        left: BorderSide(
                          color: scheme.mark,
                          width: BooklyBorder.strong,
                        ),
                      ),
                      borderRadius: BooklyRadius.rSm,
                      boxShadow: BooklyElevation.level(context, 3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        BooklySpace.md,
                        BooklySpace.sm,
                        BooklySpace.xs,
                        BooklySpace.sm,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(scheme.icon, size: 20, color: scheme.mark),
                          const SizedBox(width: BooklySpace.sm),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (request.title != null) ...[
                                  Text(
                                    request.title!,
                                    style: BooklyType.labelSm
                                        .copyWith(color: scheme.mark),
                                  ),
                                  const SizedBox(height: BooklySpace.xs),
                                ],
                                Text(
                                  request.message,
                                  style: BooklyType.bodySm
                                      .copyWith(color: colors.text),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: BooklySpace.xs),

                          /// 44×44 tap target (PLAN.md §0.1): the close
                          /// affordance exists so dismissal is not reachable
                          /// by swipe alone.
                          IconButton(
                            onPressed: _dismiss,
                            tooltip: 'Dismiss',
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: colors.textSecondary,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: BooklySpace.tapMin,
                              minHeight: BooklySpace.tapMin,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            splashRadius: BooklySpace.tapMin / 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tone → ground, hinge mark and icon.
///
/// Grounds are the `*Subtle` tokens, which are authored to carry `text` at
/// full contrast in both modes; marks are their strong counterparts. `help`
/// uses `accentSubtleText` rather than `accent`, because Burnished Amber
/// against a pale ground is about 2.7:1 — under the 3:1 a non-text mark
/// needs — while the deep amber clears it comfortably.
///
/// No `danger`/`error` split here: the two are the same *look*, differing
/// only in where they appear (bar vs. inline under a field).
({IconData icon, Color ground, Color mark}) _schemeFor(
  BooklyColors colors,
  ToastTone tone,
) =>
    switch (tone) {
      ToastTone.success => (
          icon: Icons.check_circle_outline,
          ground: colors.successSubtle,
          mark: colors.success,
        ),
      ToastTone.error => (
          icon: Icons.error_outline,
          ground: colors.dangerSubtle,
          mark: colors.danger,
        ),
      ToastTone.danger => (
          icon: Icons.error_outline,
          ground: colors.dangerSubtle,
          mark: colors.danger,
        ),
      ToastTone.warning => (
          icon: Icons.warning_amber_outlined,
          ground: colors.warningSubtle,
          mark: colors.warning,
        ),
      ToastTone.info => (
          icon: Icons.info_outline,
          ground: colors.infoSubtle,
          mark: colors.info,
        ),
      ToastTone.help => (
          icon: Icons.lightbulb_outline,
          ground: colors.accentSubtle,
          mark: colors.accentSubtleText,
        ),
    };
