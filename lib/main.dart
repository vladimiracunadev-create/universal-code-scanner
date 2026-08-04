import 'dart:async';

import 'package:flutter/material.dart';
import 'package:universal_code_scanner/bootstrap_host.dart';
import 'package:universal_code_scanner/core/diagnostics/app_diagnostics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
  runZonedGuarded<void>(
    () => runApp(const BootstrapHost()),
    (Object error, StackTrace stack) => AppDiagnostics.instance.record(error, stack, area: 'root_zone'),
  );
}
