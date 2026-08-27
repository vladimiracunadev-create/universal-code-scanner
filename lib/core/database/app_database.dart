import 'package:sembast/sembast_memory.dart';
import 'package:universal_code_scanner/core/database/database_opener.dart';
import 'package:universal_code_scanner/core/database/schema_migrator.dart';

/// Owns the Sembast database and guarantees the schema is current before any
/// repository touches it.
///
/// Two version numbers live here and they are unrelated. The `version: 2`
/// passed to Sembast in the platform openers is the on-disk format of the
/// database file, unchanged since it was renamed to `…_v2.db`.
/// `SchemaMigrator.currentVersion` is the application's own logical schema,
/// kept in the `_schema_meta` store and currently at 4. Confusing the two is
/// the easiest way to break an existing installation.
class AppDatabase {
  AppDatabase._(this.database, {required this.temporary});

  final Database database;
  final bool temporary;

  static Future<AppDatabase> open() async {
    final AppDatabase result = AppDatabase._(await openScannerDatabase(), temporary: false);
    await SchemaMigrator(result.database).migrate();
    return result;
  }

  /// In-memory database for the safe-start «temporary mode» and for tests.
  ///
  /// The timestamp in the name keeps two openings within the same session from
  /// sharing state, which matters in tests that create several databases.
  /// Nothing here reaches the disk, so everything is lost on close — that is
  /// the point, and the interface says so with a permanent banner.
  static Future<AppDatabase> openTemporary() async {
    final Database database = await databaseFactoryMemory.openDatabase('ucs_temporary_${DateTime.now().microsecondsSinceEpoch}');
    final AppDatabase result = AppDatabase._(database, temporary: true);
    await SchemaMigrator(database).migrate();
    return result;
  }

  Future<void> close() => database.close();
}
