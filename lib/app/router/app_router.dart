import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/snackbar/bookly_overlay.dart';
import '../../core/widgets/placeholder_screen.dart';
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
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: Routes.login,
          name: 'login',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Sign in', phase: 'Phase 1'),
        ),
        GoRoute(
          path: Routes.register,
          name: 'register',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Create account', phase: 'Phase 1'),
        ),
        GoRoute(
          path: Routes.forgotPassword,
          name: 'forgot-password',
          builder: (context, state) => const PlaceholderScreen(
            title: 'Reset password',
            phase: 'Phase 1',
          ),
        ),

        // ── Signed in ─────────────────────────────────────────────────────
        GoRoute(
          path: Routes.catalog,
          name: 'catalog',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Catalog', phase: 'Phase 1'),
        ),
        GoRoute(
          path: Routes.bookPath,
          name: 'book',
          builder: (context, state) => PlaceholderScreen(
            title: 'Book · ${state.pathParameters[Routes.bookIdParam] ?? ''}',
            phase: 'Phase 1',
          ),
        ),
        GoRoute(
          path: Routes.readPath,
          name: 'read',
          builder: (context, state) => PlaceholderScreen(
            title:
                'Read · ${state.pathParameters[Routes.bookIdParam] ?? ''}',
            phase: 'Phase 1',
          ),
        ),
        GoRoute(
          path: Routes.editBookPath,
          name: 'edit-book',
          builder: (context, state) => PlaceholderScreen(
            title:
                'Edit · ${state.pathParameters[Routes.bookIdParam] ?? ''}',
            phase: 'Phase 1',
          ),
        ),
        GoRoute(
          path: Routes.chapterPath,
          name: 'chapter',
          builder: (context, state) => PlaceholderScreen(
            title: 'Chapter · '
                '${state.pathParameters[Routes.chapterIdParam] ?? ''}',
            phase: 'Phase 1',
          ),
        ),
        GoRoute(
          path: Routes.circlePath,
          name: 'circle',
          builder: (context, state) => PlaceholderScreen(
            title: 'Circle · ${state.pathParameters[Routes.circleIdParam] ?? ''}',
            phase: 'Phase 2',
          ),
        ),
        GoRoute(
          path: Routes.suggestions,
          name: 'suggestions',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Suggestions', phase: 'Phase 2'),
        ),
        GoRoute(
          path: Routes.notifications,
          name: 'notifications',
          builder: (context, state) => const PlaceholderScreen(
            title: 'Notifications',
            phase: 'Phase 3',
          ),
        ),
        GoRoute(
          path: Routes.settings,
          name: 'settings',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Settings', phase: 'Phase 3'),
        ),
        GoRoute(
          path: Routes.settingsProfile,
          name: 'settings-profile',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Profile', phase: 'Phase 3'),
        ),
      ],
    );
