import 'app/bootstrap.dart';
import 'app/flavor/flavor.dart';

/// Development entrypoint.
///
/// Run with:
/// ```sh
/// flutter run --flavor dev -t lib/main_dev.dart \
///   --dart-define-from-file=env/dev.json
/// ```
Future<void> main() => bootstrap(flavor: Flavor.dev);
