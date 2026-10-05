import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/bookly_design_system.dart';

/// First screen (PLAN.md §4.8): the mark, the session resolving behind it,
/// then `/login` or `/catalog`.
///
/// Built from `branding/flows/splash/splash_screen_light_mode/code.html`.
/// The device status bar in that mock is a mock, so it is not reproduced;
/// everything else is — the ornamental matting frame, the ex-libris stamp,
/// the masthead with its diamond ornament, the "salon assembling" notice,
/// the epigraph, and the gilt reading thread that advances as the app
/// assembles itself.
///
/// ## The thread is the progress indicator
///
/// The stages it walks through are copy, not telemetry: nothing measures
/// "tuning the reading salon". They exist so the wait reads as *preparation*
/// — the app setting a table — rather than as a stalled spinner, which is
/// the whole reason this is a splash screen and not a progress bar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// `(thread width, caption)` per stage, from the reference's script.
typedef _Stage = (double width, String caption);

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const List<_Stage> _stages = [
    (0.42, 'Gathering shared marginalia'),
    (0.68, 'Tuning the reading salon'),
    (0.92, 'Opening the chapter spread'),
    (1.00, 'Welcome to Bookly'),
  ];

  static const _stageInterval = Duration(milliseconds: 850);

  /// Long enough for two stages to have played. A splash that resolves in
  /// 200ms flashes — the reader sees a flicker rather than an opening — and
  /// one that lingers past a few seconds becomes a delay. Two stages is the
  /// middle: enough to be seen, short enough not to be felt.
  static const _minDisplay = Duration(milliseconds: 1700);

  int _stage = 0;
  bool _signedIn = false;
  bool _reducedMotion = false;
  bool _configured = false;

  Timer? _timer;
  Timer? _leaveTimer;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();

    /// Supabase is initialised in `bootstrap` before the tree goes up, so
    /// this is a synchronous read rather than a lookup. The guard is for
    /// widget tests, which pump this screen without a bootstrap behind it —
    /// an uninitialised `Supabase.instance` throws, and "no session known"
    /// is the correct answer there anyway.
    try {
      _signedIn = Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      _signedIn = false;
    }

    _timer = Timer.periodic(_stageInterval, (_) {
      if (_stage >= _stages.length - 1 || !mounted) return;
      setState(() => _stage += 1);
    });

    _leaveTimer = Timer(_minDisplay, _leave);
  }

  /// Reduce-motion is a dependency, and dependencies may not be read from
  /// `initState` — hence here, once.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;

    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (!_reducedMotion) {
      _pulse.repeat(reverse: true);
      return;
    }

    /// Static mark, short hold, then go. The thread never animates because
    /// the reader has asked the system not to animate things.
    setState(() => _stage = _stages.length - 1);
    _timer?.cancel();
    _timer = null;
    _leaveTimer?.cancel();
    _leaveTimer = Timer(const Duration(milliseconds: 400), _leave);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _leaveTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  /// Hands off to the destination the session implies. Splash owns this
  /// decision (PLAN.md §4.8) rather than the router's `redirect`: the screen
  /// that is already waiting for the answer is the one that should act on it.
  void _leave() {
    if (!mounted) return;
    context.go(_signedIn ? Routes.catalog : Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (width, caption) = _stages[_stage];
    final motion = BooklyMotion.of(context, BooklyMotion.slow);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            /// Subtle ornamental inset paper matting frame. Behind
            /// everything and inert — it is a printed border, not a
            /// surface, so it never takes a pointer.
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceSunken.withValues(alpha: 0.3),
                      borderRadius: BooklyRadius.rXl,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BooklySpace.lg,
                vertical: BooklySpace.md,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ExLibris(colors: colors),
                  _Masthead(colors: colors, pulse: _pulse),
                  _Colophon(
                    colors: colors,
                    motion: motion,
                    width: width,
                    caption: caption,
                    animateThread: !_reducedMotion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top stamp: `EX LIBRIS PRIVATUS` between two amber lozenges.
class _ExLibris extends StatelessWidget {
  const _ExLibris({required this.colors});

  final BooklyColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BooklySpace.md,
        vertical: BooklySpace.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BooklyRadius.rFull,
        border: Border.all(color: colors.border, width: BooklyBorder.thin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Lozenge(color: colors.accent),
          const SizedBox(width: BooklySpace.sm),
          Text(
            'EX LIBRIS PRIVATUS',
            style: BooklyType.labelSm.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(width: BooklySpace.sm),
          _Lozenge(color: colors.accent),
        ],
      ),
    );
  }
}

/// The 45°-rotated square the reference sets on either side of a stamp.
class _Lozenge extends StatelessWidget {
  const _Lozenge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: ColoredBox(
        color: color,
        child: const SizedBox(width: 6, height: 6),
      ),
    );
  }
}

/// Emblem, wordmark, ornament rule, tagline and the salon notice.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.colors, required this.pulse});

  final BooklyColors colors;
  final Animation<double> pulse;

  static const _tagline = 'PRIVATE READING CIRCLES & LITERARY DIALOGUE';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BooklyMark(size: 96),
        const SizedBox(height: BooklySpace.lg),
        Text(
          'Bookly',
          style: BooklyType.displayMobile.copyWith(color: colors.text),
        ),
        const SizedBox(height: BooklySpace.md),
        _Ornament(colors: colors),
        const SizedBox(height: BooklySpace.md),

        /// 0.22em, the reference's wider tagline kerning — wider than the
        /// `label-md` token's own 0.08em, because this line is doing
        /// spine-stamping work rather than labelling something.
        Text(
          _tagline,
          textAlign: TextAlign.center,
          style: BooklyType.labelMd.copyWith(
            color: colors.textSecondary,
            letterSpacing: BooklyType.labelMd.fontSize! * 0.22,
          ),
        ),
        const SizedBox(height: BooklySpace.lg),
        _SalonNotice(colors: colors, pulse: pulse),
      ],
    );
  }
}

/// Hairline — amber lozenge — hairline.
class _Ornament extends StatelessWidget {
  const _Ornament({required this.colors});

  final BooklyColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(child: ColoredBox(color: colors.borderStrong, child: const SizedBox(height: 2))),
        const SizedBox(width: BooklySpace.md),
        _Lozenge(color: colors.accent),
        const SizedBox(width: BooklySpace.md),
        Expanded(child: ColoredBox(color: colors.borderStrong, child: const SizedBox(height: 2))),
      ],
    );
  }
}

/// "Vol. IX · Winter Salon Assembling" with a pulsing amber dot.
class _SalonNotice extends StatelessWidget {
  const _SalonNotice({required this.colors, required this.pulse});

  final BooklyColors colors;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BooklySpace.md,
        vertical: BooklySpace.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSunken.withValues(alpha: 0.7),
        borderRadius: BooklyRadius.rFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Driven by [_SplashScreenState]'s controller rather than an
          /// infinite `flutter_animate` chain, so a single owner disposes it
          /// and reduce-motion can stop it outright.
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) =>
                Opacity(opacity: 0.35 + 0.65 * pulse.value, child: child),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: BooklySpace.sm),
          Text(
            'Vol. IX · Winter Salon Assembling',
            style: BooklyType.bodySm.copyWith(
              color: colors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Epigraph, gilt thread and edition colophon.
class _Colophon extends StatelessWidget {
  const _Colophon({
    required this.colors,
    required this.motion,
    required this.width,
    required this.caption,
    required this.animateThread,
  });

  final BooklyColors colors;
  final Duration motion;
  final double width;
  final String caption;
  final bool animateThread;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '“Between pages and good company, hours turn into timeless keepsakes.”',
          textAlign: TextAlign.center,
          style: BooklyType.headlineSm.copyWith(
            color: colors.textSecondary,
            fontStyle: FontStyle.italic,
            height: 1.45,
          ),
        ),
        const SizedBox(height: BooklySpace.sm),
        Text(
          '— THE BOOKLY FOLIO',
          style: BooklyType.labelSm.copyWith(
            color: colors.textSecondary,
            letterSpacing: BooklyType.labelSm.fontSize! * 0.16,
          ),
        ),
        const SizedBox(height: BooklySpace.lg),
        SizedBox(
          width: 256,
          child: Column(
            children: [
              Container(
                height: 4,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: animateThread ? motion : Duration.zero,
                    curve: BooklyMotion.standard,
                    widthFactor: width,
                    heightFactor: 1,
                    child: ColoredBox(color: colors.accent),
                  ),
                ),
              ),
              const SizedBox(height: BooklySpace.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$caption.',
                    style: BooklyType.labelSm.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    'CH. I',
                    style: BooklyType.labelSm.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: BooklySpace.md),
        Text(
          'BOOKLY EDITION · EST. 2025',
          textAlign: TextAlign.center,
          style: BooklyType.labelSm.copyWith(
            color: colors.textTertiary,
            letterSpacing: BooklyType.labelSm.fontSize! * 0.14,
          ),
        ),
      ],
    );
  }
}
