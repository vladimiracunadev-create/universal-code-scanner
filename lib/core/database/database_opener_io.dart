import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openScannerDatabase() async {
  final Directory directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final String path = '${directory.path}${Platform.pathSeparator}universal_code_scanner_v2.db';
  return databaseFactoryIo.openDatabase(path, version: 2);
}
