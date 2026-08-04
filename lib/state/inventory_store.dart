import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_code_scanner/core/performance/async_write_queue.dart';
import 'package:universal_code_scanner/models/inventory_session.dart';
import 'package:universal_code_scanner/models/scan_record.dart';
import 'package:universal_code_scanner/services/inventory_repository.dart';

class InventoryStore extends ChangeNotifier {
  InventoryStore(this._repository);

  final InventoryRepository _repository;
  final AsyncWriteQueue _writes = AsyncWriteQueue();
  List<InventorySession> _sessions = <InventorySession>[];
  String? _activeId;

  List<InventorySession> get sessions => List<InventorySession>.unmodifiable(_sessions);
  InventorySession? get activeSession {
    for (final InventorySession session in _sessions) {
      if (session.id == _activeId && session.isOpen) return session;
    }
    return null;
  }

  Future<void> initialize() async {
    _sessions = await _repository.load();
    final Iterable<InventorySession> open = _sessions.where((InventorySession item) => item.isOpen);
    _activeId = open.isEmpty ? null : open.first.id;
  }

  Future<void> importSession(InventorySession imported) => _writes.run<void>(() async {
        final DateTime now = DateTime.now();
        final String id = sha1.convert('${now.microsecondsSinceEpoch}|${imported.id}'.codeUnits).toString().substring(0, 16);
        final InventorySession session = InventorySession(
          id: id,
          name: '${imported.name} (importado)',
          createdAt: now,
          closedAt: imported.closedAt == null ? null : now,
          items: imported.items,
        );
        await _repository.save(session);
        _sessions = <InventorySession>[session, ..._sessions];
        if (session.isOpen) _activeId = session.id;
        notifyListeners();
      });

  Future<void> createSession(String name) => _writes.run<void>(() async {
        final DateTime now = DateTime.now();
        final String id = sha1.convert('${now.microsecondsSinceEpoch}|$name'.codeUnits).toString().substring(0, 16);
        final InventorySession session = InventorySession(
          id: id,
          name: name.trim().isEmpty ? 'Inventario ${_formatDate(now)}' : name.trim(),
          createdAt: now,
          items: const <String, InventoryItem>{},
        );
        await _repository.save(session);
        _sessions = <InventorySession>[session, ..._sessions];
        _activeId = id;
        notifyListeners();
      });

  Future<void> activate(String id) async {
    _activeId = id;
    notifyListeners();
  }

  Future<void> reopenSession(String id) => _writes.run<void>(() async {
        final int index = _sessions.indexWhere((InventorySession item) => item.id == id);
        if (index < 0) return;
        final InventorySession current = _sessions[index];
        final InventorySession reopened = InventorySession(
          id: current.id,
          name: current.name,
          createdAt: current.createdAt,
          items: current.items,
        );
        await _replaceUnlocked(reopened);
        _activeId = id;
        notifyListeners();
      });

  Future<void> updateItemNotes(String code, String notes) => _writes.run<void>(() async {
        final InventorySession? session = activeSession;
        if (session == null || session.items[code] == null) return;
        final Map<String, InventoryItem> items = Map<String, InventoryItem>.of(session.items);
        items[code] = items[code]!.copyWith(notes: notes.trim(), lastScannedAt: DateTime.now());
        await _replaceUnlocked(session.copyWith(items: items));
      });

  Future<void> addScan(ScanRecord record) => _writes.run<void>(() async {
        final InventorySession? session = activeSession;
        if (session == null) return;
        final DateTime now = DateTime.now();
        final Map<String, InventoryItem> items = Map<String, InventoryItem>.of(session.items);
        final InventoryItem? existing = items[record.rawValue];
        items[record.rawValue] = existing == null
            ? InventoryItem(
                code: record.rawValue,
                format: record.format,
                label: record.parsed.summary ?? record.contentType,
                quantity: 1,
                firstScannedAt: now,
                lastScannedAt: now,
              )
            : existing.copyWith(quantity: existing.quantity + 1, lastScannedAt: now);
        await _replaceUnlocked(session.copyWith(items: items));
      });

  Future<void> setQuantity(String code, int quantity) => _writes.run<void>(() async {
        final InventorySession? session = activeSession;
        if (session == null) return;
        final Map<String, InventoryItem> items = Map<String, InventoryItem>.of(session.items);
        if (quantity <= 0) {
          items.remove(code);
        } else if (items[code] != null) {
          items[code] = items[code]!.copyWith(quantity: quantity, lastScannedAt: DateTime.now());
        }
        await _replaceUnlocked(session.copyWith(items: items));
      });

  Future<void> closeActive() => _writes.run<void>(() async {
        final InventorySession? session = activeSession;
        if (session == null) return;
        await _replaceUnlocked(session.copyWith(closedAt: DateTime.now()));
        _activeId = null;
        notifyListeners();
      });

  Future<void> deleteSession(String id) => _writes.run<void>(() async {
        await _repository.remove(id);
        _sessions = _sessions.where((InventorySession item) => item.id != id).toList();
        if (_activeId == id) _activeId = null;
        notifyListeners();
      });

  Future<void> _replaceUnlocked(InventorySession session) async {
    final int index = _sessions.indexWhere((InventorySession item) => item.id == session.id);
    if (index < 0) return;
    await _repository.save(session);
    _sessions = List<InventorySession>.of(_sessions)..[index] = session;
    notifyListeners();
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
}
