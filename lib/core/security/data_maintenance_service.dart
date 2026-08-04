import 'package:sembast/sembast.dart';
import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/security/encryption_metadata_repository.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';

class EncryptionRotationResult {
  const EncryptionRotationResult({required this.keyId, required this.historyRecords, required this.inventorySessions});
  final String keyId;
  final int historyRecords;
  final int inventorySessions;
}

class DataMaintenanceService {
  DataMaintenanceService(this._database, this._cipher, this._metadata);

  final AppDatabase _database;
  final PayloadCipher _cipher;
  final EncryptionMetadataRepository _metadata;
  final StoreRef<String, Map<String, Object?>> _history = stringMapStoreFactory.store('scan_history');
  final StoreRef<String, Map<String, Object?>> _inventory = stringMapStoreFactory.store('inventory_sessions');
  bool _rotationInProgress = false;

  Future<EncryptionRotationResult> rotateEncryptionKey() async {
    if (_rotationInProgress) throw StateError('encryption_rotation_in_progress');
    _rotationInProgress = true;
    final String keyId = 'v3_${DateTime.now().toUtc().millisecondsSinceEpoch}';
    try {
      final List<RecordSnapshot<String, Map<String, Object?>>> history = await _history.find(_database.database);
      final List<RecordSnapshot<String, Map<String, Object?>>> inventory = await _inventory.find(_database.database);
      final Map<String, String> historyPayloads = <String, String>{};
      final Map<String, String> inventoryPayloads = <String, String>{};

      for (final RecordSnapshot<String, Map<String, Object?>> item in history) {
        final String? payload = item.value['payload'] as String?;
        if (payload == null) throw StateError('history_payload_missing:${item.key}');
        historyPayloads[item.key] = await _cipher.encryptJson(await _cipher.decryptJson(payload), keyId: keyId);
      }
      for (final RecordSnapshot<String, Map<String, Object?>> item in inventory) {
        final String? payload = item.value['payload'] as String?;
        if (payload == null) throw StateError('inventory_payload_missing:${item.key}');
        inventoryPayloads[item.key] = await _cipher.encryptJson(await _cipher.decryptJson(payload), keyId: keyId);
      }

      await _database.database.transaction((Transaction transaction) async {
        for (final MapEntry<String, String> entry in historyPayloads.entries) {
          await _history.record(entry.key).update(transaction, <String, Object?>{'payload': entry.value});
        }
        for (final MapEntry<String, String> entry in inventoryPayloads.entries) {
          await _inventory.record(entry.key).update(transaction, <String, Object?>{'payload': entry.value});
        }
        await _metadata.saveActiveKeyId(keyId, transaction: transaction);
      });
      _cipher.activateKey(keyId);
      return EncryptionRotationResult(
        keyId: keyId,
        historyRecords: historyPayloads.length,
        inventorySessions: inventoryPayloads.length,
      );
    } on Object {
      // A failed precomputation or rolled-back transaction must not leave an
      // orphan key that could later be mistaken for an active key.
      try {
        await _cipher.forgetKey(keyId);
      } on Object {
        // Preserve the original rotation error; the unused key is not active.
      }
      rethrow;
    } finally {
      _rotationInProgress = false;
    }
  }
}
