import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:universal_code_scanner/features/scanner/widgets/scan_status_bar.dart';
import 'package:universal_code_scanner/models/inventory_session.dart';
import 'package:universal_code_scanner/models/scan_record.dart';
import 'package:universal_code_scanner/services/export_service.dart';
import 'package:universal_code_scanner/services/import_service.dart';
import 'package:universal_code_scanner/services/scan_feedback.dart';
import 'package:universal_code_scanner/state/inventory_store.dart';
import 'package:universal_code_scanner/state/settings_store.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({required this.store, required this.settings, super.key});

  final InventoryStore store;
  final SettingsStore settings;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
  final ScanFeedback _feedback = ScanFeedback();
  late MobileScannerController _controller;
  Key _previewKey = UniqueKey();
  bool _paused = false;
  String? _lastCode;
  DateTime? _lastAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_refresh);
    _createController();
  }

  void _createController() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const <BarcodeFormat>[],
      autoZoom: true,
      invertImage: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_refresh);
    _nameController.dispose();
    unawaited(_controller.dispose());
    unawaited(_feedback.dispose());
    super.dispose();
  }

  /// A controller passed by hand opts out of the lifecycle handling built into
  /// `MobileScanner`, so returning from the background has to be handled here
  /// or the preview comes back frozen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.store.activeSession == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_paused) unawaited(_startCamera());
      case AppLifecycleState.inactive:
        unawaited(_stopCamera());
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _startCamera() async {
    try {
      await _controller.start();
    } on Object {
      // The status bar already offers the restart action.
    }
    if (mounted) setState(() {});
  }

  Future<void> _stopCamera() async {
    try {
      await _controller.stop();
    } on Object {
      // Stopping a camera that never started is not an error here.
    }
    if (mounted) setState(() {});
  }

  Future<void> _restartCamera() async {
    await _stopCamera();
    try {
      await _controller.dispose();
    } on Object {
      // An already disposed controller is the state we want.
    }
    if (!mounted) return;
    setState(() {
      _createController();
      _previewKey = UniqueKey();
      _paused = false;
    });
  }

  Future<void> _togglePause() async {
    if (_paused) {
      if (mounted) setState(() => _paused = false);
      await _startCamera();
      return;
    }
    await _stopCamera();
    if (mounted) setState(() => _paused = true);
  }

  void _refresh() => mounted ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) {
    final InventorySession? active = widget.store.activeSession;
    return active == null ? _buildSessions(context) : _buildActive(context, active);
  }

  Widget _buildSessions(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Inventario continuo', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre de la sesión', hintText: 'Ej.: Bodega central agosto')),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await widget.store.createSession(_nameController.text);
                        _nameController.clear();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Iniciar inventario'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(onPressed: _importInventory, icon: const Icon(Icons.upload_file_outlined), label: const Text('Importar JSON')),
          ),
        ),
        Expanded(
          child: widget.store.sessions.isEmpty
              ? const Center(child: Text('Aún no existen sesiones de inventario.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: widget.store.sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final InventorySession session = widget.store.sessions[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(session.isOpen ? Icons.inventory : Icons.inventory_2_outlined),
                        title: Text(session.name),
                        subtitle: Text('${session.items.length} códigos · ${session.totalUnits} unidades · ${_formatDate(session.createdAt)}'),
                        onTap: session.isOpen ? () => widget.store.activate(session.id) : null,
                        trailing: PopupMenuButton<String>(
                          onSelected: (String value) {
                            if (value == 'csv') unawaited(ExportService.shareInventoryCsv(session));
                            if (value == 'json') unawaited(ExportService.shareInventoryJson(session));
                            if (value == 'xlsx') unawaited(ExportService.shareInventoryXlsx(session));
                            if (value == 'reopen') unawaited(widget.store.reopenSession(session.id));
                            if (value == 'delete') unawaited(widget.store.deleteSession(session.id));
                          },
                          itemBuilder: (_) => <PopupMenuEntry<String>>[
                            const PopupMenuItem(value: 'csv', child: Text('Exportar CSV')),
                            const PopupMenuItem(value: 'json', child: Text('Exportar JSON')),
                            const PopupMenuItem(value: 'xlsx', child: Text('Exportar Excel XLSX')),
                            if (!session.isOpen) const PopupMenuItem(value: 'reopen', child: Text('Reabrir sesión')),
                            const PopupMenuDivider(),
                            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
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

  Widget _buildActive(BuildContext context, InventorySession session) {
    final List<InventoryItem> items = session.items.values.toList()
      ..sort((InventoryItem a, InventoryItem b) => b.lastScannedAt.compareTo(a.lastScannedAt));
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(session.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text('${session.items.length} códigos únicos · ${session.totalUnits} unidades'),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Exportar CSV',
                onPressed: () => _showExportMenu(session),
                icon: const Icon(Icons.ios_share_outlined),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(onPressed: _closeSession, child: const Text('Cerrar')),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Rect scanWindow = Rect.fromCenter(
                    center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                    width: constraints.maxWidth.clamp(180, 260).toDouble(),
                    height: 120,
                  );
                  return ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (BuildContext context, MobileScannerState state, Widget? child) {
                      final ScanPhase phase = state.error != null
                          ? ScanPhase.unavailable
                          : _paused
                              ? ScanPhase.paused
                              : state.isRunning
                                  ? ScanPhase.scanning
                                  : ScanPhase.starting;
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          MobileScanner(
                            key: _previewKey,
                            controller: _controller,
                            scanWindow: widget.settings.value.useScanWindow ? scanWindow : null,
                            tapToFocus: true,
                            onDetect: _onDetect,
                          ),
                          if (widget.settings.value.useScanWindow)
                            Center(
                              child: Container(
                                width: scanWindow.width,
                                height: scanWindow.height,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: phase == ScanPhase.scanning ? Theme.of(context).colorScheme.primary : Colors.white70,
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 10,
                            child: ScanStatusBar(
                              phase: phase,
                              message: switch (phase) {
                                ScanPhase.scanning => 'Cada código leído suma una unidad.',
                                ScanPhase.starting => 'Preparando la cámara del inventario.',
                                ScanPhase.paused => 'Reanuda para seguir sumando unidades.',
                                ScanPhase.unavailable => 'Revisa el permiso de cámara y reinicia la lectura.',
                              },
                              animate: !widget.settings.value.reduceMotion,
                              actionLabel: switch (phase) {
                                ScanPhase.paused => 'Reanudar',
                                ScanPhase.unavailable => 'Reintentar',
                                ScanPhase.starting || ScanPhase.scanning => null,
                              },
                              onAction: switch (phase) {
                                ScanPhase.paused => _togglePause,
                                ScanPhase.unavailable => _restartCamera,
                                ScanPhase.starting || ScanPhase.scanning => null,
                              },
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Column(
                              children: <Widget>[
                                IconButton.filled(
                                  tooltip: 'Linterna',
                                  onPressed: _controller.toggleTorch,
                                  icon: const Icon(Icons.flashlight_on_outlined),
                                ),
                                const SizedBox(height: 8),
                                IconButton.filled(
                                  tooltip: phase == ScanPhase.scanning ? 'Pausar lectura' : 'Reanudar lectura',
                                  onPressed: _togglePause,
                                  icon: Icon(phase == ScanPhase.scanning ? Icons.pause : Icons.play_arrow),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Escanea el primer producto para comenzar.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final InventoryItem item = items[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${item.quantity}')),
                        title: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${item.format}\n${item.code}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              tooltip: 'Restar una unidad',
                              onPressed: () => widget.store.setQuantity(item.code, item.quantity - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            IconButton(
                              tooltip: 'Sumar una unidad',
                              onPressed: () => widget.store.setQuantity(item.code, item.quantity + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (String value) {
                                if (value == 'notes') unawaited(_editItemNotes(item));
                                if (value == 'delete') unawaited(widget.store.setQuantity(item.code, 0));
                              },
                              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                PopupMenuItem(value: 'notes', child: Text('Editar nota')),
                                PopupMenuItem(value: 'delete', child: Text('Quitar del inventario')),
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

  void _onDetect(BarcodeCapture capture) {
    if (_paused) return;
    final DateTime now = DateTime.now();
    for (final Barcode barcode in capture.barcodes) {
      final String raw = ScanRecord.payloadForBarcode(barcode);
      if (raw.isEmpty) continue;
      if (_lastCode == raw && _lastAt != null && now.difference(_lastAt!) < const Duration(milliseconds: 1200)) continue;
      _lastCode = raw;
      _lastAt = now;
      final ScanRecord record = ScanRecord.fromBarcode(barcode, source: 'Inventario', scannedAt: now);
      unawaited(widget.store.addScan(record));
      unawaited(_feedback.success(
        sound: widget.settings.value.soundEnabled,
        vibration: widget.settings.value.vibrationEnabled,
      ));
    }
  }



  Future<void> _importInventory() async {
    try {
      final InventoryImportPreview? preview = await ImportService.pickInventoryJson();
      if (preview == null || !mounted) return;
      final bool confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Vista previa de inventario'),
              content: Text(
                'Archivo: ${preview.fileName}\n'
                'Esquema: ${preview.schemaVersion}${preview.legacy ? ' (formato anterior)' : ''}\n'
                'Sesión: ${preview.session.name}\n'
                'Productos: ${preview.session.items.length}',
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Importar como copia')),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
      await widget.store.importSession(preview.session);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventario importado correctamente.')));
    } on Object {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El archivo de inventario no es válido.')));
    }
  }

  Future<void> _showExportMenu(InventorySession session) async {
    final String? format = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(leading: const Icon(Icons.table_view_outlined), title: const Text('Excel XLSX'), onTap: () => Navigator.of(context).pop('xlsx')),
            ListTile(leading: const Icon(Icons.grid_on_outlined), title: const Text('CSV'), onTap: () => Navigator.of(context).pop('csv')),
            ListTile(leading: const Icon(Icons.data_object), title: const Text('JSON'), onTap: () => Navigator.of(context).pop('json')),
          ],
        ),
      ),
    );
    if (format == 'xlsx') await ExportService.shareInventoryXlsx(session);
    if (format == 'csv') await ExportService.shareInventoryCsv(session);
    if (format == 'json') await ExportService.shareInventoryJson(session);
  }

  Future<void> _editItemNotes(InventoryItem item) async {
    final TextEditingController controller = TextEditingController(text: item.notes);
    final bool saved = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Nota del producto'),
            content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(hintText: 'Ubicación, estado u observaciones')),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Guardar')),
            ],
          ),
        ) ??
        false;
    if (saved) await widget.store.updateItemNotes(item.code, controller.text);
    controller.dispose();
  }

  Future<void> _closeSession() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Cerrar inventario'),
            content: const Text('La sesión quedará guardada y podrá exportarse, pero ya no aceptará nuevas lecturas.'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cerrar sesión')),
            ],
          ),
        ) ??
        false;
    if (confirmed) await widget.store.closeActive();
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
