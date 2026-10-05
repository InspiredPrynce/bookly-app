import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-only secrets.
///
/// Everything in here stays on the reader's phone. The Gemini API key is
/// pasted by each user, stored by this class through `flutter_secure_storage`
/// (Keychain / EncryptedSharedPreferences), and is **never** sent to Bookly's
/// backend, never placed in Riverpod state, never logged, and never written
/// to `profiles` (PLAN.md §7.1, §7.5).
///
/// This is a thin, explicit wrapper rather than a `FlutterSecureStorage`
/// handed around directly: it keeps the key *names* in one place, so a caller
/// cannot silently read `'geminiApiKey'` while another writes
/// `'gemini_api_key'`.
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// The user's own Gemini key. Device-only.
  static const String geminiApiKey = 'gemini_api_key';

  /// The chosen Gemini model id. Also device-only.
  static const String geminiModel = 'gemini_model';

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  /// Clears every Bookly secret — logout, and only logout.
  ///
  /// Deleting on logout rather than only on account removal is the
  /// conservative reading: a shared device should not retain one reader's
  /// key after they sign out (PLAN.md §3.1).
  Future<void> clear() => _storage.deleteAll();
}

/// The app's single secure-storage handle.
///
/// PLAN.md §1.3 lists secure storage among bootstrap's concerns; there is no
/// async initialisation step for it — `FlutterSecureStorage` is ready as soon
/// as it is constructed — so the whole of "owning" it is providing one
/// instance rather than letting `const FlutterSecureStorage()` be sprinkled
/// across features with no shared key namespace.
final secureStorageProvider = Provider<SecureStorage>(
  (ref) => SecureStorage(),
);
