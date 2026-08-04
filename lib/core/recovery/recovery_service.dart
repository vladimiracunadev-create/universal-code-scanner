import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/recovery/recovery_issue.dart';
import 'package:universal_code_scanner/core/recovery/recovery_repository.dart';
import 'package:universal_code_scanner/core/security/payload_cipher.dart';
import 'package:universal_code_scanner/models/inventory_session.dart';
import 'package:universal_code_scanner/models/scan_record.dart';

class RecoveryService {
  RecoveryService(this._database, this._cipher, this.repository);

  final AppDatabase _database;
  final PayloadCipher _cipher;
  final RecoveryRepository repository;
  final StoreRef<String, Map<String, Object?>> _history = stringMapStoreFactory.store('scan_history');
  final StoreRef<String, Map<String, Object?>> _inventory = stringMapStoreFactory.store('inventory_sessions');

  Future<List<RecoveryIssue>> load({bool unresolvedOnly = false}) => repository.load(unresolvedOnly: unresolvedOnly);

  Future<bool> retry(RecoveryIssue issue) async {
    final String? encrypted = issue.encryptedPayload;
    if (encrypted == null || issue.state != RecoveryIssueState.unresolved) return false;
    try {
      final Map<String, dynamic> clear = await _cipher.decryptJson(encrypted);
      final String upgraded = await _cipher.upgradeEnvelope(encrypted);
      switch (issue.entityType) {
        case RecoveryEntityType.history:
          final ScanRecord record = ScanRecord.fromJson(clear);
          await _history.record(issue.entityId).put(_database.database, <String, Object?>{
            'id': record.id,
            'scannedAt': record.scannedAt.toIso8601String(),
            'payload': upgraded,
          });
          break;
        case RecoveryEntityType.inventory:
          final InventorySession session = InventorySession.fromJson(clear);
          await _inventory.record(issue.entityId).put(_database.database, <String, Object?>{
            'id': session.id,
            'createdAt': session.createdAt.toIso8601String(),
            'payload': upgraded,
          });
          break;
        case RecoveryEntityType.migration:
        case RecoveryEntityType.database:
        case RecoveryEntityType.startup:
          return false;
      }
      await repository.mark(issue.id, RecoveryIssueState.recovered);
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> discard(RecoveryIssue issue) async {
    switch (issue.entityType) {
      case RecoveryEntityType.history:
        await _history.record(issue.entityId).delete(_database.database);
        break;
      case RecoveryEntityType.inventory:
        await _inventory.record(issue.entityId).delete(_database.database);
        break;
      case RecoveryEntityType.migration:
      case RecoveryEntityType.database:
      case RecoveryEntityType.startup:
        break;
    }
    await repository.mark(issue.id, RecoveryIssueState.deleted);
  }

  Future<String> exportBundle() async {
    final List<RecoveryIssue> issues = await repository.load(unresolvedOnly: false);
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'application': 'Universal Code Scanner',
      'type': 'recovery',
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'notice': 'Encrypted payloads remain encrypted. No decryption key is included.',
      'issues': issues.map((RecoveryIssue issue) => issue.toJson()).toList(growable: false),
    });
  }
}
