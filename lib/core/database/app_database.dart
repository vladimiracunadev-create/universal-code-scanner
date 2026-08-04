import 'package:sembast/sembast_memory.dart';
import 'package:universal_code_scanner/core/database/database_opener.dart';
import 'package:universal_code_scanner/core/database/schema_migrator.dart';

class AppDatabase {
  AppDatabase._(this.database, {required this.temporary});

  final Database database;
  final bool temporary;

  static Future<AppDatabase> open() async {
    final AppDatabase result = AppDatabase._(await openScannerDatabase(), temporary: false);
    await SchemaMigrator(result.database).migrate();
    return result;
  }

  static Future<AppDatabase> openTemporary() async {
    final Database database = await databaseFactoryMemory.openDatabase('ucs_temporary_${DateTime.now().microsecondsSinceEpoch}');
    final AppDatabase result = AppDatabase._(database, temporary: true);
    await SchemaMigrator(database).migrate();
    return result;
  }

  Future<void> close() => database.close();
}
