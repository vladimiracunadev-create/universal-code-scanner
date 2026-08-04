import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:universal_code_scanner/core/database/schema_migrator.dart';

void main() {
  test('schema migration is idempotent and non-destructive', () async {
    final database = await databaseFactoryMemory.openDatabase('schema-test');
    addTearDown(database.close);
    final SchemaMigrator migrator = SchemaMigrator(database);

    final first = await migrator.migrate();
    final second = await migrator.migrate();

    expect(first.toVersion, SchemaMigrator.currentVersion);
    expect(first.applied, isNotEmpty);
    expect(second.applied, isEmpty);
    expect(second.toVersion, SchemaMigrator.currentVersion);
  });
}
