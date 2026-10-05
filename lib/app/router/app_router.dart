import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/bookly_design_system.dart';
import '../../core/snackbar/bookly_overlay.dart';
import '../../core/widgets/placeholder_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import 'routes.dart';

/// The application router.
///
/// Held in a [Provider] so it is built exactly once per app run. A router
/// created inside a widget's `build` would be rebuilt (and its navigation
/// stack reset) every time that widget re-renders.
final appRouterProvider = Provider<GoRouter>((ref) => buildAppRouter());

/// Builds the router.
///
/// **The table is complete from day one** (PLAN.md §1.5), even though most
/// destinations are still [PlaceholderScreen]s. Deep links are a shape, not
/// a screen: a tapped FCM notification must resolve to a path whether or not
/// the surface behind it exists, and deferring the table until the features
/// arrive would mean the notification path and the in-app path disagree in
/// the meantime. Each placeholder is replaced as its feature lands — the
/// route never changes.
///
/// Every route goes through [_booklyPage] rather than the default
/// `builder:`, because `MaterialPage` fixes its transition at 300ms while
/// PLAN.md §4.7 specifies `dur-slow`.
///
/// Splash-first: `initialLocation` is `/splash`, and the splash screen
/// resolves the session itself before handing off to `/login` or `/catalog`
/// (PLAN.md §4.8). There is deliberately no `redirect` callback doing that
/// job — it belongs to the screen that is already waiting for the answer.
GoRouter buildAppRouter() => GoRouter(
      initialLocation: Routes.splash,
      navigatorKey: BooklyOverlay.navigatorKey,
      routes: [
        // ── Public ────────────────────────────────────────────────────────
        GoRoute(
          path: Routes.splash,
          name: 'splash',
          pageBuilder: (context, state) =>
              _booklyPage(context, state, const SplashScreen()),
        ),
        GoRoute(
          path: Routes.login,
          name: 'login',
          pageBuilder: (context, state) =>
              _booklyPage(context, state, const LoginScreen()),
        ),
        GoRoute(
          path: Routes.register,
          name: 'register',
          pageBuilder: (context, state) =>
              _booklyPage(context, state, const RegisterScreen()),
        ),
        GoRoute(
          path: Routes.forgotPassword,
          name: 'forgot-password',
          pageBuilder: (context, state) =>
              _booklyPage(context, state, const ForgotPasswordScreen()),
        ),

        // ── Signed in ─────────────────────────────────────────────────────
        GoRoute(
          path: Routes.catalog,
          name: 'catalog',
          pageBuilder: (context, state) => _booklyPage(
            context,
            state,
            const PlaceholderScreen(title: 'Catalog', phase: 'Phase 1'),
          ),
        ),
        GoRoute(
          path: Routes.bookPath,
          name: 'book',
          pageBuilder: (context, state) => _booklyPage(
            context,
            state,
            PlaceholderScreen(
              title: 'Book · ${state.pathParameters[Routes.bookIdParam] ?? ''}',
              phase: 'Phase 1',
            ),
          ),
        ),
        GoRoute(
          path: Routes.readPath,
          name: 'read',
          pageBuilder: (context, state) => _booklyPage(
            context,
            state,
            PlaceholderScreen(
              title: 'Read · ${state.pathParameters[Routes.bookIdParam] ?? ''}',
              phase: 'Phase 1',
            ),
          ),
        ),
        GoRoute(
          path: Routes.editBookPath,
          name: 'edit-book',
          pageBuilder: (context, state) => _booklyPage(
            context,
            state,
            PlaceholderScreen(
              title:
                  'Edit · ${state.pathParameters[Routes.bookIdParam] ?? ''}',
              phase: 'Phase 1',
            ),
          ),
        ),
        GoRoute(
          path: Routes.chapterPath,
          name: 'chapter',
          pageBuilder: (context, state) => _booklyPage(
            context,
            state,
            PlaceholderScreen(
              title: 'Chapter · '
                  '${state.pathParameters[Routes.chapterIdParam] ?? ''}',
              phase: 'Phase 1',
            ),
          ),
        ),
        GoRoute(
          path: Routes.circlePath,
          name: 'circle',
          pageBuilder: (context, state) => _booklyPage(
            context,
            state,
            PlaceholderScreen(
              title:
                  'Circle · ${state.pathParameters[Routes.circleIdParam] ?? ''}',
              phase: 'Phase 2',
            ),
          ),
        ),
        GoRoute(
          path: Routes.suggestions,
          name: 'suggestions',
          pageBuilder: (context, state) => _booklyPage(
            context,
            state,
            const PlaceholderScreen(title: 'Suggestions', phase: 'Phase 2'),
          ),
        ),
        GoRoute(
          path: Routes.notifications,
          name: 'notifications',
          pageBuilder: (context, state) => _booklyPage(
            context,
            state,
            const PlaceholderScreen(
              title: 'Notifications',
              phase: 'Phase 3',
            ),
          ),
        ),
        GoRoute(
          path: Routes.settings,
          name: 'settings',
          pageBuilder: (context, state) => _booklyPage(
            context,
            state,
            const PlaceholderScreen(title: 'Settings', phase: 'Phase 3'),
          ),
        ),
        GoRoute(
          path: Routes.settingsProfile,
          name: 'settings-profile',
          pageBuilder: (context, state) =>
              _booklyPage(context, state, const EditProfileScreen()),
        ),
      ],
    );

/// The one page shape every Bookly route uses.
///
/// [CustomTransitionPage] rather than `MaterialPage` because the duration
/// belongs to the page: `MaterialPageRoute.transitionDuration` is a hard
/// 300ms and cannot be set from anywhere. Here it is [BooklyMotion.slow] —
/// 320ms, PLAN.md §4.7 — collapsed to zero when the reader has asked the
/// system for reduced motion, which is also why the duration is read in
/// `pageBuilder` rather than declared as a constant: it depends on
/// `MediaQuery`, and a constant could not see it.
///
/// The key is `state.pageKey` so the Navigator identifies this route by its
/// match rather than by position, which is what lets a deep link replace
/// the stack without the screens re-instantiating.
Page<void> _booklyPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final duration = BooklyMotion.of(context, BooklyMotion.slow);

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SharedAxisXTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    ),
  );
}
