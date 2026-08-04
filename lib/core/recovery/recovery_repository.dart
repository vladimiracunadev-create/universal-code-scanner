import 'package:crypto/crypto.dart';
import 'package:sembast/sembast.dart';
import 'package:universal_code_scanner/core/database/app_database.dart';
import 'package:universal_code_scanner/core/recovery/recovery_issue.dart';

class RecoveryRepository {
  RecoveryRepository(this._database);

  final AppDatabase _database;
  final StoreRef<String, Map<String, Object?>> _store = stringMapStoreFactory.store('recovery_issues');

  Future<RecoveryIssue> record({
    required RecoveryEntityType entityType,
    required String entityId,
    required String code,
    String? encryptedPayload,
  }) async {
    final String source = '${entityType.name}|$entityId|$code';
    final String id = sha256.convert(source.codeUnits).toString().substring(0, 24);
    final RecoveryIssue issue = RecoveryIssue(
      id: id,
      entityType: entityType,
      entityId: entityId,
      detectedAt: DateTime.now().toUtc(),
      code: code,
      state: RecoveryIssueState.unresolved,
      encryptedPayload: encryptedPayload,
    );
    await _store.record(id).put(_database.database, issue.toJson());
    return issue;
  }

  Future<List<RecoveryIssue>> load({bool unresolvedOnly = true}) async {
    final List<RecordSnapshot<String, Map<String, Object?>>> snapshots = await _store.find(
      _database.database,
      finder: Finder(sortOrders: <SortOrder>[SortOrder('detectedAt', false)]),
    );
    return snapshots
        .map((RecordSnapshot<String, Map<String, Object?>> item) => RecoveryIssue.fromJson(item.value))
        .where((RecoveryIssue issue) => !unresolvedOnly || issue.state == RecoveryIssueState.unresolved)
        .toList(growable: false);
  }

  Future<void> mark(String id, RecoveryIssueState state) async {
    final Map<String, Object?>? current = await _store.record(id).get(_database.database);
    if (current == null) return;
    final RecoveryIssue issue = RecoveryIssue.fromJson(current).copyWith(state: state);
    await _store.record(id).put(_database.database, issue.toJson());
  }

  Future<void> clearResolved() async {
    final List<RecordSnapshot<String, Map<String, Object?>>> snapshots = await _store.find(_database.database);
    await _database.database.transaction((Transaction transaction) async {
      for (final RecordSnapshot<String, Map<String, Object?>> item in snapshots) {
        final RecoveryIssue issue = RecoveryIssue.fromJson(item.value);
        if (issue.state != RecoveryIssueState.unresolved) await _store.record(item.key).delete(transaction);
      }
    });
  }
}
