import 'package:flutter/material.dart';

import '../bookly_tokens.dart';

/// Shared-axis X page transition (PLAN.md §4.7): the outgoing and incoming
/// surfaces slide along the horizontal axis while cross-fading, so a push
/// reads as one book being slid aside for another rather than two screens
/// stacked on each other.
///
/// Bookly owns this widget rather than depending on `package:animations`.
/// That package's `SharedAxisPageTransitionsBuilder` has the right shape but
/// takes its duration from the route, and every `PageRoute` Flutter ships
/// fixes that at 300ms — while PLAN.md §4.7 specifies `dur-slow` (320ms).
/// `booklyPage` in `app_router.dart` supplies the duration; this widget
/// supplies the motion.
///
/// ## Structure
///
/// Two nested [DualTransitionBuilder]s, not one. A route is very often
/// finishing its own entrance at the same moment it is being covered by the
/// next one — a fast double-tap — and a single builder can only handle one
/// of those at a time. The outer builder reads the route's own animation:
/// entering and leaving. The inner one reads the *secondary* animation
/// reversed, so being covered slides the route out to the left and being
/// uncovered again slides it back in from the left.
///
/// ## The curves are Bookly's
///
/// The slide follows [BooklyMotion.standard], the entrance fade
/// [BooklyMotion.enter] over the last 70% of the transition, the exit fade
/// [BooklyMotion.exit]. The entrance holding still for its first 30% is
/// deliberate: the outgoing surface completes most of its travel before the
/// incoming one becomes visible, which is what keeps the pair from reading
/// as two independently moving layers.
class SharedAxisXTransition extends StatelessWidget {
  const SharedAxisXTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    this.fillColor,
    this.child,
  });

  /// The route's own animation — driving its entrance and its exit.
  final Animation<double> animation;

  /// The animation of whatever is above this route: rising while this route
  /// is covered, falling as it is uncovered.
  final Animation<double> secondaryAnimation;

  /// Painted behind the surface while it moves, so the strip it slides open
  /// shows this route's own background rather than a half-faded page
  /// underneath. Defaults to the theme's scaffold background.
  final Color? fillColor;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final fill = fillColor ?? Theme.of(context).scaffoldBackgroundColor;

    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (context, animation, child) => _EnterTransition(
        animation: animation,
        child: child,
      ),
      reverseBuilder: (context, animation, child) => _ExitTransition(
        animation: animation,
        reverse: true,
        fillColor: fill,
        child: child,
      ),
      child: DualTransitionBuilder(
        animation: ReverseAnimation(secondaryAnimation),
        forwardBuilder: (context, animation, child) => _EnterTransition(
          animation: animation,
          reverse: true,
          child: child,
        ),
        reverseBuilder: (context, animation, child) => _ExitTransition(
          animation: animation,
          fillColor: fill,
          child: child,
        ),
        child: child,
      ),
    );
  }
}

/// How far a surface travels on a shared-axis X, in logical pixels.
///
/// An absolute offset rather than a fraction of the screen, because the
/// effect is meant to read as a small lateral nudge on any device — a 12%
/// slide on a tablet would be a different gesture altogether.
const double _kTravel = 30;

class _EnterTransition extends StatelessWidget {
  const _EnterTransition({
    required this.animation,
    this.reverse = false,
    this.child,
  });

  final Animation<double> animation;

  /// `true` when the surface is coming back from the left rather than in
  /// from the right.
  final bool reverse;

  final Widget? child;

  /// Opaque until 30%, then in.
  static final Animatable<double> _fade = CurveTween(
    curve: BooklyMotion.enter,
  ).chain(CurveTween(curve: const Interval(0.3, 1.0)));

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: Offset(reverse ? -_kTravel : _kTravel, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: BooklyMotion.standard));

    return FadeTransition(
      opacity: _fade.animate(animation),
      child: ListenableBuilder(
        listenable: animation,
        builder: (context, child) =>
            Transform.translate(offset: slide.transform(animation), child: child),
        child: child,
      ),
    );
  }
}

class _ExitTransition extends StatelessWidget {
  const _ExitTransition({
    required this.animation,
    required this.fillColor,
    this.reverse = false,
    this.child,
  });

  final Animation<double> animation;

  /// `true` when the surface retreats back to the right — the pop that
  /// undoes a push.
  final bool reverse;

  final Color fillColor;

  final Widget? child;

  /// The surface stays present through its travel and lets go at the end,
  /// rather than thinning out from the start — see [_FlippedCurveTween].
  static final Animatable<double> _fade = _FlippedCurveTween(
    curve: BooklyMotion.exit,
  ).chain(CurveTween(curve: const Interval(0.0, 0.3)));

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(reverse ? _kTravel : -_kTravel, 0),
    ).chain(CurveTween(curve: BooklyMotion.standard));

    return FadeTransition(
      opacity: _fade.animate(animation),
      child: ColoredBox(
        color: fillColor,
        child: ListenableBuilder(
          listenable: animation,
          builder: (context, child) => Transform.translate(
            offset: slide.transform(animation),
            child: child,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A [CurveTween] whose output is flipped vertically, so the exit fade rises
/// while the exit animation falls.
///
/// Without the flip the fade would be driven straight by the exit curve:
/// the surface would start thinning the moment it began to move, and the
/// gap it slides open would show through it. Flipped, it holds at full
/// strength while it travels and lets go only once the incoming surface has
/// had time to arrive.
class _FlippedCurveTween extends CurveTween {
  _FlippedCurveTween({required super.curve});

  @override
  double transform(double t) => 1 - super.transform(t);
}
