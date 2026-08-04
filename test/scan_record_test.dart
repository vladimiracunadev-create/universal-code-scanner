import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:universal_code_scanner/core/security/scan_security_analyzer.dart';
import 'package:universal_code_scanner/models/parsed_content.dart';
import 'package:universal_code_scanner/models/scan_record.dart';

void main() {
  test('ScanRecord conserva todos sus datos al serializar', () {
    final ScanRecord original = ScanRecord(
      id: 'abc123',
      rawValue: 'https://example.com',
      displayValue: 'https://example.com',
      format: 'QR Code',
      contentType: 'Enlace web',
      scannedAt: DateTime.utc(2026, 8, 2, 22, 30),
      source: 'Cámara',
      riskLevel: RiskLevel.low,
      riskReasons: const <String>[],
      canOpen: true,
      parsed: const ParsedContent(
        kind: ContentKind.url,
        title: 'Enlace web',
        fields: <String, String>{'Dominio': 'example.com'},
      ),
      favorite: true,
      tags: const <String>['trabajo'],
      notes: 'Revisado',
    );

    final ScanRecord restored = ScanRecord.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.rawValue, original.rawValue);
    expect(restored.scannedAt, original.scannedAt);
    expect(restored.riskLevel, original.riskLevel);
    expect(restored.parsed.kind, ContentKind.url);
    expect(restored.favorite, isTrue);
    expect(restored.tags, <String>['trabajo']);
    expect(restored.notes, 'Revisado');
  });

  test('ScanRecord conserva un contenido binario como Base64', () {
    final Barcode barcode = Barcode(
      format: BarcodeFormat.qrCode,
      rawDecodedBytes: DecodedBarcodeBytes(
        bytes: Uint8List.fromList(<int>[0, 1, 254, 255]),
      ),
    );

    final ScanRecord record = ScanRecord.fromBarcode(
      barcode,
      source: 'Prueba',
      scannedAt: DateTime.utc(2026, 8, 2, 22, 30),
    );

    expect(record.rawValue, startsWith('binary-base64:'));
    expect(record.contentType, 'Datos binarios');
    expect(record.parsed.kind, ContentKind.binary);
    expect(record.riskLevel, RiskLevel.low);
    expect(record.canOpen, isFalse);
  });

  test('identifica OTP y Wi-Fi con contraseña como sensibles', () {
    final ScanRecord otp = ScanRecord.manual(
      rawValue: 'otpauth://totp/Ejemplo?secret=ABC123',
      format: 'QR Code',
      source: 'Prueba',
    );
    final ScanRecord wifi = ScanRecord.manual(
      rawValue: 'WIFI:T:WPA;S:Invitados;P:secreto;;',
      format: 'QR Code',
      source: 'Prueba',
    );

    expect(otp.isSensitive, isTrue);
    expect(wifi.isSensitive, isTrue);
  });
}
