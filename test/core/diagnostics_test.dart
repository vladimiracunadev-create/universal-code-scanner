import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/core/diagnostics/app_diagnostics.dart';

void main() {
  test('diagnostic export excludes error messages and sensitive values', () {
    final AppDiagnostics diagnostics = AppDiagnostics.instance..clear();
    diagnostics.record(
      StateError('password=secret otp=ABC123 https://private.example'),
      StackTrace.fromString('frame one\nframe two'),
      area: 'test area',
    );

    final String exported = diagnostics.exportJson();
    expect(exported, isNot(contains('secret')));
    expect(exported, isNot(contains('ABC123')));
    expect(exported, isNot(contains('private.example')));
    expect(exported, contains('StateError'));
    diagnostics.clear();
  });
}
