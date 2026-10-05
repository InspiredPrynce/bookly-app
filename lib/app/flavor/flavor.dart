/// Build environments Bookly ships under.
///
/// One enum per file — see PLAN.md §0.1.
///
/// - [dev]  → `com.pragma.bookly.app.dev`, reads `env/dev.json`
/// - [prod] → `com.pragma.bookly.app`, reads `env/prod.json`
enum Flavor {
  dev,
  prod;

  /// Resolves a flavor from the `FLAVOR` dart-define.
  ///
  /// Throws [StateError] on an unknown name rather than falling back to a
  /// default: a mistyped flavor silently pointing a dev build at production
  /// config is exactly the failure this should make loud.
  static Flavor fromName(String name) {
    for (final flavor in Flavor.values) {
      if (flavor.name == name) return flavor;
    }
    throw StateError(
      'Unknown FLAVOR "$name". Expected one of: '
      '${Flavor.values.map((f) => f.name).join(', ')}.',
    );
  }
}
