import 'package:flutter_test/flutter_test.dart';

import 'package:bookly/app/flavor/flavor.dart';
import 'package:bookly/core/config/env.dart';

void main() {
  group('Flavor', () {
    test('parses dev', () {
      expect(Flavor.fromName('dev'), Flavor.dev);
    });

    test('parses prod', () {
      expect(Flavor.fromName('prod'), Flavor.prod);
    });

    test('rejects an unknown name rather than silently defaulting', () {
      expect(
        () => Flavor.fromName('staging'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('staging'), contains('dev'), contains('prod')),
          ),
        ),
      );
    });
  });

  group('Env.fromMap', () {
    const valid = {
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_ANON_KEY': 'sb_publishable_abc',
      'FLAVOR': 'dev',
    };

    test('reads every value from the map', () {
      final env = Env.fromMap(valid);

      expect(env.supabaseUrl, 'https://example.supabase.co');
      expect(env.supabaseAnonKey, 'sb_publishable_abc');
      expect(env.flavor, Flavor.dev);
    });

    test('rejects a blank value, not just a missing key', () {
      final values = {...valid, 'SUPABASE_URL': '   '};

      expect(
        () => Env.fromMap(values),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('SUPABASE_URL'))),
      );
    });

    test('names every missing key at once so the fix is one edit', () {
      expect(
        () => Env.fromMap(const {'FLAVOR': 'prod'}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('SUPABASE_URL'), contains('SUPABASE_ANON_KEY')),
          ),
        ),
      );
    });

    test('rejects a bad flavor value by name', () {
      final values = {...valid, 'FLAVOR': 'staging'};

      expect(
        () => Env.fromMap(values),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('staging'))),
      );
    });

    test('reads the keys actually injected by --dart-define-from-file', () {
      expect(
        Env.dartDefine.keys,
        containsAll(<String>['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'FLAVOR']),
      );
    });
  });
}
