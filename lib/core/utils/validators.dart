/// Form validation for text the reader types (PLAN.md §1.3).
///
/// Messages are presentable copy rather than diagnostics: each one is
/// rendered beneath the field it belongs to (§3.2), so each names what is
/// needed and never what the regex failed on.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Deliberately permissive. The only authoritative answer to "is this a
  /// real address" is whether Supabase recognises it, and a stricter
  /// pattern here would reject addresses that are valid while never
  /// catching one that is merely well-formed and wrong.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(v)) return "That doesn't look like an email address.";
    return null;
  }

  /// Bookly's password floor.
  ///
  /// **8 characters.** PLAN.md specifies "weak password → danger, inline
  /// under field" but never states the number, so this is where the policy
  /// lives — one constant, chosen rather than inherited from GoTrue's
  /// default of 6, and the repository's `weakPassword` copy states the
  /// same figure so the two can never disagree.
  static const int passwordMinLength = 8;

  /// Display name bounds — `char_length(name) between 1 and 60` in
  /// `public.profiles` (`20261005000002`).
  ///
  /// Enforced on screen rather than only in the database so a name the
  /// row would reject is never first heard about as a server failure
  /// after the reader has committed to it.
  static const int nameMaxLength = 60;

  /// Bio bound — `char_length(bio) <= 160`, same migration (§3.3).
  static const int bioMaxLength = 160;

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password.';
    if (v.length < passwordMinLength) {
      return 'Use at least $passwordMinLength characters.';
    }
    return null;
  }

  static String? notEmpty(String? value, {required String message}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// The bound `books.title`, `chapters.title` and `book_links.title`
  /// all share — every one of them is `char_length between 1 and 300`.
  ///
  /// One constant because it is one rule wearing three column names;
  /// three constants would drift the first time one of them is widened.
  static const titleMaxLength = 300;

  /// A title for one of those three rows. [message] is asked for because
  /// "enter a title" is wrong for a chapter and "enter a chapter title"
  /// is wrong for a book, and the length half needs no wording of its
  /// own — it is the same sentence whichever field it lands under.
  static String? title(String? value, {required String message}) {
    final v = value ?? '';
    if (v.trim().isEmpty) return message;
    if (v.length > titleMaxLength) {
      return 'Keep it to $titleMaxLength characters or fewer.';
    }
    return null;
  }

  /// An external link (PLAN.md §5.2).
  ///
  /// Mirrors the column's own check — `url ~* '^https?://'` — closely
  /// enough that a value this accepts is a value Postgres will take,
  /// while staying a *shape* check: only the reader knows whether the
  /// address leads somewhere, and refusing a well-formed URL because
  /// Bookly could not reach it would reject a link that works fine for
  /// everyone on a better connection.
  static String? url(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter a link.';

    final uri = Uri.tryParse(v);
    final scheme = uri?.scheme.toLowerCase();
    final usable = uri != null &&
        (scheme == 'http' || scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!usable) return "That doesn't look like a web address.";
    return null;
  }
}
