import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_code_scanner/features/scanner/widgets/scan_status_bar.dart';
import 'package:universal_code_scanner/features/scanner/widgets/scanner_overlay.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required ScanPhase phase,
    bool animate = true,
    VoidCallback? onAction,
    String? actionLabel,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScanStatusBar(
          phase: phase,
          message: 'Mensaje de estado',
          animate: animate,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    ));
    // Never pumpAndSettle: while it is scanning the bar animates forever, which
    // is exactly the state under test.
    await tester.pump();
  }

  LinearProgressIndicator indicator(WidgetTester tester) =>
      tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));

  testWidgets('while scanning the bar moves and says so', (WidgetTester tester) async {
    await pumpBar(tester, phase: ScanPhase.scanning);

    expect(find.text('Escaneando'), findsOneWidget);
    // A null value is the indeterminate, moving bar.
    expect(indicator(tester).value, isNull);
  });

  testWidgets('reduced motion keeps the bar readable without movement', (WidgetTester tester) async {
    await pumpBar(tester, phase: ScanPhase.scanning, animate: false);

    expect(find.text('Escaneando'), findsOneWidget);
    expect(indicator(tester).value, 1);
  });

  testWidgets('a paused camera is announced and offers the way back', (WidgetTester tester) async {
    int taps = 0;
    await pumpBar(
      tester,
      phase: ScanPhase.paused,
      actionLabel: 'Reanudar escaneo',
      onAction: () => taps++,
    );

    expect(find.text('Escaneo en pausa'), findsOneWidget);
    expect(indicator(tester).value, 0);

    await tester.tap(find.text('Reanudar escaneo'));
    expect(taps, 1);
  });

  testWidgets('a camera that could not start is named as such', (WidgetTester tester) async {
    await pumpBar(tester, phase: ScanPhase.unavailable);

    expect(find.text('Cámara no disponible'), findsOneWidget);
    expect(find.text('Mensaje de estado'), findsOneWidget);
  });

  testWidgets('the frame only sweeps while the camera is analysing frames', (WidgetTester tester) async {
    Future<void> pumpOverlay({required bool active, required bool animate}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScannerOverlay(
            scanWindow: const Rect.fromLTWH(20, 20, 200, 200),
            active: active,
            animate: animate,
          ),
        ),
      ));
      await tester.pump();
    }

    await pumpOverlay(active: true, animate: true);
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await pumpOverlay(active: false, animate: true);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, 0);

    await pumpOverlay(active: true, animate: false);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, 0);
  });
}
