import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:universal_code_scanner/features/scanner/domain/scanner_engine.dart';

class MobileScannerEngine implements ScannerEngine {
  MobileScannerEngine({required bool torchEnabled})
      : _controller = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          formats: const <BarcodeFormat>[],
          invertImage: true,
          autoZoom: true,
          torchEnabled: torchEnabled,
          returnImage: false,
        );

  final MobileScannerController _controller;

  @override
  MobileScannerController get controller => _controller;
  @override
  ValueListenable<MobileScannerState> get state => _controller;
  @override
  Future<BarcodeCapture?> analyzeImage(String path) => _controller.analyzeImage(path);
  @override
  Future<void> dispose() => _controller.dispose();
  @override
  Future<void> setZoomScale(double value) => _controller.setZoomScale(value);
  @override
  Future<void> start() => _controller.start();
  @override
  Future<void> stop() => _controller.stop();
  @override
  Future<void> switchCamera() => _controller.switchCamera();
  @override
  Future<void> toggleTorch() => _controller.toggleTorch();
}
