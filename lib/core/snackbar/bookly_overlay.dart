import 'package:flutter/material.dart';

/// The app's navigator, and through it the root [Overlay] a toast is placed on.
///
/// ## Why a global key
///
/// A toast has to be reachable from places that have no `BuildContext` — a
/// repository surfacing a network failure, an Edge Function's callback, a
/// logout that has already torn the widget tree down. Requiring a context
/// would push presentation knowledge out to exactly the layers that must not
/// have it (PLAN.md §1.2).
///
/// The key is owned **here**, in `core/`, and consumed by the router: the
/// router needs a navigator key anyway, and giving it one defined next to
/// the only thing that requires it means there is a single instance rather
/// than two that silently disagree.
///
/// `NavigatorState.overlay` is the [OverlayState] itself, so there is no
/// context to walk and no direction to get wrong. It is non-null for exactly
/// as long as there is a navigator to show a toast in.
abstract final class BooklyOverlay {
  /// Attach to `GoRouter(navigatorKey: ...)` — see `app/router/app_router.dart`.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'BooklyNavigatorKey');

  static OverlayState? get overlay => navigatorKey.currentState?.overlay;
}
