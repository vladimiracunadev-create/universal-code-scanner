import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:universal_code_scanner/models/inventory_session.dart';
import 'package:universal_code_scanner/models/scan_record.dart';

enum ImportStrategy { merge, skipDuplicates, replace }

class HistoryImportPreview {
  const HistoryImportPreview({
    required this.records,
    required this.schemaVersion,
    required this.legacy,
    required this.duplicates,
    required this.rejected,
    required this.fileName,
  });

  final List<ScanRecord> records;
  final int schemaVersion;
  final bool legacy;
  final int duplicates;
  final int rejected;
  final String fileName;

  int get valid => records.length;

  List<ScanRecord> apply(Set<String> existingIds, ImportStrategy strategy) {
    if (strategy == ImportStrategy.skipDuplicates) {
      return records.where((ScanRecord item) => !existingIds.contains(item.id)).toList(growable: false);
    }
    return records;
  }
}

class InventoryImportPreview {
  const InventoryImportPreview({required this.session, required this.schemaVersion, required this.legacy, required this.fileName});
  final InventorySession session;
  final int schemaVersion;
  final bool legacy;
  final String fileName;
}

abstract final class ImportService {
  static const int currentSchemaVersion = 2;
  static const int maxHistoryRecords = 5000;
  static const int maxImportBytes = 25 * 1024 * 1024;
  static const int maxJsonDepth = 32;
  static const int maxJsonNodes = 100000;
  static const int maxInventoryItems = 10000;

  static Future<HistoryImportPreview?> pickHistoryJson({required Set<String> existingIds}) async {
    final _PickedJson? picked = await _pickJson();
    if (picked == null) return null;
    return parseHistoryBytes(picked.bytes, existingIds: existingIds, fileName: picked.fileName);
  }

  static HistoryImportPreview parseHistoryBytes(
    List<int> bytes, {
    required Set<String> existingIds,
    String fileName = 'respaldo.json',
  }) {
    if (bytes.length > maxImportBytes) throw const FormatException('El archivo supera el límite de 25 MB.');
    final dynamic decoded = jsonDecode(utf8.decode(bytes));
    _validateJsonShape(decoded);
    final bool legacy = decoded is List;
    final int schemaVersion;
    final List<dynamic> source;
    if (legacy) {
      schemaVersion = 1;
      source = decoded;
    } else if (decoded is Map) {
      final Map<String, dynamic> envelope = Map<String, dynamic>.from(decoded);
      if (envelope['application'] != 'Universal Code Scanner' || envelope['type'] != 'history') {
        throw const FormatException('El respaldo no pertenece al historial de Universal Code Scanner.');
      }
      schemaVersion = envelope['schemaVersion'] as int? ?? 1;
      if (schemaVersion > currentSchemaVersion) throw const FormatException('El respaldo fue creado por una versión más reciente.');
      final dynamic values = envelope['records'];
      if (values is! List) throw const FormatException('El respaldo no contiene registros.');
      source = values;
    } else {
      throw const FormatException('El archivo no contiene un respaldo compatible.');
    }
    if (source.length > maxHistoryRecords) throw const FormatException('El respaldo supera el límite de registros.');

    final Map<String, ScanRecord> unique = <String, ScanRecord>{};
    int rejected = 0;
    int duplicates = 0;
    for (final dynamic value in source) {
      try {
        if (value is! Map) throw const FormatException('record_not_map');
        final ScanRecord record = ScanRecord.fromJson(Map<String, dynamic>.from(value));
        if (existingIds.contains(record.id) || unique.containsKey(record.id)) duplicates++;
        unique[record.id] = record;
      } on Object {
        rejected++;
      }
    }
    final List<ScanRecord> records = unique.values.toList(growable: false);
    return HistoryImportPreview(
      records: records,
      schemaVersion: schemaVersion,
      legacy: legacy,
      duplicates: duplicates,
      rejected: rejected,
      fileName: fileName,
    );
  }

  static Future<InventoryImportPreview?> pickInventoryJson() async {
    final _PickedJson? picked = await _pickJson();
    if (picked == null) return null;
    return parseInventoryBytes(picked.bytes, fileName: picked.fileName);
  }

  static InventoryImportPreview parseInventoryBytes(List<int> bytes, {String fileName = 'inventario.json'}) {
    if (bytes.length > maxImportBytes) throw const FormatException('El archivo supera el límite de 25 MB.');
    final dynamic decoded = jsonDecode(utf8.decode(bytes));
    _validateJsonShape(decoded);
    if (decoded is! Map) throw const FormatException('El archivo no contiene una sesión de inventario.');
    final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
    final bool legacy = !map.containsKey('application');
    if (legacy) {
      return InventoryImportPreview(
        session: _validatedInventorySession(map),
        schemaVersion: 1,
        legacy: true,
        fileName: fileName,
      );
    }
    if (map['application'] != 'Universal Code Scanner' || map['type'] != 'inventory') {
      throw const FormatException('El respaldo no pertenece al inventario de Universal Code Scanner.');
    }
    final int version = map['schemaVersion'] as int? ?? 1;
    if (version > currentSchemaVersion) throw const FormatException('El respaldo fue creado por una versión más reciente.');
    final dynamic session = map['session'];
    if (session is! Map) throw const FormatException('El respaldo no contiene una sesión.');
    return InventoryImportPreview(
      session: _validatedInventorySession(Map<String, dynamic>.from(session)),
      schemaVersion: version,
      legacy: false,
      fileName: fileName,
    );
  }

  static InventorySession _validatedInventorySession(Map<String, dynamic> value) {
    final InventorySession session = InventorySession.fromJson(value);
    if (session.items.length > maxInventoryItems) {
      throw const FormatException('La sesión supera el límite de productos.');
    }
    return session;
  }

  static void _validateJsonShape(dynamic root) {
    final List<(dynamic value, int depth)> pending = <(dynamic, int)>[(root, 0)];
    int nodes = 0;
    while (pending.isNotEmpty) {
      final (dynamic value, int depth) = pending.removeLast();
      nodes++;
      if (nodes > maxJsonNodes) throw const FormatException('El archivo contiene demasiados elementos.');
      if (depth > maxJsonDepth) throw const FormatException('El archivo contiene una estructura demasiado profunda.');
      if (value is Map) {
        for (final dynamic child in value.values) {
          pending.add((child, depth + 1));
        }
      } else if (value is List) {
        for (final dynamic child in value) {
          pending.add((child, depth + 1));
        }
      }
    }
  }

  static Future<_PickedJson?> _pickJson() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
      allowMultiple: false,
      withData: true,
    );
    final PlatformFile? file = result?.files.single;
    final List<int>? bytes = file?.bytes;
    if (bytes == null) return null;
    if (bytes.length > maxImportBytes) throw const FormatException('El archivo supera el límite de 25 MB.');
    return _PickedJson(fileName: file?.name ?? 'respaldo.json', bytes: bytes);
  }
}

class _PickedJson {
  const _PickedJson({required this.fileName, required this.bytes});
  final String fileName;
  final List<int> bytes;
}
