import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/design_system/bookly_design_system.dart';
import 'router/app_router.dart';

/// The root widget: everything above the router.
///
/// Theme comes from the Literary Clothbound system in
/// `core/design_system/`. Routing is supplied by [appRouterProvider] rather
/// than being constructed here, so the router is created exactly once —
/// rebuilding this widget must not recreate it and silently reset navigation
/// state.
class BooklyApp extends ConsumerWidget {
  const BooklyApp({super.key, required this.env});

  final Env env;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Bookly',
      debugShowCheckedModeBanner: false,
      theme: BooklyTheme.light,
      darkTheme: BooklyTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
