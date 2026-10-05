import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../core/sound/bookly_sound_player.dart';
import 'app.dart';
import 'flavor/flavor.dart';

/// Boots Bookly — the only place the process touches platform plugins.
///
/// Order matters and each step is deliberately its own function:
///
/// 1. [WidgetsFlutterBinding.ensureInitialized] — must precede any plugin use.
/// 2. [_loadConfig] — reads the `--dart-define-from-file` values and fails
///    fast if they belong to the other flavor.
/// 3. [_initSupabase] — the backend client, keyed by [Env].
/// 4. [_initFirebase] — messaging.
///
/// Then the widget tree goes up behind a [ProviderScope] so every downstream
/// provider can reach what was initialised here.
///
/// One entrypoint per flavor — `main_dev.dart` / `main_prod.dart` — rather
/// than a single `main.dart` that infers the flavor. Inferring means a prod
/// binary started with dev config looks identical to a correct launch until
/// something writes to the wrong backend; passing the flavor in and checking
/// it against [Env.flavor] turns that into a startup error instead.
Future<void> bootstrap({required Flavor flavor}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final env = _loadConfig(flavor);

  await _initSupabase(env);
  await _initFirebase();

  runApp(ProviderScope(child: BooklyApp(env: env)));

  /// Not awaited: decoding the chime must never delay the first frame. A
  /// toast raised while it is still warming queues behind the warm-up and
  /// still sounds — see `BooklySoundPlayer._ready`.
  unawaited(BooklySoundPlayer.preload());
}

/// Reads [Env] and refuses to start if the entrypoint and the env file
/// disagree about which flavor this is.
Env _loadConfig(Flavor flavor) {
  final env = Env.load();
  if (env.flavor != flavor) {
    throw StateError(
      'Entrypoint main_${flavor.name}.dart was started with config for '
      '${env.flavor.name}. Run:\n'
      '  flutter run --flavor ${flavor.name} '
      '-t lib/main_${flavor.name}.dart '
      '--dart-define-from-file=env/${flavor.name}.json',
    );
  }
  return env;
}

/// Supabase is initialised with the publishable key only. That key is
/// designed to ship in the client; row-level security, not secrecy, is what
/// protects the data (PLAN.md §7.1).
Future<void> _initSupabase(Env env) => Supabase.initialize(
      url: env.supabaseUrl,
      publishableKey: env.supabaseAnonKey,
    );

/// Firebase messaging. Requires `google-services.json` per flavor, produced
/// by `flutterfire configure`.
Future<void> _initFirebase() => Firebase.initializeApp();
