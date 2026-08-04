import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_code_scanner/models/inventory_session.dart';
import 'package:universal_code_scanner/models/scan_record.dart';

abstract final class ExportService {
  static Future<void> shareHistoryJson(List<ScanRecord> records) {
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'application': 'Universal Code Scanner',
        'schemaVersion': 2,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'type': 'history',
        'records': records.map((ScanRecord item) => item.toJson()).toList(growable: false),
      })),
    );
    return SharePlus.instance.share(ShareParams(
      title: 'Historial de escaneos',
      files: <XFile>[XFile.fromData(bytes, mimeType: 'application/json')],
      fileNameOverrides: const <String>['historial-escaneos.json'],
    ));
  }

  static Future<void> shareHistoryCsv(List<ScanRecord> records) {
    final List<List<String>> rows = <List<String>>[
      <String>['fecha', 'tipo', 'formato', 'origen', 'riesgo', 'favorito', 'etiquetas', 'contenido'],
      ...records.map((ScanRecord item) => <String>[
            item.scannedAt.toIso8601String(),
            item.contentType,
            item.format,
            item.source,
            item.riskLevel.name,
            '${item.favorite}',
            item.tags.join('|'),
            item.rawValue,
          ]),
    ];
    return _shareCsv(rows, 'historial-escaneos.csv', 'Historial de escaneos');
  }


  static Future<void> shareHistoryXlsx(List<ScanRecord> records) {
    final List<List<String>> rows = <List<String>>[
      <String>['Fecha', 'Tipo', 'Formato', 'Origen', 'Riesgo', 'Favorito', 'Etiquetas', 'Notas', 'Contenido'],
      ...records.map((ScanRecord item) => <String>[
            item.scannedAt.toIso8601String(),
            item.contentType,
            item.format,
            item.source,
            item.riskLevel.name,
            item.favorite ? 'Sí' : 'No',
            item.tags.join(' | '),
            item.notes,
            item.rawValue,
          ]),
    ];
    return _shareXlsx(rows, 'Historial', 'historial-escaneos.xlsx', 'Historial de escaneos');
  }

  static Future<void> shareInventoryCsv(InventorySession session) {
    final List<List<String>> rows = <List<String>>[
      <String>['sesion', 'codigo', 'formato', 'descripcion', 'cantidad', 'primera_lectura', 'ultima_lectura', 'notas'],
      ...session.items.values.map((InventoryItem item) => <String>[
            session.name,
            item.code,
            item.format,
            item.label,
            '${item.quantity}',
            item.firstScannedAt.toIso8601String(),
            item.lastScannedAt.toIso8601String(),
            item.notes,
          ]),
    ];
    return _shareCsv(rows, 'inventario-${session.id}.csv', 'Inventario ${session.name}');
  }


  static Future<void> shareInventoryJson(InventorySession session) {
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'application': 'Universal Code Scanner',
        'schemaVersion': 2,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'type': 'inventory',
        'session': session.toJson(),
      })),
    );
    return SharePlus.instance.share(ShareParams(
      title: 'Inventario ${session.name}',
      files: <XFile>[XFile.fromData(bytes, mimeType: 'application/json')],
      fileNameOverrides: <String>['inventario-${session.id}.json'],
    ));
  }

  static Future<void> shareInventoryXlsx(InventorySession session) {
    final List<List<String>> rows = <List<String>>[
      <String>['Sesión', 'Código', 'Formato', 'Descripción', 'Cantidad', 'Primera lectura', 'Última lectura', 'Notas'],
      ...session.items.values.map((InventoryItem item) => <String>[
            session.name,
            item.code,
            item.format,
            item.label,
            '${item.quantity}',
            item.firstScannedAt.toIso8601String(),
            item.lastScannedAt.toIso8601String(),
            item.notes,
          ]),
    ];
    return _shareXlsx(rows, 'Inventario', 'inventario-${session.id}.xlsx', 'Inventario ${session.name}');
  }

  static Future<void> _shareCsv(List<List<String>> rows, String name, String title) async {
    final Uint8List bytes = Uint8List.fromList(await compute<List<List<String>>, List<int>>(_encodeCsv, rows));
    await SharePlus.instance.share(ShareParams(
      title: title,
      files: <XFile>[XFile.fromData(bytes, mimeType: 'text/csv')],
      fileNameOverrides: <String>[name],
    ));
  }


  static Future<void> _shareXlsx(List<List<String>> rows, String sheetName, String name, String title) async {
    final List<int>? encoded = await compute<Map<String, Object?>, List<int>?>(_encodeXlsx, <String, Object?>{
      'rows': rows,
      'sheetName': sheetName,
    });
    if (encoded == null) return;
    await SharePlus.instance.share(ShareParams(
      title: title,
      files: <XFile>[
        XFile.fromData(
          Uint8List.fromList(encoded),
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      fileNameOverrides: <String>[name],
    ));
  }

}

List<int> _encodeCsv(List<List<String>> rows) {
  String csvCell(String value) => '"${value.replaceAll('"', '""')}"';
  final String csv = rows.map((List<String> row) => row.map(csvCell).join(',')).join('\r\n');
  return <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
}

List<int>? _encodeXlsx(Map<String, Object?> request) {
  final List<List<String>> rows = (request['rows'] as List<dynamic>)
      .map<List<String>>((dynamic row) => (row as List<dynamic>).map((dynamic value) => '$value').toList(growable: false))
      .toList(growable: false);
  final String sheetName = request['sheetName'] as String;
  final Excel workbook = Excel.createExcel();
  final String firstSheet = workbook.getDefaultSheet() ?? 'Sheet1';
  final Sheet sheet = workbook[sheetName];
  for (final List<String> row in rows) {
    sheet.appendRow(row.map<TextCellValue>((String value) => TextCellValue(value)).toList(growable: false));
  }
  if (firstSheet != sheetName) workbook.delete(firstSheet);
  return workbook.save();
}
