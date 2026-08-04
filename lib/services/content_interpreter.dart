import 'package:universal_code_scanner/models/parsed_content.dart';

abstract final class ContentInterpreter {
  static ParsedContent parse(String rawValue) {
    final String raw = rawValue.trim();
    final String lower = raw.toLowerCase();

    if (lower.startsWith('binary-base64:')) {
      return ParsedContent(
        kind: ContentKind.binary,
        title: 'Datos binarios',
        summary: 'Contenido codificado en Base64',
        fields: <String, String>{'Carga': raw.substring(14)},
      );
    }
    if (lower.startsWith('wifi:')) return _wifi(raw);
    if (lower.startsWith('begin:vcard')) return _vcard(raw);
    if (lower.startsWith('mecard:')) return _mecard(raw);
    if (lower.startsWith('begin:vevent')) return _event(raw);
    if (lower.startsWith('mailto:') || lower.startsWith('matmsg:')) return _email(raw);
    if (lower.startsWith('tel:')) {
      return ParsedContent(
        kind: ContentKind.phone,
        title: 'Teléfono',
        fields: <String, String>{'Número': raw.substring(4)},
      );
    }
    if (lower.startsWith('sms:') || lower.startsWith('smsto:')) return _sms(raw);
    if (lower.startsWith('geo:')) return _geo(raw);
    if (lower.startsWith('otpauth:')) return _otp(raw);
    if (lower.startsWith('bitcoin:') || lower.startsWith('lightning:') || lower.startsWith('ethereum:')) {
      return _crypto(raw);
    }
    if (raw.startsWith('SPC\n')) return _swissQr(raw);
    if (raw.startsWith('BCD\n')) return _epc(raw);
    if (raw.startsWith('000201') && raw.contains('6304')) return _emv(raw);
    if (raw.startsWith('@') && raw.contains('ANSI ')) return _aamva(raw);
    if (_looksLikeGs1(raw)) return _gs1(raw);
    if (_isIsbn(raw)) {
      return ParsedContent(
        kind: ContentKind.isbn,
        title: 'ISBN',
        fields: <String, String>{'ISBN': raw.replaceAll(RegExp(r'[^0-9Xx]'), '')},
      );
    }

    final Uri? uri = _webUri(raw);
    if (uri != null) {
      return ParsedContent(
        kind: ContentKind.url,
        title: 'Enlace web',
        summary: uri.host,
        fields: <String, String>{
          'Dominio': uri.host,
          'Protocolo': uri.scheme.toUpperCase(),
          if (uri.path.isNotEmpty) 'Ruta': uri.path,
          if (uri.query.isNotEmpty) 'Consulta': uri.query,
          'Dirección': uri.toString(),
        },
      );
    }

    if (RegExp(r'^\d{8,14}$').hasMatch(raw)) {
      return ParsedContent(
        kind: ContentKind.product,
        title: 'Código de producto',
        fields: <String, String>{'Identificador': raw, 'Longitud': '${raw.length} dígitos'},
      );
    }

    return ParsedContent(
      kind: ContentKind.text,
      title: 'Texto',
      fields: <String, String>{'Contenido': raw},
    );
  }

  static ParsedContent _wifi(String raw) {
    final Map<String, String> values = _segments(raw.substring(5));
    return ParsedContent(
      kind: ContentKind.wifi,
      title: 'Red Wi-Fi',
      summary: values['S'] ?? 'Red sin nombre',
      sensitive: (values['P'] ?? '').isNotEmpty,
      fields: <String, String>{
        'Red': values['S'] ?? '',
        'Seguridad': values['T'] ?? 'Sin especificar',
        'Contraseña': values['P'] ?? '',
        'Oculta': values['H'] ?? 'false',
      },
    );
  }

  static ParsedContent _vcard(String raw) {
    final Map<String, String> fields = <String, String>{};
    for (final String line in raw.replaceAll('\r', '').split('\n')) {
      final int index = line.indexOf(':');
      if (index <= 0) continue;
      final String key = line.substring(0, index).toUpperCase();
      final String value = line.substring(index + 1).replaceAll(r'\n', '\n');
      if (key.startsWith('FN')) fields['Nombre'] = value;
      if (key.startsWith('ORG')) fields['Organización'] = value;
      if (key.startsWith('TITLE')) fields['Cargo'] = value;
      if (key.startsWith('TEL')) fields.putIfAbsent('Teléfono', () => value);
      if (key.startsWith('EMAIL')) fields.putIfAbsent('Correo', () => value);
      if (key.startsWith('ADR')) fields['Dirección'] = value.replaceAll(';', ', ');
      if (key.startsWith('URL')) fields['Sitio web'] = value;
      if (key.startsWith('NOTE')) fields['Nota'] = value;
    }
    return ParsedContent(
      kind: ContentKind.contact,
      title: 'Contacto',
      summary: fields['Nombre'],
      fields: fields.isEmpty ? <String, String>{'vCard': raw} : fields,
    );
  }

  static ParsedContent _mecard(String raw) {
    final Map<String, String> values = _segments(raw.substring(7));
    return ParsedContent(
      kind: ContentKind.contact,
      title: 'Contacto MeCard',
      summary: values['N'],
      fields: <String, String>{
        if (values['N'] != null) 'Nombre': values['N']!,
        if (values['TEL'] != null) 'Teléfono': values['TEL']!,
        if (values['EMAIL'] != null) 'Correo': values['EMAIL']!,
        if (values['ADR'] != null) 'Dirección': values['ADR']!,
        if (values['URL'] != null) 'Sitio web': values['URL']!,
      },
    );
  }

  static ParsedContent _event(String raw) {
    final Map<String, String> fields = <String, String>{};
    for (final String line in raw.replaceAll('\r', '').split('\n')) {
      final int index = line.indexOf(':');
      if (index <= 0) continue;
      final String key = line.substring(0, index).toUpperCase();
      final String value = line.substring(index + 1);
      if (key.startsWith('SUMMARY')) fields['Título'] = value;
      if (key.startsWith('DTSTART')) fields['Inicio'] = value;
      if (key.startsWith('DTEND')) fields['Término'] = value;
      if (key.startsWith('LOCATION')) fields['Ubicación'] = value;
      if (key.startsWith('DESCRIPTION')) fields['Descripción'] = value;
    }
    return ParsedContent(
      kind: ContentKind.event,
      title: 'Evento de calendario',
      summary: fields['Título'],
      fields: fields,
    );
  }

  static ParsedContent _email(String raw) {
    if (raw.toLowerCase().startsWith('matmsg:')) {
      final Map<String, String> values = _segments(raw.substring(7));
      return ParsedContent(
        kind: ContentKind.email,
        title: 'Correo electrónico',
        summary: values['TO'],
        fields: <String, String>{
          'Destinatario': values['TO'] ?? '',
          'Asunto': values['SUB'] ?? '',
          'Mensaje': values['BODY'] ?? '',
        },
      );
    }
    final Uri? uri = Uri.tryParse(raw);
    return ParsedContent(
      kind: ContentKind.email,
      title: 'Correo electrónico',
      summary: uri?.path,
      fields: <String, String>{
        'Destinatario': uri?.path ?? raw.substring(7),
        'Asunto': uri?.queryParameters['subject'] ?? '',
        'Mensaje': uri?.queryParameters['body'] ?? '',
      },
    );
  }

  static ParsedContent _sms(String raw) {
    final int separator = raw.indexOf(':');
    final String payload = separator < 0 ? raw : raw.substring(separator + 1);
    final int next = payload.indexOf(':');
    return ParsedContent(
      kind: ContentKind.sms,
      title: 'Mensaje SMS',
      fields: <String, String>{
        'Número': next < 0 ? payload : payload.substring(0, next),
        'Mensaje': next < 0 ? '' : payload.substring(next + 1),
      },
    );
  }

  static ParsedContent _geo(String raw) {
    final String payload = raw.substring(4);
    final String coordinates = payload.split('?').first;
    final List<String> parts = coordinates.split(',');
    return ParsedContent(
      kind: ContentKind.geo,
      title: 'Ubicación',
      fields: <String, String>{
        'Latitud': parts.isNotEmpty ? parts.first : '',
        'Longitud': parts.length > 1 ? parts[1] : '',
        if (payload.contains('?q=')) 'Búsqueda': Uri.decodeComponent(payload.split('?q=').last),
      },
    );
  }

  static ParsedContent _otp(String raw) {
    final Uri? uri = Uri.tryParse(raw);
    return ParsedContent(
      kind: ContentKind.otp,
      title: 'Clave OTP',
      summary: uri?.pathSegments.isNotEmpty == true ? Uri.decodeComponent(uri!.pathSegments.last) : null,
      sensitive: true,
      fields: <String, String>{
        'Tipo': uri?.host ?? '',
        'Cuenta': uri?.path.replaceFirst('/', '') ?? '',
        'Emisor': uri?.queryParameters['issuer'] ?? '',
        'Algoritmo': uri?.queryParameters['algorithm'] ?? 'SHA1',
        'Dígitos': uri?.queryParameters['digits'] ?? '6',
        'Periodo': uri?.queryParameters['period'] ?? '30',
        'Secreto': uri?.queryParameters['secret'] ?? '',
      },
    );
  }

  static ParsedContent _crypto(String raw) {
    final Uri? uri = Uri.tryParse(raw);
    return ParsedContent(
      kind: ContentKind.crypto,
      title: 'Pago con criptomoneda',
      summary: uri?.scheme.toUpperCase(),
      sensitive: true,
      fields: <String, String>{
        'Red': uri?.scheme ?? '',
        'Dirección': uri?.path ?? raw,
        if (uri?.queryParameters['amount'] != null) 'Monto': uri!.queryParameters['amount']!,
        if (uri?.queryParameters['label'] != null) 'Etiqueta': uri!.queryParameters['label']!,
      },
    );
  }

  static ParsedContent _gs1(String raw) {
    final Map<String, String> fields = <String, String>{};
    final RegExp exp = RegExp(r'\((\d{2,4})\)([^()]*)');
    for (final RegExpMatch match in exp.allMatches(raw)) {
      final String ai = match.group(1)!;
      final String value = match.group(2)!.trim();
      fields[_aiLabel(ai)] = value;
    }
    return ParsedContent(
      kind: ContentKind.gs1,
      title: 'Datos GS1',
      summary: fields['GTIN'],
      fields: fields.isEmpty ? <String, String>{'Carga GS1': raw} : fields,
    );
  }

  static ParsedContent _emv(String raw) {
    final Map<String, String> fields = _tlv(raw);
    return ParsedContent(
      kind: ContentKind.payment,
      title: 'Pago QR EMVCo',
      sensitive: true,
      fields: <String, String>{
        if (fields['53'] != null) 'Moneda': fields['53']!,
        if (fields['54'] != null) 'Monto': fields['54']!,
        if (fields['58'] != null) 'País': fields['58']!,
        if (fields['59'] != null) 'Comercio': fields['59']!,
        if (fields['60'] != null) 'Ciudad': fields['60']!,
        if (fields['63'] != null) 'CRC': fields['63']!,
        'Carga': raw,
      },
    );
  }

  static ParsedContent _epc(String raw) {
    final List<String> lines = raw.split('\n');
    return ParsedContent(
      kind: ContentKind.payment,
      title: 'Transferencia EPC/SEPA',
      sensitive: true,
      fields: <String, String>{
        if (lines.length > 5) 'Beneficiario': lines[5],
        if (lines.length > 6) 'IBAN': lines[6],
        if (lines.length > 7) 'Monto': lines[7],
        if (lines.length > 9) 'Referencia': lines[9],
      },
    );
  }

  static ParsedContent _swissQr(String raw) {
    final List<String> lines = raw.split('\n');
    return ParsedContent(
      kind: ContentKind.payment,
      title: 'Swiss QR Bill',
      sensitive: true,
      fields: <String, String>{
        if (lines.length > 3) 'IBAN': lines[3],
        if (lines.length > 5) 'Nombre': lines[5],
        if (lines.length > 18) 'Monto': lines[18],
        if (lines.length > 19) 'Moneda': lines[19],
      },
    );
  }

  static ParsedContent _aamva(String raw) {
    final Map<String, String> fields = <String, String>{};
    for (final String code in <String>['DAQ', 'DCS', 'DAC', 'DBB', 'DBA', 'DAG', 'DAI']) {
      final RegExpMatch? match = RegExp('$code([^\r\n]+)').firstMatch(raw);
      if (match != null) fields[_aamvaLabel(code)] = match.group(1)!.trim();
    }
    return ParsedContent(
      kind: ContentKind.identity,
      title: 'Documento AAMVA',
      sensitive: true,
      fields: fields,
    );
  }

  static Map<String, String> _segments(String value) {
    final Map<String, String> result = <String, String>{};
    final StringBuffer current = StringBuffer();
    final List<String> parts = <String>[];
    bool escaped = false;
    for (final int rune in value.runes) {
      final String char = String.fromCharCode(rune);
      if (escaped) {
        current.write(char);
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == ';') {
        parts.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    if (current.length > 0) parts.add(current.toString());
    for (final String part in parts) {
      final int index = part.indexOf(':');
      if (index > 0) result[part.substring(0, index).toUpperCase()] = part.substring(index + 1);
    }
    return result;
  }

  static Map<String, String> _tlv(String raw) {
    final Map<String, String> result = <String, String>{};
    int index = 0;
    while (index + 4 <= raw.length) {
      final String id = raw.substring(index, index + 2);
      final int? length = int.tryParse(raw.substring(index + 2, index + 4));
      if (length == null || index + 4 + length > raw.length) break;
      result[id] = raw.substring(index + 4, index + 4 + length);
      index += 4 + length;
    }
    return result;
  }

  static Uri? _webUri(String value) {
    final String normalized = value.toLowerCase().startsWith('www.') ? 'https://$value' : value;
    final Uri? uri = Uri.tryParse(normalized);
    if (uri == null || !<String>{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) return null;
    return uri;
  }

  static bool _looksLikeGs1(String raw) => RegExp(r'^\(\d{2,4}\)').hasMatch(raw) || raw.contains('<GS>');

  static bool _isIsbn(String raw) {
    final String value = raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (value.length == 13 && (value.startsWith('978') || value.startsWith('979'))) return true;
    return value.length == 10;
  }

  static String _aiLabel(String ai) => switch (ai) {
        '00' => 'SSCC',
        '01' => 'GTIN',
        '10' => 'Lote',
        '11' => 'Fecha de producción',
        '15' => 'Consumo preferente',
        '17' => 'Vencimiento',
        '21' => 'Número de serie',
        '30' => 'Cantidad',
        '414' => 'GLN',
        _ => 'AI $ai',
      };

  static String _aamvaLabel(String code) => switch (code) {
        'DAQ' => 'Número de licencia',
        'DCS' => 'Apellido',
        'DAC' => 'Nombre',
        'DBB' => 'Fecha de nacimiento',
        'DBA' => 'Vencimiento',
        'DAG' => 'Dirección',
        'DAI' => 'Ciudad',
        _ => code,
      };
}
