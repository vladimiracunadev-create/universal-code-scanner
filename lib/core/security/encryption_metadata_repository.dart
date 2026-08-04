import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';

class EncryptionMetadataRepository {
  EncryptionMetadataRepository(this._database);

  static const String _activeKeyId = 'encryption_active_key_id';
  final AppDatabase _database;
  final StoreRef<String, Object?> _store = StoreRef<String, Object?>('_security_meta');
  final SharedPreferencesAsync _legacyPreferences = SharedPreferencesAsync();

  Future<String> loadActiveKeyId() async {
    final String? stored = await _store.record(_activeKeyId).get(_database.database) as String?;
    if (stored != null && stored.trim().isNotEmpty) return stored;

    // Compatible migration from the version that stored this metadata in preferences.
    final String? legacy = await _legacyPreferences.getString(_activeKeyId);
    final String resolved = legacy == null || legacy.trim().isEmpty ? PayloadCipher.currentKeyId : legacy;
    await _store.record(_activeKeyId).put(_database.database, resolved);
    if (legacy != null) await _legacyPreferences.remove(_activeKeyId);
    return resolved;
  }

  Future<void> saveActiveKeyId(String keyId, {Transaction? transaction}) {
    if (transaction != null) return _store.record(_activeKeyId).put(transaction, keyId);
    return _store.record(_activeKeyId).put(_database.database, keyId);
  }
}
