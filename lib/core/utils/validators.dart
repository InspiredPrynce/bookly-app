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
}
