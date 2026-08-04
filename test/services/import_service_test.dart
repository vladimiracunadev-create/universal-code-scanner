import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/models/scan_record.dart';
import 'package:universal_code_scanner/services/import_service.dart';

void main() {
  test('history import previews valid, duplicate, and rejected records', () {
    final ScanRecord record = ScanRecord.manual(rawValue: 'https://example.com', format: 'QR', source: 'Test');
    final List<int> bytes = utf8.encode(jsonEncode(<String, Object?>{
      'application': 'Universal Code Scanner',
      'schemaVersion': 2,
      'type': 'history',
      'records': <Object?>[record.toJson(), 'invalid'],
    }));

    final HistoryImportPreview preview = ImportService.parseHistoryBytes(bytes, existingIds: <String>{record.id});
    expect(preview.valid, 1);
    expect(preview.duplicates, 1);
    expect(preview.rejected, 1);
    expect(preview.apply(<String>{record.id}, ImportStrategy.skipDuplicates), isEmpty);
  });

  test('future schema is rejected before modifying data', () {
    final List<int> bytes = utf8.encode(jsonEncode(<String, Object?>{
      'application': 'Universal Code Scanner',
      'schemaVersion': 999,
      'type': 'history',
      'records': <Object?>[],
    }));
    expect(
      () => ImportService.parseHistoryBytes(bytes, existingIds: const <String>{}),
      throwsA(isA<FormatException>()),
    );
  });

  test('duplicate records inside the same file are collapsed before import', () {
    final ScanRecord record = ScanRecord.manual(rawValue: 'same', format: 'QR', source: 'Test');
    final List<int> bytes = utf8.encode(jsonEncode(<String, Object?>{
      'application': 'Universal Code Scanner',
      'schemaVersion': 2,
      'type': 'history',
      'records': <Object?>[record.toJson(), record.toJson()],
    }));

    final HistoryImportPreview preview = ImportService.parseHistoryBytes(bytes, existingIds: const <String>{});
    expect(preview.records, hasLength(1));
    expect(preview.duplicates, 1);
  });

  test('excessively deep JSON is rejected before persistence', () {
    dynamic nested = <String, Object?>{'value': true};
    for (int index = 0; index < ImportService.maxJsonDepth + 2; index++) {
      nested = <String, Object?>{'child': nested};
    }
    final List<int> bytes = utf8.encode(jsonEncode(nested));
    expect(
      () => ImportService.parseHistoryBytes(bytes, existingIds: const <String>{}),
      throwsA(isA<FormatException>()),
    );
  });

}
