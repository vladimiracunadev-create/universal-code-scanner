import 'package:sembast/sembast.dart';
import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/recovery/recovery_issue.dart';
import 'package:universal_code_scanner/core/recovery/recovery_repository.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';
import 'package:universal_code_scanner/models/inventory_session.dart';

class InventoryRepository {
  InventoryRepository(this._database, this._cipher, {RecoveryRepository? recovery})
      : _recovery = recovery ?? RecoveryRepository(_database);

  final AppDatabase _database;
  final PayloadCipher _cipher;
  final RecoveryRepository _recovery;
  final StoreRef<String, Map<String, Object?>> _store = stringMapStoreFactory.store('inventory_sessions');

  Future<List<InventorySession>> load() async {
    final List<RecordSnapshot<String, Map<String, Object?>>> snapshots = await _store.find(
      _database.database,
      finder: Finder(sortOrders: <SortOrder>[SortOrder('createdAt', false)]),
    );
    final List<InventorySession> sessions = <InventorySession>[];
    for (final RecordSnapshot<String, Map<String, Object?>> snapshot in snapshots) {
      final String? encrypted = snapshot.value['payload'] as String?;
      if (encrypted == null) {
        await _recovery.record(entityType: RecoveryEntityType.inventory, entityId: snapshot.key, code: 'missing_payload');
        continue;
      }
      try {
        sessions.add(InventorySession.fromJson(await _cipher.decryptJson(encrypted)));
        final CipherEnvelopeInfo info = _cipher.inspect(encrypted);
        if (info.legacy || info.version < PayloadCipher.currentVersion) {
          await _store.record(snapshot.key).update(_database.database, <String, Object?>{
            'payload': await _cipher.upgradeEnvelope(encrypted),
          });
        }
      } on Object catch (error) {
        await _recovery.record(
          entityType: RecoveryEntityType.inventory,
          entityId: snapshot.key,
          code: 'decrypt_${error.runtimeType}',
          encryptedPayload: encrypted,
        );
      }
    }
    return sessions;
  }

  Future<void> save(InventorySession session) async {
    await _store.record(session.id).put(_database.database, <String, Object?>{
      'id': session.id,
      'createdAt': session.createdAt.toIso8601String(),
      'payload': await _cipher.encryptJson(session.toJson()),
    });
  }

  Future<void> remove(String id) => _store.record(id).delete(_database.database);
}
