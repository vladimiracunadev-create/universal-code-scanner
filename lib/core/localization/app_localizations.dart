import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  static const List<Locale> supportedLocales = <Locale>[Locale('es', 'CL'), Locale('es'), Locale('en')];

  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get _es => locale.languageCode != 'en';
  String get appTitle => 'Universal Code Scanner';
  String get scan => _es ? 'Escanear' : 'Scan';
  String get inventory => _es ? 'Inventario' : 'Inventory';
  String get generate => _es ? 'Generar' : 'Generate';
  String get history => _es ? 'Historial' : 'History';
  String get settings => _es ? 'Ajustes' : 'Settings';
  String get scannerTitle => _es ? 'Escáner universal' : 'Universal scanner';
  String get scannerSubtitle => _es ? 'Escanea, interpreta y verifica antes de ejecutar' : 'Scan, interpret, and verify before acting';
  String get temporaryMode => _es ? 'Modo temporal' : 'Temporary mode';
  String get recoveryCenter => _es ? 'Centro de recuperación' : 'Recovery center';
  String get retry => _es ? 'Reintentar' : 'Retry';
  String get cancel => _es ? 'Cancelar' : 'Cancel';
  String get continueLabel => _es ? 'Continuar' : 'Continue';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => <String>{'es', 'en'}.contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppStringsContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this);
}
