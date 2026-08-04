import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({required this.scanWindow, super.key});

  final Rect scanWindow;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScannerOverlayPainter(
          borderColor: Theme.of(context).colorScheme.primary,
          scanWindow: scanWindow,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({required this.borderColor, required this.scanWindow});

  final Color borderColor;
  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final Path background = Path()..addRect(Offset.zero & size);
    final Path cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(28)));
    final Path overlay = Path.combine(PathOperation.difference, background, cutout);
    canvas.drawPath(overlay, Paint()..color = Colors.black.withValues(alpha: 0.58));

    final Paint border = Paint()
      ..color = borderColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const double corner = 42;
    final Rect window = scanWindow;
    final Path corners = Path()
      ..moveTo(window.left, window.top + corner)
      ..lineTo(window.left, window.top)
      ..lineTo(window.left + corner, window.top)
      ..moveTo(window.right - corner, window.top)
      ..lineTo(window.right, window.top)
      ..lineTo(window.right, window.top + corner)
      ..moveTo(window.right, window.bottom - corner)
      ..lineTo(window.right, window.bottom)
      ..lineTo(window.right - corner, window.bottom)
      ..moveTo(window.left + corner, window.bottom)
      ..lineTo(window.left, window.bottom)
      ..lineTo(window.left, window.bottom - corner);
    canvas.drawPath(corners, border);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor || oldDelegate.scanWindow != scanWindow;
}
