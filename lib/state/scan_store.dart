import 'package:flutter/foundation.dart';
import 'package:universal_code_scanner/models/scan_record.dart';
import 'package:universal_code_scanner/services/history_repository.dart';
import 'package:universal_code_scanner/services/import_service.dart';

class ScanStore extends ChangeNotifier {
  ScanStore(this._repository);

  final HistoryRepository _repository;
  List<ScanRecord> _history = <ScanRecord>[];
  bool _loading = false;
  HistoryMigrationStatus? _migrationStatus;

  List<ScanRecord> get history => List<ScanRecord>.unmodifiable(_history);
  Set<String> get ids => _history.map((ScanRecord item) => item.id).toSet();
  bool get loading => _loading;
  HistoryMigrationStatus? get migrationStatus => _migrationStatus;

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    try {
      _migrationStatus = await _repository.initialize();
      _history = await _repository.load();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<HistoryMigrationStatus> retryMigration() async {
    _loading = true;
    notifyListeners();
    try {
      final HistoryMigrationStatus status = await _repository.initialize();
      _migrationStatus = status;
      _history = await _repository.load();
      return status;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int> importPreview(HistoryImportPreview preview, ImportStrategy strategy) async {
    final List<ScanRecord> selected = preview.apply(ids, strategy);
    if (strategy == ImportStrategy.replace) {
      await _repository.replaceAll(selected);
      _history = List<ScanRecord>.of(selected)..sort((ScanRecord a, ScanRecord b) => b.scannedAt.compareTo(a.scannedAt));
      notifyListeners();
    } else {
      await addAll(selected);
    }
    return selected.length;
  }

  Future<void> addAll(List<ScanRecord> records) async {
    if (records.isEmpty) return;
    await _repository.upsertAll(records);
    final Map<String, ScanRecord> unique = <String, ScanRecord>{
      for (final ScanRecord item in _history) item.id: item,
      for (final ScanRecord item in records) item.id: item,
    };
    _history = unique.values.toList(growable: false)
      ..sort((ScanRecord a, ScanRecord b) => b.scannedAt.compareTo(a.scannedAt));
    notifyListeners();
  }

  Future<void> update(ScanRecord record) async {
    final int index = _history.indexWhere((ScanRecord item) => item.id == record.id);
    if (index < 0) return;
    await _repository.upsert(record);
    _history = List<ScanRecord>.of(_history)..[index] = record;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final int index = _history.indexWhere((ScanRecord item) => item.id == id);
    if (index < 0) return;
    final ScanRecord current = _history[index];
    await update(current.copyWith(favorite: !current.favorite));
  }

  Future<void> pruneOlderThan(int days) async {
    if (days <= 0) return;
    final DateTime cutoff = DateTime.now().subtract(Duration(days: days));
    await _repository.pruneOlderThan(days);
    _history = _history.where((ScanRecord item) => !item.scannedAt.isBefore(cutoff)).toList(growable: false);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _repository.remove(id);
    _history = _history.where((ScanRecord item) => item.id != id).toList();
    notifyListeners();
  }

  Future<void> clear() async {
    await _repository.clear();
    _history = <ScanRecord>[];
    notifyListeners();
  }
}
