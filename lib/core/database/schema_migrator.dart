import 'package:sembast/sembast.dart';

class SchemaMigrationResult {
  const SchemaMigrationResult({required this.fromVersion, required this.toVersion, required this.applied});
  final int fromVersion;
  final int toVersion;
  final List<int> applied;
}

/// Advances the application's own logical schema, kept in `_schema_meta`.
///
/// Unrelated to the `version` Sembast receives when the file is opened. None of
/// the steps creates a store or transforms a record — Sembast creates stores
/// lazily on first use — so what they really record is «this installation has
/// reached that point». They run inside one transaction and are idempotent, so
/// calling `migrate` twice applies nothing the second time.
class SchemaMigrator {
  SchemaMigrator(this.database);
  static const int currentVersion = 4;
  final Database database;
  final StoreRef<String, Object?> _meta = StoreRef<String, Object?>('_schema_meta');

  Future<SchemaMigrationResult> migrate() async {
    final int initial = await _meta.record('schemaVersion').get(database) as int? ?? 1;
    int version = initial;
    final List<int> applied = <int>[];
    await database.transaction((Transaction transaction) async {
      if (version < 2) {
        await _meta.record('v2MigratedAt').put(transaction, DateTime.now().toUtc().toIso8601String());
        version = 2;
        applied.add(2);
      }
      if (version < 3) {
        // Stores are created lazily by Sembast. Version 3 reserves recovery and migration metadata.
        await _meta.record('recoveryStoreEnabled').put(transaction, true);
        await _meta.record('cipherEnvelopeVersion').put(transaction, 2);
        version = 3;
        applied.add(3);
      }
      if (version < 4) {
        await _meta.record('encryptionMetadataInDatabase').put(transaction, true);
        version = 4;
        applied.add(4);
      }
      await _meta.record('schemaVersion').put(transaction, version);
    });
    return SchemaMigrationResult(fromVersion: initial, toVersion: version, applied: applied);
  }
}
