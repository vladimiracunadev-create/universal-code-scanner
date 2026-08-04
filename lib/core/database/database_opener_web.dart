import 'package:sembast_web/sembast_web.dart';

Future<Database> openScannerDatabase() {
  return databaseFactoryWeb.openDatabase('universal_code_scanner_v2.db', version: 2);
}
