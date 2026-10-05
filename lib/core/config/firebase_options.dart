import 'package:firebase_core/firebase_core.dart';

import '../../app/flavor/flavor.dart';

/// Android [FirebaseOptions] for each build flavor.
///
/// ## Why there are two of them
///
/// The flavors are two different application ids — `com.pragma.bookly.app`
/// (prod) and `com.pragma.bookly.app.dev` (dev) — so Firebase holds two
/// separate Android apps behind one project. Each has its own `appId` so a
/// device token and the notifications it receives are attributable to an
/// environment; sharing one `appId` would make a dev install
/// indistinguishable from a prod one in the Firebase console.
///
/// Both entries share `apiKey`, `messagingSenderId`, `projectId` and
/// `storageBucket` because they belong to the same Firebase project; only
/// `appId` differs.
///
/// ## Regenerating
///
/// The FlutterFire CLI writes one `android` entry per run, so refreshing
/// this file takes two passes into temporary outputs and a merge —
/// `flutterfire configure` overwrites, it does not merge:
///
/// ```sh
/// flutterfire configure -y -p bookly-57cbb --platforms=android \
///   -a com.pragma.bookly.app     --out lib/core/config/firebase_options.dart
/// flutterfire configure -y -p bookly-57cbb --platforms=android \
///   -a com.pragma.bookly.app.dev --out lib/core/config/firebase_options.dev.dart
/// ```
///
/// Copy the `android` block of the second run over [devAndroid] and delete
/// the temporary file.
///
/// ## Not yet configured
///
/// iOS has no registered app, so only [devAndroid] and [prodAndroid] exist.
/// [BooklyFirebaseOptions.forFlavor] is Android-only by construction and
/// `_initFirebase` refuses to start on any other platform rather than hand
/// an Android `appId` to the iOS SDK (PLAN.md §4).
abstract final class BooklyFirebaseOptions {
  /// The options for [flavor]'s Android app.
  static FirebaseOptions forFlavor(Flavor flavor) => switch (flavor) {
        Flavor.dev => devAndroid,
        Flavor.prod => prodAndroid,
      };

  /// Backing app: `com.pragma.bookly.app.dev`.
  static const FirebaseOptions devAndroid = FirebaseOptions(
    apiKey: 'AIzaSyCOIR0-J_U7CYjsl5BxwH7oqf9GE2-Etic',
    appId: '1:867041617765:android:799eba83e65779c83d638c',
    messagingSenderId: '867041617765',
    projectId: 'bookly-57cbb',
    storageBucket: 'bookly-57cbb.firebasestorage.app',
  );

  /// Backing app: `com.pragma.bookly.app`.
  static const FirebaseOptions prodAndroid = FirebaseOptions(
    apiKey: 'AIzaSyCOIR0-J_U7CYjsl5BxwH7oqf9GE2-Etic',
    appId: '1:867041617765:android:e9a721d59274d30f3d638c',
    messagingSenderId: '867041617765',
    projectId: 'bookly-57cbb',
    storageBucket: 'bookly-57cbb.firebasestorage.app',
  );
}
