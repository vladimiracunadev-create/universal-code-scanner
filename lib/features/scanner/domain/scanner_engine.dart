import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Stable boundary around the current scanner package. New engines can be added
/// without changing history, inventory, result, or persistence code.
abstract interface class ScannerEngine {
  MobileScannerController get controller;
  ValueListenable<MobileScannerState> get state;
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
  Future<void> toggleTorch();
  Future<void> switchCamera();
  Future<void> setZoomScale(double value);
  Future<BarcodeCapture?> analyzeImage(String path);
}
