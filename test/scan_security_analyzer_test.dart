import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/core/security/scan_security_analyzer.dart';

void main() {
  group('ScanSecurityAnalyzer', () {
    test('acepta un enlace HTTPS común', () {
      final SecurityAssessment result =
          ScanSecurityAnalyzer.analyze('https://example.com/documento');

      expect(result.level, RiskLevel.low);
      expect(result.canOpen, isTrue);
      expect(result.reasons, isEmpty);
    });

    test('advierte cuando el enlace usa HTTP', () {
      final SecurityAssessment result =
          ScanSecurityAnalyzer.analyze('http://example.com');

      expect(result.level, RiskLevel.caution);
      expect(result.canOpen, isTrue);
    });

    test('no marca un correo dentro de la consulta como credencial', () {
      final SecurityAssessment result = ScanSecurityAnalyzer.analyze(
        'https://example.com/contacto?email=persona@example.com',
      );

      expect(result.level, RiskLevel.low);
      expect(result.canOpen, isTrue);
    });

    test('marca credenciales antes del dominio como riesgo elevado', () {
      final SecurityAssessment result = ScanSecurityAnalyzer.analyze(
        'https://usuario@example.com',
      );

      expect(result.level, RiskLevel.high);
      expect(result.canOpen, isTrue);
    });

    test('marca Punycode como riesgo elevado', () {
      final SecurityAssessment result =
          ScanSecurityAnalyzer.analyze('https://xn--pple-43d.com');

      expect(result.level, RiskLevel.high);
      expect(result.reasons, isNotEmpty);
    });

    test('bloquea esquemas desconocidos', () {
      final SecurityAssessment result =
          ScanSecurityAnalyzer.analyze('javascript:alert(1)');

      expect(result.level, RiskLevel.high);
      expect(result.canOpen, isFalse);
    });

    test('permite acciones telefónicas explícitas', () {
      final SecurityAssessment result =
          ScanSecurityAnalyzer.analyze('tel:+56912345678');

      expect(result.level, RiskLevel.low);
      expect(result.canOpen, isTrue);
    });

    test('trata un QR Wi-Fi como contenido estructurado', () {
      final SecurityAssessment result = ScanSecurityAnalyzer.analyze(
        'WIFI:T:WPA;S:Invitados;P:clave-segura;;',
      );

      expect(result.level, RiskLevel.low);
      expect(result.canOpen, isFalse);
    });

    test('advierte que una clave OTP es sensible', () {
      final SecurityAssessment result = ScanSecurityAnalyzer.analyze(
        'otpauth://totp/Ejemplo?secret=ABC123',
      );

      expect(result.level, RiskLevel.caution);
      expect(result.canOpen, isFalse);
    });
  });
}
