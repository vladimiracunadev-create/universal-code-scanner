import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:universal_code_scanner/core/localization/app_localizations.dart';

void main() {
  test('Spanish and English navigation labels are available', () {
    expect(const AppLocalizations(Locale('es', 'CL')).scan, 'Escanear');
    expect(const AppLocalizations(Locale('es')).scan, 'Escanear');
    expect(const AppLocalizations(Locale('en')).scan, 'Scan');
    expect(AppLocalizations.supportedLocales, contains(const Locale('es', 'CL')));
  });
}
