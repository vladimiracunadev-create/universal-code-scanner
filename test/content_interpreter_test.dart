import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/models/parsed_content.dart';
import 'package:universal_code_scanner/services/content_interpreter.dart';

void main() {
  group('ContentInterpreter', () {
    test('interpreta Wi-Fi con campos escapados', () {
      final ParsedContent parsed = ContentInterpreter.parse(
        r'WIFI:T:WPA;S:Mi\;Red;P:clave\:segura;H:false;;',
      );

      expect(parsed.kind, ContentKind.wifi);
      expect(parsed.fields['Red'], 'Mi;Red');
      expect(parsed.fields['Contraseña'], 'clave:segura');
      expect(parsed.sensitive, isTrue);
    });

    test('interpreta una vCard', () {
      final ParsedContent parsed = ContentInterpreter.parse(
        'BEGIN:VCARD\nVERSION:3.0\nFN:Ana Pérez\nTEL:+56912345678\nEMAIL:ana@example.com\nEND:VCARD',
      );

      expect(parsed.kind, ContentKind.contact);
      expect(parsed.fields['Nombre'], 'Ana Pérez');
      expect(parsed.fields['Correo'], 'ana@example.com');
    });

    test('interpreta identificadores GS1', () {
      final ParsedContent parsed = ContentInterpreter.parse(
        '(01)09506000134352(10)LOTE-7(17)270101',
      );

      expect(parsed.kind, ContentKind.gs1);
      expect(parsed.fields['GTIN'], '09506000134352');
      expect(parsed.fields['Lote'], 'LOTE-7');
      expect(parsed.fields['Vencimiento'], '270101');
    });

    test('interpreta datos EMVCo', () {
      final ParsedContent parsed = ContentInterpreter.parse(
        '0002015303152540512.345802CL5910COMERCIO X6008SANTIAGO6304ABCD',
      );

      expect(parsed.kind, ContentKind.payment);
      expect(parsed.title, 'Pago QR EMVCo');
      expect(parsed.sensitive, isTrue);
    });

    test('normaliza un enlace que comienza con www', () {
      final ParsedContent parsed = ContentInterpreter.parse('www.example.com/ruta');

      expect(parsed.kind, ContentKind.url);
      expect(parsed.fields['Dominio'], 'www.example.com');
      expect(parsed.fields['Protocolo'], 'HTTPS');
    });

    test('identifica ISBN', () {
      final ParsedContent parsed = ContentInterpreter.parse('9789561234567');

      expect(parsed.kind, ContentKind.isbn);
      expect(parsed.fields['ISBN'], '9789561234567');
    });
  });
}
