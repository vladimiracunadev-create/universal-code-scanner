import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:universal_code_scanner/core/localization/app_localizations.dart';
import 'package:universal_code_scanner/core/performance/cancellation_token.dart';
import 'package:universal_code_scanner/features/result/scan_result_sheet.dart';
import 'package:universal_code_scanner/features/scanner/data/mobile_scanner_engine.dart';
import 'package:universal_code_scanner/features/scanner/domain/scanner_engine.dart';
import 'package:universal_code_scanner/features/scanner/widgets/scan_status_bar.dart';
import 'package:universal_code_scanner/features/scanner/widgets/scanner_overlay.dart';
import 'package:universal_code_scanner/models/app_settings.dart';
import 'package:universal_code_scanner/models/scan_record.dart';
import 'package:universal_code_scanner/services/pdf_page_renderer.dart';
import 'package:universal_code_scanner/services/scan_feedback.dart';
import 'package:universal_code_scanner/state/scan_store.dart';
import 'package:universal_code_scanner/state/settings_store.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({required this.store, required this.settings, super.key});

  final ScanStore store;
  final SettingsStore settings;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  late ScannerEngine _engine;
  final ImagePicker _imagePicker = ImagePicker();
  final ScanFeedback _feedback = ScanFeedback();

  /// Rebuilding the [MobileScanner] with a new key forces it to attach to the
  /// freshly created controller. A controller that failed to start cannot be
  /// reused, so "restart the camera" means "build a new one".
  Key _previewKey = UniqueKey();

  bool _handlingResult = false;
  bool _paused = false;
  String? _startFailure;
  String? _lastSignature;
  DateTime? _lastDetectedAt;
  double _zoom = 0;

  AppSettings get _settings => widget.settings.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createEngine();
  }

  void _createEngine() {
    _engine = MobileScannerEngine(torchEnabled: _settings.autoTorch);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_engine.dispose());
    unawaited(_feedback.dispose());
    super.dispose();
  }

  /// The scanner owns its controller, so `MobileScanner` deliberately leaves
  /// lifecycle handling to this screen. Without this, coming back from the
  /// background — or from the system camera permission dialog — left the
  /// preview frozen with no way to recover other than leaving the tab.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_paused && !_handlingResult) unawaited(_startCamera());
      case AppLifecycleState.inactive:
        unawaited(_stopCamera());
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Every call into the controller can throw: it may be disposed, still
  /// starting, or not yet attached to a widget. A failure here must leave the
  /// screen in a state the user can act on, never in an exception.
  Future<void> _startCamera() async {
    try {
      await _engine.start();
      if (mounted) setState(() => _startFailure = null);
    } on MobileScannerException catch (error) {
      if (mounted) setState(() => _startFailure = _describe(error));
    } on Object {
      if (mounted) setState(() => _startFailure = 'No fue posible iniciar la cámara.');
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _engine.stop();
    } on Object {
      // Stopping an already stopped or disposed camera is not an error here.
    }
  }

  String _describe(MobileScannerException error) => switch (error.errorCode) {
        MobileScannerErrorCode.permissionDenied =>
          'Falta el permiso de cámara. Actívalo en los ajustes del sistema y vuelve a intentarlo.',
        MobileScannerErrorCode.unsupported => 'Este dispositivo no permite leer códigos con la cámara.',
        _ => 'La cámara no pudo iniciarse. Toca «Reintentar».',
      };

  /// Replaces the controller and the preview widget. This is the recovery path
  /// offered to the user whenever the camera does not come up.
  Future<void> _restartCamera() async {
    // The old controller is released before the new one exists: both share a
    // single platform camera session, and disposing it afterwards would tear
    // down the session the new controller has just claimed.
    await _stopCamera();
    try {
      await _engine.dispose();
    } on Object {
      // An already disposed controller is exactly the state we want.
    }
    if (!mounted) return;
    setState(() {
      _createEngine();
      _previewKey = UniqueKey();
      _startFailure = null;
      _paused = false;
      _zoom = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(context.strings.scannerTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(context.strings.scannerSubtitle),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Importar imágenes o PDF',
                enabled: !kIsWeb,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                onSelected: (String value) {
                  if (value == 'images') unawaited(_scanFromGallery());
                  if (value == 'pdf') unawaited(_scanFromPdf());
                },
                itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'images',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.collections_outlined),
                      title: Text('Varias imágenes'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'pdf',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.picture_as_pdf_outlined),
                      title: Text('Documento PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double side = math.min(constraints.maxWidth, constraints.maxHeight) * 0.68;
                  final Rect window = Rect.fromCenter(
                    center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                    width: side,
                    height: side,
                  );
                  return ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _engine.state,
                    builder: (BuildContext context, MobileScannerState state, Widget? child) {
                      final ScanPhase phase = _phaseFor(state);
                      final bool scanning = phase == ScanPhase.scanning;
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          MobileScanner(
                            key: _previewKey,
                            controller: _engine.controller,
                            scanWindow: _settings.useScanWindow ? window : null,
                            // No threshold: the scan window is recalculated from
                            // the camera output size and the device orientation,
                            // both of which can arrive after the first frame. A
                            // threshold froze the first — sometimes wrong —
                            // window, and every code outside it was ignored
                            // until the screen was rebuilt from scratch.
                            tapToFocus: true,
                            onDetect: (BarcodeCapture capture) => unawaited(_handleCapture(capture, source: 'Cámara')),
                            errorBuilder: (BuildContext context, MobileScannerException error) =>
                                _ScannerError(error: error, onRetry: _restartCamera),
                          ),
                          if (_settings.useScanWindow && phase != ScanPhase.unavailable)
                            ScannerOverlay(
                              scanWindow: window,
                              active: scanning,
                              animate: !_settings.reduceMotion,
                            ),
                          if (phase == ScanPhase.paused)
                            // A dimmed preview is not a control: tapping
                            // anywhere resumes, the way every camera app does.
                            // The unavailable state keeps its own retry button
                            // visible instead of covering it with this layer.
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _resumeScanning,
                                child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                              ),
                            ),
                          Positioned(
                            top: 18,
                            left: 18,
                            right: 18,
                            child: ScanStatusBar(
                              phase: phase,
                              message: _messageFor(phase),
                              animate: !_settings.reduceMotion,
                              actionLabel: switch (phase) {
                                ScanPhase.paused => 'Reanudar escaneo',
                                ScanPhase.unavailable => 'Reintentar',
                                ScanPhase.starting || ScanPhase.scanning => null,
                              },
                              onAction: switch (phase) {
                                ScanPhase.paused => _resumeScanning,
                                ScanPhase.unavailable => () => unawaited(_restartCamera()),
                                ScanPhase.starting || ScanPhase.scanning => null,
                              },
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 82,
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.zoom_out, color: Colors.white),
                                Expanded(
                                  child: Slider(
                                    value: _zoom,
                                    onChanged: (double value) {
                                      setState(() => _zoom = value);
                                      unawaited(_engine.setZoomScale(value));
                                    },
                                  ),
                                ),
                                const Icon(Icons.zoom_in, color: Colors.white),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 18,
                            // Wrap, not Row: with large controls or a big text
                            // scale these four actions do not fit on one line,
                            // and a second line is better than a clipped one.
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10,
                              runSpacing: 8,
                              children: <Widget>[
                                _CameraButton(
                                  tooltip: 'Linterna',
                                  onPressed: state.torchState == TorchState.unavailable ? null : _engine.toggleTorch,
                                  icon: state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                                ),
                                FilledButton.icon(
                                  onPressed: _togglePause,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: scanning ? Colors.white : Theme.of(context).colorScheme.primary,
                                    foregroundColor: scanning ? Colors.black : Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  icon: Icon(scanning ? Icons.pause : Icons.play_arrow),
                                  label: Text(scanning ? 'Pausar' : 'Escanear'),
                                ),
                                _CameraButton(
                                  tooltip: 'Cambiar cámara',
                                  onPressed: () => _engine.switchCamera(),
                                  icon: Icons.cameraswitch_outlined,
                                ),
                                _CameraButton(
                                  tooltip: 'Reiniciar cámara',
                                  onPressed: _restartCamera,
                                  icon: Icons.refresh,
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
      ],
    );
  }

  ScanPhase _phaseFor(MobileScannerState state) {
    if (_startFailure != null || state.error != null) return ScanPhase.unavailable;
    if (_paused || _handlingResult) return ScanPhase.paused;
    if (state.isRunning) return ScanPhase.scanning;
    return ScanPhase.starting;
  }

  String _messageFor(ScanPhase phase) => switch (phase) {
        ScanPhase.starting => 'Preparando el enfoque. Si no aparece la imagen, toca «Reiniciar cámara».',
        ScanPhase.scanning => _settings.useScanWindow
            ? 'Alinea uno o varios códigos dentro del marco.'
            : 'Apunta la cámara hacia uno o varios códigos.',
        ScanPhase.paused => 'La cámara no está leyendo. Toca la pantalla para continuar.',
        ScanPhase.unavailable => _startFailure ?? 'Revisa el permiso de cámara y vuelve a intentarlo.',
      };

  Future<void> _resumeScanning() async {
    if (mounted) setState(() => _paused = false);
    await _startCamera();
  }

  Future<void> _togglePause() async {
    if (_paused) {
      await _resumeScanning();
      return;
    }
    await _stopCamera();
    if (mounted) setState(() => _paused = true);
  }

  Future<void> _scanFromGallery() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(limit: 20);
    if (images.isEmpty || !mounted) return;
    final CancellationToken token = CancellationToken();
    final BatchProgress progress = BatchProgress(label: 'Preparando imágenes')..update(total: images.length);
    try {
      final List<ScanRecord> all = await _runBatchDialog<List<ScanRecord>>(
        progress: progress,
        token: token,
        operation: () async {
          final List<ScanRecord> records = <ScanRecord>[];
          await _stopCamera();
          try {
            for (int index = 0; index < images.length; index++) {
              token.throwIfCancelled();
              progress.update(label: 'Analizando imagen ${index + 1} de ${images.length}', current: index);
              final BarcodeCapture? capture = await _engine.analyzeImage(images[index].path);
              if (capture != null) {
                final Map<String, Barcode> unique = <String, Barcode>{};
                for (final Barcode barcode in capture.barcodes) {
                  final String raw = ScanRecord.payloadForBarcode(barcode);
                  if (raw.isNotEmpty) unique.putIfAbsent(raw, () => barcode);
                }
                records.addAll(unique.values.map((Barcode barcode) => ScanRecord.fromBarcode(barcode, source: 'Imagen')));
              }
              progress.update(current: index + 1);
              await Future<void>.delayed(Duration.zero);
            }
            token.throwIfCancelled();
            return records;
          } finally {
            if (mounted && !_paused) await _startCamera();
          }
        },
      );
      if (!mounted) return;
      if (all.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontraron códigos compatibles.')));
      } else {
        await _persistAndShow(all);
      }
    } on OperationCancelledException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Análisis cancelado sin modificar el historial.')));
    } on Object {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No fue posible analizar una o más imágenes.')));
    }
  }

  Future<void> _scanFromPdf() async {
    if (kIsWeb) return;
    final CancellationToken token = CancellationToken();
    final BatchProgress progress = BatchProgress(label: 'Seleccionando documento');
    final List<RenderedPdfPage> pages = <RenderedPdfPage>[];
    try {
      final List<ScanRecord> records = await _runBatchDialog<List<ScanRecord>>(
        progress: progress,
        token: token,
        operation: () async {
          final List<ScanRecord> found = <ScanRecord>[];
          await _stopCamera();
          try {
            pages.addAll(await PdfPageRenderer.pickAndRender(
              maxPages: 50,
              cancellationToken: token,
              onProgress: (int current, int total) => progress.update(
                label: 'Renderizando página $current de $total',
                current: current,
                total: total * 2,
              ),
            ));
            for (int index = 0; index < pages.length; index++) {
              token.throwIfCancelled();
              final RenderedPdfPage page = pages[index];
              progress.update(
                label: 'Buscando códigos en página ${page.pageNumber}',
                current: pages.length + index,
                total: pages.length * 2,
              );
              final BarcodeCapture? capture = await _engine.analyzeImage(page.imagePath);
              if (capture != null) {
                final Map<String, Barcode> uniqueOnPage = <String, Barcode>{};
                for (final Barcode barcode in capture.barcodes) {
                  final String raw = ScanRecord.payloadForBarcode(barcode);
                  if (raw.isNotEmpty) uniqueOnPage.putIfAbsent(raw, () => barcode);
                }
                final DateTime scannedAt = DateTime.now();
                found.addAll(uniqueOnPage.values.map((Barcode barcode) => ScanRecord.fromBarcode(
                      barcode,
                      source: 'PDF · página ${page.pageNumber}',
                      scannedAt: scannedAt,
                    )));
              }
              progress.update(current: pages.length + index + 1);
              await Future<void>.delayed(Duration.zero);
            }
            token.throwIfCancelled();
            return found;
          } finally {
            await PdfPageRenderer.cleanup(pages);
            if (mounted && !_paused) await _startCamera();
          }
        },
      );
      if (!mounted) return;
      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontraron códigos en las páginas analizadas.')));
      } else {
        await _persistAndShow(records);
      }
    } on OperationCancelledException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Análisis de PDF cancelado sin modificar el historial.')));
    } on Object {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No fue posible analizar el documento PDF.')));
    }
  }

  Future<T> _runBatchDialog<T>({
    required BatchProgress progress,
    required CancellationToken token,
    required Future<T> Function() operation,
  }) async {
    bool dialogOpen = true;
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final Future<void> dialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _BatchProgressDialog(progress: progress, token: token),
    ).whenComplete(() => dialogOpen = false);
    await Future<void>.delayed(Duration.zero);
    try {
      return await operation();
    } finally {
      if (dialogOpen && navigator.mounted) navigator.pop();
      await dialog;
      progress.dispose();
      token.dispose();
    }
  }

  Future<void> _handleCapture(BarcodeCapture capture, {required String source}) async {
    if (_handlingResult || _paused || !mounted) return;
    final Map<String, Barcode> unique = <String, Barcode>{};
    for (final Barcode barcode in capture.barcodes) {
      final String raw = ScanRecord.payloadForBarcode(barcode);
      if (raw.isNotEmpty) unique.putIfAbsent(raw, () => barcode);
    }
    if (unique.isEmpty) return;

    final List<String> signature = unique.keys.toList()..sort();
    final String joined = signature.join('|');
    final DateTime now = DateTime.now();
    if (_lastSignature == joined && _lastDetectedAt != null && now.difference(_lastDetectedAt!) < const Duration(seconds: 2)) return;
    _lastSignature = joined;
    _lastDetectedAt = now;
    if (mounted) setState(() => _handlingResult = true);

    try {
      await _stopCamera();
      await _feedback.success(sound: _settings.soundEnabled, vibration: _settings.vibrationEnabled);
      final List<ScanRecord> records = unique.values
          .map((Barcode barcode) => ScanRecord.fromBarcode(barcode, source: source, scannedAt: now))
          .toList(growable: false);
      await _persistAndShow(records);
    } finally {
      if (mounted) setState(() => _handlingResult = false);
      if (mounted && !_paused) await _startCamera();
    }
  }

  Future<void> _persistAndShow(List<ScanRecord> records) async {
    if (_settings.saveHistory && !_settings.privateMode) {
      final List<ScanRecord> persistent = records.where((ScanRecord record) => !record.isSensitive).toList(growable: false);
      await widget.store.addAll(persistent);
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (BuildContext context) => ScanResultsSheet(records: records, settings: widget.settings),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.tooltip, required this.onPressed, required this.icon});
  final String tooltip;
  final Future<void> Function()? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed == null ? null : () => unawaited(onPressed!()),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.black.withValues(alpha: 0.35),
      ),
      icon: Icon(icon),
    );
  }
}

class _BatchProgressDialog extends StatelessWidget {
  const _BatchProgressDialog({required this.progress, required this.token});
  final BatchProgress progress;
  final CancellationToken token;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Procesando localmente'),
      content: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[progress, token]),
        builder: (BuildContext context, Widget? child) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LinearProgressIndicator(value: progress.fraction),
            const SizedBox(height: 12),
            Text(progress.label, textAlign: TextAlign.center),
            if (progress.total > 0) Text('${progress.current}/${progress.total}', textAlign: TextAlign.center),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: token.isCancelled ? null : token.cancel,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, required this.onRetry});
  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.no_photography_outlined, size: 54),
              const SizedBox(height: 14),
              Text('No se pudo iniciar la cámara', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                error.errorCode == MobileScannerErrorCode.permissionDenied
                    ? 'Concede el permiso de cámara en los ajustes del sistema y vuelve a intentarlo.'
                    : 'Cierra otras aplicaciones que estén usando la cámara y reinicia la lectura.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => unawaited(onRetry()),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
