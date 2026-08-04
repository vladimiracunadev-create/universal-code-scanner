import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_code_scanner/core/security/scan_security_analyzer.dart';
import 'package:universal_code_scanner/models/parsed_content.dart';
import 'package:universal_code_scanner/models/scan_record.dart';
import 'package:universal_code_scanner/services/clipboard_service.dart';
import 'package:universal_code_scanner/state/settings_store.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanResultsSheet extends StatelessWidget {
  const ScanResultsSheet({required this.records, required this.settings, super.key});

  final List<ScanRecord> records;
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                records.length == 1 ? 'Código interpretado' : '${records.length} códigos interpretados',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) => ScanRecordCard(record: records[index], settings: settings),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Continuar escaneando')),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanRecordCard extends StatefulWidget {
  const ScanRecordCard({required this.record, required this.settings, this.compact = false, super.key});

  final ScanRecord record;
  final SettingsStore settings;
  final bool compact;

  @override
  State<ScanRecordCard> createState() => _ScanRecordCardState();
}

class _ScanRecordCardState extends State<ScanRecordCard> {
  bool _revealed = false;

  ScanRecord get record => widget.record;

  @override
  Widget build(BuildContext context) {
    final bool conceal = record.isSensitive && widget.settings.value.hideSensitiveValues && !_revealed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(child: Icon(_iconForKind(record.parsed.kind))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(record.parsed.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${record.format} · ${record.source}'),
                      if (record.parsed.summary?.isNotEmpty == true)
                        Text(record.parsed.summary!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (record.isSensitive)
                  IconButton(
                    tooltip: conceal ? 'Mostrar datos sensibles' : 'Ocultar datos sensibles',
                    onPressed: () => setState(() => _revealed = !_revealed),
                    icon: Icon(conceal ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ...record.parsed.fields.entries.map((MapEntry<String, String> field) {
              final bool sensitiveField = record.parsed.sensitive && <String>{'Contraseña', 'Secreto', 'Dirección', 'IBAN', 'Carga'}.contains(field.key);
              final String value = conceal && sensitiveField ? '••••••••' : field.value;
              if (value.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(field.key, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                    SelectableText(value),
                  ],
                ),
              );
            }),
            if (!widget.compact) ...<Widget>[
              const SizedBox(height: 6),
              _RiskBanner(record: record),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copiar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(_shareRecord(context)),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Compartir'),
                  ),
                  if (_actionUri(record) != null)
                    FilledButton.icon(
                      onPressed: () => unawaited(_openRecord(context)),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(_actionLabel(record.parsed.kind)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await ClipboardService.copy(
      record.rawValue,
      clearAfterSeconds: widget.settings.value.clearClipboardSeconds,
    );
    if (context.mounted) {
      final int seconds = widget.settings.value.clearClipboardSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(seconds <= 0 ? 'Contenido copiado.' : 'Contenido copiado; se borrará en $seconds segundos.'),
        ),
      );
    }
  }

  Future<void> _shareRecord(BuildContext context) async {
    if (record.isSensitive) {
      final bool confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              icon: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Compartir información sensible'),
              content: const Text('El contenido puede incluir contraseñas, secretos, información de pago o identificación. Revisa el destino antes de compartir.'),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Compartir')),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    if (record.parsed.kind == ContentKind.contact || record.parsed.kind == ContentKind.event) {
      final bool contact = record.parsed.kind == ContentKind.contact;
      final String extension = contact ? 'vcf' : 'ics';
      final String mimeType = contact ? 'text/vcard' : 'text/calendar';
      await SharePlus.instance.share(
        ShareParams(
          title: contact ? 'Contacto escaneado' : 'Evento escaneado',
          files: <XFile>[
            XFile.fromData(
              Uint8List.fromList(utf8.encode(record.rawValue)),
              mimeType: mimeType,
            ),
          ],
          fileNameOverrides: <String>['${contact ? 'contacto' : 'evento'}.$extension'],
        ),
      );
      return;
    }
    await SharePlus.instance.share(ShareParams(text: record.rawValue));
  }

  Future<void> _openRecord(BuildContext context) async {
    final Uri? uri = _actionUri(record);
    if (uri == null) return;
    final bool shouldConfirm = widget.settings.value.confirmBeforeOpen || record.riskLevel != RiskLevel.low;
    if (shouldConfirm) {
      final bool confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              icon: Icon(record.riskLevel == RiskLevel.high ? Icons.warning_amber_rounded : Icons.open_in_new),
              title: const Text('Confirmar acción'),
              content: Text(
                record.riskLevel == RiskLevel.high
                    ? 'Se detectaron señales de riesgo. Comprueba cuidadosamente el dominio y los datos antes de continuar.'
                    : 'La aplicación abrirá este contenido mediante una aplicación externa. Revisa los datos antes de continuar.',
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Continuar')),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }
    try {
      final bool opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No existe una aplicación compatible para esta acción.')));
      }
    } on Object {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No fue posible abrir el contenido.')));
    }
  }

  Uri? _actionUri(ScanRecord record) {
    if (record.canOpen) return ScanSecurityAnalyzer.normalizedActionUri(record.rawValue);
    return switch (record.parsed.kind) {
      ContentKind.phone || ContentKind.email || ContentKind.sms || ContentKind.geo => Uri.tryParse(record.rawValue),
      _ => null,
    };
  }

  String _actionLabel(ContentKind kind) => switch (kind) {
        ContentKind.phone => 'Llamar',
        ContentKind.email => 'Correo',
        ContentKind.sms => 'SMS',
        ContentKind.geo => 'Mapa',
        _ => 'Abrir',
      };

  IconData _iconForKind(ContentKind kind) => switch (kind) {
        ContentKind.url => Icons.link,
        ContentKind.wifi => Icons.wifi,
        ContentKind.contact => Icons.person_outline,
        ContentKind.event => Icons.event_outlined,
        ContentKind.email => Icons.email_outlined,
        ContentKind.phone => Icons.phone_outlined,
        ContentKind.sms => Icons.sms_outlined,
        ContentKind.geo => Icons.location_on_outlined,
        ContentKind.otp => Icons.key_outlined,
        ContentKind.gs1 => Icons.qr_code_2,
        ContentKind.isbn => Icons.menu_book_outlined,
        ContentKind.product => Icons.inventory_2_outlined,
        ContentKind.payment => Icons.payments_outlined,
        ContentKind.crypto => Icons.currency_bitcoin,
        ContentKind.identity => Icons.badge_outlined,
        ContentKind.binary => Icons.data_object,
        ContentKind.text => Icons.text_snippet_outlined,
      };
}

class _RiskBanner extends StatelessWidget {
  const _RiskBanner({required this.record});
  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final (Color, Color, IconData) style = switch (record.riskLevel) {
      RiskLevel.low => (colors.primaryContainer, colors.onPrimaryContainer, Icons.verified_user_outlined),
      RiskLevel.caution => (colors.tertiaryContainer, colors.onTertiaryContainer, Icons.info_outline),
      RiskLevel.high => (colors.errorContainer, colors.onErrorContainer, Icons.warning_amber_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: style.$1, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(style.$3, color: style.$2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(record.riskLevel == RiskLevel.low ? 'Sin señales evidentes' : record.riskLevel == RiskLevel.caution ? 'Revisar antes de continuar' : 'Riesgo elevado', style: TextStyle(color: style.$2, fontWeight: FontWeight.w700)),
                for (final String reason in record.riskReasons) Text('• $reason', style: TextStyle(color: style.$2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
