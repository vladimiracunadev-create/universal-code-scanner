import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:universal_code_scanner/core/localization/app_localizations.dart';

void main() {
  test('the interface is offered only in Spanish', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('es', 'CL')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('es')));
    expect(AppLocalizations.supportedLocales, isNot(contains(const Locale('en'))));
  });

  test('Spanish navigation labels resolve for every supported locale', () {
    for (final Locale locale in AppLocalizations.supportedLocales) {
      final AppLocalizations strings = AppLocalizations(locale);
      expect(strings.scan, 'Escanear');
      expect(strings.inventory, 'Inventario');
      expect(strings.generate, 'Generar');
      expect(strings.history, 'Historial');
      expect(strings.settings, 'Ajustes');
    }
  });

  test('an unsupported device locale never yields a half-translated interface', () {
    // The delegate rejects English, so Flutter falls back to the first
    // supported locale and the whole interface stays in one language.
    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isFalse);
    expect(AppLocalizations.delegate.isSupported(const Locale('es')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('es', 'CL')), isTrue);
  });

  test('English keys remain available for the pending translation', () {
    expect(const AppLocalizations(Locale('en')).scan, 'Scan');
  });
}
