import '../../app/flavor/flavor.dart';

/// Compile-time configuration injected with
/// `--dart-define-from-file=env/<flavor>.json`.
///
/// Every value is read once at build time. Nothing here is a secret: the
/// Supabase publishable (anon) key is designed to ship in the client and is
/// backed by Row Level Security, not by secrecy. The Gemini key is a
/// different matter — it is device-only and never reaches this class
/// (PLAN.md §7.1).
class Env {
  const Env({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.flavor,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final Flavor flavor;

  /// The keys `env/*.json` must supply.
  static const List<String> requiredKeys = <String>[
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'FLAVOR',
  ];

  /// Values handed to the app by `--dart-define-from-file`.
  ///
  /// Exposed so callers can assert the exact key set the build must provide
  /// without having to build first.
  static const Map<String, String> dartDefine = <String, String>{
    'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
    'FLAVOR': String.fromEnvironment('FLAVOR'),
  };

  /// Builds an [Env] from an already-decoded map, validating everything in
  /// one pass so a broken env file is a single fix rather than one run per
  /// missing key.
  factory Env.fromMap(Map<String, String> values) {
    final missing = requiredKeys
        .where((key) => !(values[key] ?? '').trim().isNotEmpty)
        .toList(growable: false);

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing or blank environment values: ${missing.join(', ')}. '
        'Run with --dart-define-from-file=env/<flavor>.json '
        '(copy env/dev.example.json if the file is absent).',
      );
    }

    return Env(
      supabaseUrl: values['SUPABASE_URL']!.trim(),
      supabaseAnonKey: values['SUPABASE_ANON_KEY']!.trim(),
      flavor: Flavor.fromName(values['FLAVOR']!.trim()),
    );
  }

  /// Reads [dartDefine] as supplied by the build.
  factory Env.load() => Env.fromMap(dartDefine);
}
