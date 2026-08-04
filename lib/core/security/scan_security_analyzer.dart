enum RiskLevel { low, caution, high }

class SecurityAssessment {
  const SecurityAssessment({
    required this.level,
    required this.reasons,
    required this.canOpen,
    this.normalizedHost,
  });

  final RiskLevel level;
  final List<String> reasons;
  final bool canOpen;
  final String? normalizedHost;

  String get label => switch (level) {
        RiskLevel.low => 'Sin señales evidentes',
        RiskLevel.caution => 'Revisar antes de abrir',
        RiskLevel.high => 'Riesgo elevado',
      };
}

abstract final class ScanSecurityAnalyzer {
  static const Set<String> _shorteners = <String>{
    'bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'ow.ly', 'buff.ly',
    'is.gd', 'cutt.ly', 'rebrand.ly', 'shorturl.at', 'tiny.one',
  };
  static const Set<String> _dangerousExtensions = <String>{
    '.apk', '.appx', '.bat', '.cmd', '.com', '.dmg', '.exe', '.hta',
    '.iso', '.jar', '.js', '.msi', '.pkg', '.ps1', '.scr', '.vbs', '.zip',
  };

  static SecurityAssessment analyze(String rawValue) {
    final String value = rawValue.trim();
    final String lower = value.toLowerCase();

    if (lower.startsWith('otpauth:') || lower.startsWith('bitcoin:') ||
        lower.startsWith('lightning:') || lower.startsWith('ethereum:')) {
      return const SecurityAssessment(
        level: RiskLevel.caution,
        reasons: <String>['Contiene información sensible o una instrucción de pago. Verifica todos los datos antes de usarla.'],
        canOpen: false,
      );
    }

    if (_isSafeSystemScheme(lower)) {
      return const SecurityAssessment(level: RiskLevel.low, reasons: <String>[], canOpen: true);
    }
    if (_isKnownStructuredContent(lower)) {
      return const SecurityAssessment(level: RiskLevel.low, reasons: <String>[], canOpen: false);
    }

    final Uri? uri = _toWebUri(value);
    if (uri == null) {
      final bool unknownScheme = RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(value);
      return SecurityAssessment(
        level: unknownScheme ? RiskLevel.high : RiskLevel.low,
        reasons: unknownScheme ? const <String>['El código usa un esquema de aplicación no permitido.'] : const <String>[],
        canOpen: false,
      );
    }

    final List<String> reasons = <String>[];
    RiskLevel level = RiskLevel.low;
    void caution(String reason) {
      reasons.add(reason);
      if (level == RiskLevel.low) level = RiskLevel.caution;
    }
    void high(String reason) {
      reasons.add(reason);
      level = RiskLevel.high;
    }

    if (uri.scheme == 'http') caution('La dirección no usa HTTPS cifrado.');
    if (uri.host.isEmpty) high('No se pudo identificar un dominio válido.');
    if (uri.userInfo.isNotEmpty) high('La dirección contiene credenciales o un símbolo @ potencialmente engañoso.');
    if (uri.host.contains('xn--')) high('El dominio usa Punycode y podría imitar otro nombre.');
    if (_hasMixedScripts(uri.host)) high('El dominio mezcla alfabetos visualmente similares.');
    if (uri.host.runes.any((int rune) => rune > 127)) caution('El dominio contiene caracteres internacionales; revisa su escritura.');
    if (_isIpAddress(uri.host)) caution('El destino usa una dirección IP en lugar de un dominio reconocible.');
    if (_isPrivateOrLocalHost(uri.host)) high('El enlace apunta al propio dispositivo o a una red privada.');
    if (_shorteners.contains(uri.host.toLowerCase())) caution('La dirección está acortada y oculta el destino final.');
    if (uri.host.split('.').length > 5) caution('El dominio tiene una cantidad inusual de subdominios.');
    if (uri.hasPort && !<int>{80, 443}.contains(uri.port)) caution('La dirección utiliza un puerto poco habitual (${uri.port}).');
    if (value.length > 240) caution('La dirección es inusualmente extensa.');
    if (lower.contains('%00') || value.runes.any((int rune) => rune < 32)) high('La dirección contiene caracteres de control sospechosos.');
    if (_dangerousExtensions.any((String extension) => uri.path.toLowerCase().endsWith(extension))) {
      high('El enlace parece descargar un archivo ejecutable o comprimido.');
    }
    if (_looksLikeLogin(uri)) caution('La ruta parece conducir a una pantalla de acceso; confirma el dominio antes de ingresar credenciales.');
    if (_hasExcessiveTracking(uri)) caution('La dirección contiene varios parámetros de seguimiento.');

    return SecurityAssessment(
      level: level,
      reasons: reasons,
      canOpen: uri.scheme == 'http' || uri.scheme == 'https',
      normalizedHost: uri.host.toLowerCase(),
    );
  }

  static Uri? normalizedActionUri(String rawValue) {
    final String value = rawValue.trim();
    final String lower = value.toLowerCase();
    if (_isSafeSystemScheme(lower)) return Uri.tryParse(value);
    return _toWebUri(value);
  }

  static bool _isSafeSystemScheme(String lower) =>
      lower.startsWith('mailto:') || lower.startsWith('tel:') ||
      lower.startsWith('sms:') || lower.startsWith('smsto:') || lower.startsWith('geo:');

  static bool _isKnownStructuredContent(String lower) =>
      lower.startsWith('binary-base64:') || lower.startsWith('wifi:') ||
      lower.startsWith('begin:vcard') || lower.startsWith('mecard:') ||
      lower.startsWith('matmsg:') || lower.startsWith('begin:vevent') ||
      lower.startsWith('000201') || lower.startsWith('spc\n') || lower.startsWith('bcd\n');

  static Uri? _toWebUri(String value) {
    final String normalized = value.toLowerCase().startsWith('www.') ? 'https://$value' : value;
    final Uri? uri = Uri.tryParse(normalized);
    if (uri == null || !<String>{'http', 'https'}.contains(uri.scheme)) return null;
    return uri;
  }

  static bool _isIpAddress(String host) {
    final RegExp ipv4 = RegExp(r'^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$');
    return ipv4.hasMatch(host) || host.contains(':');
  }

  static bool _isPrivateOrLocalHost(String host) {
    final String h = host.toLowerCase();
    if (h == 'localhost' || h.endsWith('.local')) return true;
    final List<int> parts = h.split('.').map(int.tryParse).whereType<int>().toList();
    if (parts.length != 4) return false;
    return parts[0] == 10 || parts[0] == 127 ||
        (parts[0] == 192 && parts[1] == 168) ||
        (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) ||
        (parts[0] == 169 && parts[1] == 254);
  }

  static bool _hasMixedScripts(String host) {
    bool latin = false;
    bool cyrillic = false;
    bool greek = false;
    for (final int rune in host.runes) {
      if ((rune >= 0x0041 && rune <= 0x024F)) latin = true;
      if (rune >= 0x0400 && rune <= 0x052F) cyrillic = true;
      if (rune >= 0x0370 && rune <= 0x03FF) greek = true;
    }
    return <bool>[latin, cyrillic, greek].where((bool value) => value).length > 1;
  }

  static bool _looksLikeLogin(Uri uri) {
    final String value = '${uri.path}?${uri.query}'.toLowerCase();
    return <String>['login', 'signin', 'verify', 'account', 'password', 'wallet', 'bank'].any(value.contains);
  }

  static bool _hasExcessiveTracking(Uri uri) {
    final int trackers = uri.queryParameters.keys.where((String key) {
      final String lower = key.toLowerCase();
      return lower.startsWith('utm_') || <String>{'gclid', 'fbclid', 'mc_cid', 'ref'}.contains(lower);
    }).length;
    return trackers >= 3;
  }
}
