import 'dart:convert';

import 'package:flutter/foundation.dart';

class DiagnosticEntry {
  const DiagnosticEntry({required this.at, required this.area, required this.errorType, required this.stackFingerprint});
  final DateTime at;
  final String area;
  final String errorType;
  final String stackFingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
        'at': at.toIso8601String(),
        'area': area,
        'errorType': errorType,
        'stackFingerprint': stackFingerprint,
      };
}

/// Stores only technical metadata. Scan payloads and user-entered values are never accepted.
class AppDiagnostics extends ChangeNotifier {
  AppDiagnostics._();
  static final AppDiagnostics instance = AppDiagnostics._();
  static const int maxEntries = 100;

  final List<DiagnosticEntry> _entries = <DiagnosticEntry>[];
  List<DiagnosticEntry> get entries => List<DiagnosticEntry>.unmodifiable(_entries);

  void record(Object error, StackTrace stack, {required String area}) {
    final String stackText = stack.toString();
    final int fingerprint = Object.hash(error.runtimeType.toString(), stackText.split('\n').take(4).join('|'));
    _entries.insert(0, DiagnosticEntry(
      at: DateTime.now().toUtc(),
      area: _sanitize(area),
      errorType: error.runtimeType.toString(),
      stackFingerprint: fingerprint.toUnsigned(32).toRadixString(16).padLeft(8, '0'),
    ));
    if (_entries.length > maxEntries) _entries.removeRange(maxEntries, _entries.length);
    notifyListeners();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'application': 'Universal Code Scanner',
        'schemaVersion': 1,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'privacy': 'No scan payloads, URLs, passwords, one-time codes, notes or inventory values are included.',
        'entries': _entries.map((DiagnosticEntry entry) => entry.toJson()).toList(growable: false),
      });

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  static String _sanitize(String value) {
    final String clean = value.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    return clean.length <= 80 ? clean : clean.substring(0, 80);
  }
}

void installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    AppDiagnostics.instance.record(details.exception, details.stack ?? StackTrace.current, area: 'flutter');
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppDiagnostics.instance.record(error, stack, area: 'platform');
    return true;
  };

}
