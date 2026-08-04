import 'package:mobile_scanner/mobile_scanner.dart';

abstract final class BarcodeLabels {
  static String format(BarcodeFormat format) {
    return switch (format) {
      BarcodeFormat.qrCode => 'QR Code',
      BarcodeFormat.microQrCode => 'Micro QR',
      BarcodeFormat.dataMatrix => 'Data Matrix',
      BarcodeFormat.aztec => 'Aztec',
      BarcodeFormat.pdf417 => 'PDF417',
      BarcodeFormat.maxiCode => 'MaxiCode',
      BarcodeFormat.code128 => 'Code 128',
      BarcodeFormat.code39 => 'Code 39',
      BarcodeFormat.code93 => 'Code 93',
      BarcodeFormat.codabar => 'Codabar',
      BarcodeFormat.ean13 => 'EAN-13',
      BarcodeFormat.ean8 => 'EAN-8',
      BarcodeFormat.upcA => 'UPC-A',
      BarcodeFormat.upcE => 'UPC-E',
      // ignore: deprecated_member_use
      BarcodeFormat.itf => 'ITF',
      BarcodeFormat.itf14 => 'ITF-14',
      BarcodeFormat.itf2of5 => 'ITF 2 de 5',
      BarcodeFormat.itf2of5WithChecksum => 'ITF 2 de 5 con checksum',
      BarcodeFormat.dataBar => 'GS1 DataBar',
      BarcodeFormat.dataBarExpanded => 'GS1 DataBar Expanded',
      BarcodeFormat.dataBarLimited => 'GS1 DataBar Limited',
      BarcodeFormat.all => 'Todos los formatos',
      BarcodeFormat.unknown => 'Formato desconocido',
    };
  }

  static String contentType(Barcode barcode) {
    final String raw = (barcode.rawValue ?? barcode.displayValue ?? '').trim();
    final String lower = raw.toLowerCase();

    if (raw.isEmpty && barcode.rawDecodedBytes != null) return 'Datos binarios';
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.')) {
      return 'Enlace web';
    }
    if (lower.startsWith('wifi:')) return 'Red Wi-Fi';
    if (lower.startsWith('otpauth:')) return 'Clave de autenticación';
    if (lower.startsWith('begin:vcard')) return 'Contacto';
    if (lower.startsWith('mailto:') || lower.startsWith('matmsg:')) {
      return 'Correo electrónico';
    }
    if (lower.startsWith('tel:')) return 'Teléfono';
    if (lower.startsWith('sms:') || lower.startsWith('smsto:')) {
      return 'Mensaje SMS';
    }
    if (lower.startsWith('geo:')) return 'Ubicación';
    if (lower.startsWith('begin:vevent')) return 'Evento de calendario';

    return switch (barcode.type) {
      BarcodeType.contactInfo => 'Contacto',
      BarcodeType.email => 'Correo electrónico',
      BarcodeType.isbn => 'ISBN',
      BarcodeType.phone => 'Teléfono',
      BarcodeType.product => 'Producto',
      BarcodeType.sms => 'Mensaje SMS',
      BarcodeType.text => 'Texto',
      BarcodeType.url => 'Enlace web',
      BarcodeType.wifi => 'Red Wi-Fi',
      BarcodeType.geo => 'Ubicación',
      BarcodeType.calendarEvent => 'Evento de calendario',
      BarcodeType.driverLicense => 'Documento de identidad',
      BarcodeType.unknown => _fallbackType(barcode.format),
    };
  }

  static String _fallbackType(BarcodeFormat format) {
    const Set<BarcodeFormat> productFormats = <BarcodeFormat>{
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.dataBar,
      BarcodeFormat.dataBarExpanded,
      BarcodeFormat.dataBarLimited,
    };

    return productFormats.contains(format) ? 'Producto' : 'Texto';
  }
}
