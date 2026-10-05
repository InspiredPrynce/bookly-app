/// Every location Bookly can navigate to, as one list (PLAN.md §1.5).
///
/// Kept apart from the router's construction so a screen can build a path
/// without importing go_router — `Routes.book(id)` is navigation, while
/// knowing that `/book/:bookId` takes a `GoRoute` is routing.
///
/// `go_router` is here **specifically for deep links**: a tapped FCM
/// notification has to land on the exact surface, not on the app's idea of
/// what that notification was about.
abstract final class Routes {
  // ── Public ──────────────────────────────────────────────────────────────
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // ── Signed-in ───────────────────────────────────────────────────────────
  static const catalog = '/catalog';
  static const notifications = '/notifications';
  static const suggestions = '/suggestions';
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';

  // ── Patterns ────────────────────────────────────────────────────────────
  static const bookPath = '/book/:bookId';
  static const readPath = '/book/:bookId/read';
  static const editBookPath = '/book/:bookId/edit';
  static const chapterPath = '/book/:bookId/chapter/:chapterId';
  static const circlePath = '/circle/:circleId';

  // ── Path parameter names ────────────────────────────────────────────────
  static const bookIdParam = 'bookId';
  static const chapterIdParam = 'chapterId';
  static const circleIdParam = 'circleId';

  // ── Location builders ───────────────────────────────────────────────────
  static String book(String bookId) => '/book/$bookId';
  static String read(String bookId) => '/book/$bookId/read';
  static String editBook(String bookId) => '/book/$bookId/edit';

  static String chapter(String bookId, String chapterId) =>
      '/book/$bookId/chapter/$chapterId';

  static String circle(String circleId) => '/circle/$circleId';
}
