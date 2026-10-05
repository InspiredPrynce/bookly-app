import 'app/bootstrap.dart';
import 'app/flavor/flavor.dart';

/// Production entrypoint.
///
/// Build with:
/// ```sh
/// flutter build apk --flavor prod -t lib/main_prod.dart \
///   --dart-define-from-file=env/prod.json
/// ```
Future<void> main() => bootstrap(flavor: Flavor.prod);
