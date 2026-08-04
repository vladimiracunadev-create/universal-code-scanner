import 'dart:async';

import 'package:flutter/material.dart';
import 'package:universal_code_scanner/core/security/scan_security_analyzer.dart';
import 'package:universal_code_scanner/features/result/scan_result_sheet.dart';
import 'package:universal_code_scanner/models/scan_record.dart';
import 'package:universal_code_scanner/services/export_service.dart';
import 'package:universal_code_scanner/services/import_service.dart';
import 'package:universal_code_scanner/state/scan_store.dart';
import 'package:universal_code_scanner/state/settings_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.store, required this.settings, super.key});

  final ScanStore store;
  final SettingsStore settings;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  RiskLevel? _risk;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => mounted ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<ScanRecord> records = widget.store.history.where((ScanRecord item) {
      final bool matchesSearch = query.isEmpty ||
          item.rawValue.toLowerCase().contains(query) ||
          item.contentType.toLowerCase().contains(query) ||
          item.format.toLowerCase().contains(query) ||
          item.tags.any((String tag) => tag.toLowerCase().contains(query)) ||
          item.notes.toLowerCase().contains(query);
      return matchesSearch && (_risk == null || item.riskLevel == _risk) && (!_favoritesOnly || item.favorite);
    }).toList(growable: false);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Historial seguro', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      '${records.length} visibles · ${widget.store.history.where((ScanRecord item) => item.favorite).length} favoritos · ${widget.store.history.where((ScanRecord item) => item.riskLevel == RiskLevel.high).length} de riesgo alto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Exportar o limpiar',
                onSelected: (String value) {
                  if (value == 'csv') unawaited(ExportService.shareHistoryCsv(records));
                  if (value == 'json') unawaited(ExportService.shareHistoryJson(records));
                  if (value == 'xlsx') unawaited(ExportService.shareHistoryXlsx(records));
                  if (value == 'import') unawaited(_importHistory());
                  if (value == 'clear') unawaited(_clearHistory());
                },
                itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem(value: 'csv', child: Text('Exportar CSV')),
                  PopupMenuItem(value: 'json', child: Text('Exportar JSON')),
                  PopupMenuItem(value: 'xlsx', child: Text('Exportar Excel XLSX')),
                  PopupMenuItem(value: 'import', child: Text('Importar respaldo JSON')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'clear', child: Text('Borrar historial')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar contenido, formato, nota o etiqueta', border: OutlineInputBorder()),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              FilterChip(
                label: const Text('Favoritos'),
                selected: _favoritesOnly,
                onSelected: (bool value) => setState(() => _favoritesOnly = value),
              ),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Todos'), selected: _risk == null, onSelected: (_) => setState(() => _risk = null)),
              const SizedBox(width: 8),
              for (final RiskLevel level in RiskLevel.values) ...<Widget>[
                ChoiceChip(
                  label: Text(level == RiskLevel.low ? 'Bajo' : level == RiskLevel.caution ? 'Precaución' : 'Alto'),
                  selected: _risk == level,
                  onSelected: (_) => setState(() => _risk = level),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: records.isEmpty
              ? const Center(child: Text('No hay lecturas que coincidan con los filtros.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final ScanRecord item = records[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(_riskIcon(item.riskLevel)),
                        title: Text(item.parsed.summary?.isNotEmpty == true ? item.parsed.summary! : item.contentType, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${item.format} · ${_formatDate(item.scannedAt)}\n${item.rawValue}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        onTap: () => _showDetails(item),
                        trailing: Wrap(
                          spacing: 0,
                          children: <Widget>[
                            IconButton(
                              tooltip: item.favorite ? 'Quitar favorito' : 'Marcar favorito',
                              onPressed: () => widget.store.toggleFavorite(item.id),
                              icon: Icon(item.favorite ? Icons.star : Icons.star_border),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (String value) {
                                if (value == 'edit') unawaited(_edit(item));
                                if (value == 'delete') unawaited(widget.store.remove(item.id));
                              },
                              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                PopupMenuItem(value: 'edit', child: Text('Notas y etiquetas')),
                                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showDetails(ScanRecord record) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: ScanRecordCard(record: record, settings: widget.settings)),
        ),
      ),
    );
  }

  Future<void> _edit(ScanRecord record) async {
    final TextEditingController notes = TextEditingController(text: record.notes);
    final TextEditingController tags = TextEditingController(text: record.tags.join(', '));
    final bool saved = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Notas y etiquetas'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notas')),
                const SizedBox(height: 12),
                TextField(controller: tags, decoration: const InputDecoration(labelText: 'Etiquetas separadas por comas')),
              ],
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Guardar')),
            ],
          ),
        ) ??
        false;
    if (saved) {
      await widget.store.update(record.copyWith(
        notes: notes.text.trim(),
        tags: tags.text.split(',').map((String value) => value.trim()).where((String value) => value.isNotEmpty).toSet().toList(),
      ));
    }
    notes.dispose();
    tags.dispose();
  }


  Future<void> _importHistory() async {
    try {
      final HistoryImportPreview? preview = await ImportService.pickHistoryJson(existingIds: widget.store.ids);
      if (preview == null || !mounted) return;
      final ImportStrategy? strategy = await showDialog<ImportStrategy>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Vista previa de importación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Archivo: ${preview.fileName}'),
              Text('Esquema: ${preview.schemaVersion}${preview.legacy ? ' (formato anterior)' : ''}'),
              Text('Registros válidos: ${preview.valid}'),
              Text('Duplicados: ${preview.duplicates}'),
              Text('Rechazados: ${preview.rejected}'),
              const SizedBox(height: 12),
              const Text('La base existente no se modifica hasta elegir una estrategia.'),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(context).pop(ImportStrategy.skipDuplicates), child: const Text('Omitir duplicados')),
            TextButton(onPressed: () => Navigator.of(context).pop(ImportStrategy.merge), child: const Text('Combinar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(ImportStrategy.replace), child: const Text('Reemplazar')),
          ],
        ),
      );
      if (strategy == null) return;
      final int imported = await widget.store.importPreview(preview, strategy);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$imported lecturas importadas.')));
    } on Object {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El respaldo no es válido o no pudo leerse.')));
    }
  }

  Future<void> _clearHistory() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Borrar historial'),
            content: const Text('Esta acción eliminará todas las lecturas guardadas en la base local.'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Borrar')),
            ],
          ),
        ) ??
        false;
    if (confirmed) await widget.store.clear();
  }

  IconData _riskIcon(RiskLevel level) => switch (level) {
        RiskLevel.low => Icons.verified_user_outlined,
        RiskLevel.caution => Icons.info_outline,
        RiskLevel.high => Icons.warning_amber_rounded,
      };

  String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }
}
