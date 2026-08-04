import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_code_scanner/services/clipboard_service.dart';
import 'package:universal_code_scanner/state/settings_store.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({required this.settings, super.key});

  final SettingsStore settings;

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

enum _PayloadType { text, url, wifi, contact, event, email, phone, sms, geo }
enum _CodeFormat { qr, dataMatrix, aztec, pdf417, code128, code39, ean13, ean8, upcA, gs128 }

class _GeneratorScreenState extends State<GeneratorScreen> {
  final GlobalKey _previewKey = GlobalKey();
  final TextEditingController _primary = TextEditingController(text: 'https://example.com');
  final TextEditingController _secondary = TextEditingController();
  final TextEditingController _tertiary = TextEditingController();
  final TextEditingController _quaternary = TextEditingController();
  _PayloadType _payloadType = _PayloadType.url;
  _CodeFormat _format = _CodeFormat.qr;
  bool _highCorrection = true;

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    _tertiary.dispose();
    _quaternary.dispose();
    super.dispose();
  }

  String get _payload => switch (_payloadType) {
        _PayloadType.text => _primary.text,
        _PayloadType.url => _normalizeUrl(_primary.text),
        _PayloadType.wifi => 'WIFI:T:${_secondary.text.isEmpty ? 'WPA' : _secondary.text};S:${_escape(_primary.text)};P:${_escape(_tertiary.text)};H:${_quaternary.text.toLowerCase() == 'true'};;',
        _PayloadType.contact => 'BEGIN:VCARD\nVERSION:3.0\nFN:${_primary.text}\nTEL:${_secondary.text}\nEMAIL:${_tertiary.text}\nORG:${_quaternary.text}\nEND:VCARD',
        _PayloadType.event => 'BEGIN:VEVENT\nSUMMARY:${_primary.text}\nDTSTART:${_secondary.text}\nDTEND:${_tertiary.text}\nLOCATION:${_quaternary.text}\nEND:VEVENT',
        _PayloadType.email => Uri(scheme: 'mailto', path: _primary.text, queryParameters: <String, String>{'subject': _secondary.text, 'body': _tertiary.text}).toString(),
        _PayloadType.phone => 'tel:${_primary.text}',
        _PayloadType.sms => 'SMSTO:${_primary.text}:${_secondary.text}',
        _PayloadType.geo => 'geo:${_primary.text},${_secondary.text}${_tertiary.text.isEmpty ? '' : '?q=${Uri.encodeComponent(_tertiary.text)}'}',
      };

  @override
  Widget build(BuildContext context) {
    final bool twoDimensional = <_CodeFormat>{_CodeFormat.qr, _CodeFormat.dataMatrix, _CodeFormat.aztec, _CodeFormat.pdf417}.contains(_format);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: <Widget>[
        Text('Generador', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Text('Crea códigos verificables sin enviar los datos a un servidor.'),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                DropdownButtonFormField<_PayloadType>(
                  initialValue: _payloadType,
                  decoration: const InputDecoration(labelText: 'Tipo de contenido'),
                  items: _PayloadType.values.map((value) => DropdownMenuItem(value: value, child: Text(_payloadLabel(value)))).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _payloadType = value;
                      _setExamples(value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<_CodeFormat>(
                  initialValue: _format,
                  decoration: const InputDecoration(labelText: 'Formato visual'),
                  items: _CodeFormat.values.map((value) => DropdownMenuItem(value: value, child: Text(_formatLabel(value)))).toList(),
                  onChanged: (value) => value == null ? null : setState(() => _format = value),
                ),
                const SizedBox(height: 12),
                TextField(controller: _primary, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: _labels.$1)),
                if (_labels.$2 != null) ...<Widget>[
                  const SizedBox(height: 10),
                  TextField(controller: _secondary, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: _labels.$2)),
                ],
                if (_labels.$3 != null) ...<Widget>[
                  const SizedBox(height: 10),
                  TextField(controller: _tertiary, onChanged: (_) => setState(() {}), obscureText: _payloadType == _PayloadType.wifi, decoration: InputDecoration(labelText: _labels.$3)),
                ],
                if (_labels.$4 != null) ...<Widget>[
                  const SizedBox(height: 10),
                  TextField(controller: _quaternary, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: _labels.$4)),
                ],
                if (_format == _CodeFormat.qr)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Corrección de errores alta'),
                    subtitle: const Text('Recomendada cuando el QR incorpora un logotipo o puede ensuciarse.'),
                    value: _highCorrection,
                    onChanged: (bool value) => setState(() => _highCorrection = value),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                RepaintBoundary(
                  key: _previewKey,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: BarcodeWidget(
                        barcode: _barcode,
                        data: _payload,
                        width: twoDimensional ? 270 : 330,
                        height: twoDimensional ? 270 : 130,
                        drawText: !twoDimensional,
                        backgroundColor: Colors.white,
                        color: Colors.black,
                        errorBuilder: (BuildContext context, String error) => SizedBox(
                          height: 180,
                          child: Center(child: Text('El contenido no es válido para ${_formatLabel(_format)}.\n$error', textAlign: TextAlign.center)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(_payload, maxLines: 5),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    OutlinedButton.icon(onPressed: _copy, icon: const Icon(Icons.copy_outlined), label: const Text('Copiar datos')),
                    OutlinedButton.icon(onPressed: () => SharePlus.instance.share(ShareParams(text: _payload)), icon: const Icon(Icons.share_outlined), label: const Text('Compartir datos')),
                    FilledButton.icon(onPressed: _sharePng, icon: const Icon(Icons.image_outlined), label: const Text('PNG')),
                    FilledButton.tonalIcon(onPressed: _shareSvg, icon: const Icon(Icons.draw_outlined), label: const Text('SVG')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Barcode get _barcode => switch (_format) {
        _CodeFormat.qr => Barcode.qrCode(errorCorrectLevel: _highCorrection ? BarcodeQRCorrectionLevel.high : BarcodeQRCorrectionLevel.medium),
        _CodeFormat.dataMatrix => Barcode.dataMatrix(),
        _CodeFormat.aztec => Barcode.aztec(),
        _CodeFormat.pdf417 => Barcode.pdf417(),
        _CodeFormat.code128 => Barcode.code128(),
        _CodeFormat.code39 => Barcode.code39(),
        _CodeFormat.ean13 => Barcode.ean13(),
        _CodeFormat.ean8 => Barcode.ean8(),
        _CodeFormat.upcA => Barcode.upcA(),
        _CodeFormat.gs128 => Barcode.gs128(),
      };

  (String, String?, String?, String?) get _labels => switch (_payloadType) {
        _PayloadType.text => ('Texto', null, null, null),
        _PayloadType.url => ('Dirección web', null, null, null),
        _PayloadType.wifi => ('Nombre de red', 'Seguridad: WPA, WEP o nopass', 'Contraseña', 'Red oculta: true o false'),
        _PayloadType.contact => ('Nombre', 'Teléfono', 'Correo', 'Organización'),
        _PayloadType.event => ('Título', 'Inicio: AAAAMMDDTHHMMSS', 'Término: AAAAMMDDTHHMMSS', 'Ubicación'),
        _PayloadType.email => ('Destinatario', 'Asunto', 'Mensaje', null),
        _PayloadType.phone => ('Número telefónico', null, null, null),
        _PayloadType.sms => ('Número telefónico', 'Mensaje', null, null),
        _PayloadType.geo => ('Latitud', 'Longitud', 'Nombre o búsqueda', null),
      };

  Future<void> _copy() async {
    await ClipboardService.copy(_payload, clearAfterSeconds: widget.settings.value.clearClipboardSeconds);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos copiados.')));
  }

  Future<void> _shareSvg() async {
    try {
      final bool twoDimensional = <_CodeFormat>{
        _CodeFormat.qr,
        _CodeFormat.dataMatrix,
        _CodeFormat.aztec,
        _CodeFormat.pdf417,
      }.contains(_format);
      final String svg = _barcode.toSvg(
        _payload,
        width: twoDimensional ? 900 : 1200,
        height: twoDimensional ? 900 : 420,
        drawText: !twoDimensional,
      );
      await SharePlus.instance.share(
        ShareParams(
          title: 'Código ${_formatLabel(_format)}',
          files: <XFile>[
            XFile.fromData(
              Uint8List.fromList(utf8.encode(svg)),
              mimeType: 'image/svg+xml',
            ),
          ],
          fileNameOverrides: <String>['codigo-${_format.name}.svg'],
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No fue posible generar el archivo SVG con estos datos.')),
        );
      }
    }
  }

  Future<void> _sharePng() async {
    final RenderRepaintBoundary? boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return;
    await SharePlus.instance.share(ShareParams(
      title: 'Código generado',
      files: <XFile>[XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png')],
      fileNameOverrides: <String>['codigo-${_format.name}.png'],
    ));
  }

  void _setExamples(_PayloadType value) {
    _secondary.clear();
    _tertiary.clear();
    _quaternary.clear();
    switch (value) {
      case _PayloadType.text:
        _primary.text = 'Texto de ejemplo';
        break;
      case _PayloadType.url:
        _primary.text = 'https://example.com';
        break;
      case _PayloadType.wifi:
        _primary.text = 'Mi red';
        _secondary.text = 'WPA';
        break;
      case _PayloadType.contact:
        _primary.text = 'Nombre Apellido';
        break;
      case _PayloadType.event:
        _primary.text = 'Reunión';
        _secondary.text = '20260803T100000';
        _tertiary.text = '20260803T110000';
        break;
      case _PayloadType.email:
        _primary.text = 'correo@example.com';
        break;
      case _PayloadType.phone:
        _primary.text = '+56912345678';
        break;
      case _PayloadType.sms:
        _primary.text = '+56912345678';
        break;
      case _PayloadType.geo:
        _primary.text = '-33.4489';
        _secondary.text = '-70.6693';
        break;
    }
  }

  static String _payloadLabel(_PayloadType value) => switch (value) {
        _PayloadType.text => 'Texto',
        _PayloadType.url => 'Enlace',
        _PayloadType.wifi => 'Wi-Fi',
        _PayloadType.contact => 'Contacto vCard',
        _PayloadType.event => 'Evento',
        _PayloadType.email => 'Correo',
        _PayloadType.phone => 'Teléfono',
        _PayloadType.sms => 'SMS',
        _PayloadType.geo => 'Ubicación',
      };

  static String _formatLabel(_CodeFormat value) => switch (value) {
        _CodeFormat.qr => 'QR Code',
        _CodeFormat.dataMatrix => 'Data Matrix',
        _CodeFormat.aztec => 'Aztec',
        _CodeFormat.pdf417 => 'PDF417',
        _CodeFormat.code128 => 'Code 128',
        _CodeFormat.code39 => 'Code 39',
        _CodeFormat.ean13 => 'EAN-13',
        _CodeFormat.ean8 => 'EAN-8',
        _CodeFormat.upcA => 'UPC-A',
        _CodeFormat.gs128 => 'GS1-128',
      };

  static String _escape(String value) => value.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(':', r'\:').replaceAll(',', r'\,');
  static String _normalizeUrl(String value) => RegExp(r'^https?://', caseSensitive: false).hasMatch(value.trim()) ? value.trim() : 'https://${value.trim()}';
}
