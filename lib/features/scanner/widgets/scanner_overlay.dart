import 'package:flutter/material.dart';

/// Dims everything outside the reading frame and, while the camera is really
/// analysing frames, sweeps a line across it.
///
/// The sweeping line is the second half of the answer to "is it scanning?":
/// the status bar states it in words, the frame shows it where the user is
/// already looking.
class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({
    required this.scanWindow,
    this.active = true,
    this.animate = true,
    super.key,
  });

  final Rect scanWindow;

  /// Whether the camera is analysing frames right now.
  final bool active;

  /// False when the user asked for reduced motion: the frame is then drawn
  /// without the sweeping line.
  final bool animate;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  bool get _sweeping => widget.active && widget.animate;

  @override
  void initState() {
    super.initState();
    if (_sweeping) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sweeping && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!_sweeping && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) => CustomPaint(
          painter: _ScannerOverlayPainter(
            borderColor: widget.active ? colors.primary : Colors.white70,
            scanWindow: widget.scanWindow,
            sweep: _sweeping ? _controller.value : null,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({
    required this.borderColor,
    required this.scanWindow,
    required this.sweep,
  });

  final Color borderColor;
  final Rect scanWindow;

  /// Vertical position of the sweeping line, from 0 (top) to 1 (bottom).
  /// Null when the camera is not analysing frames.
  final double? sweep;

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

    final double? position = sweep;
    if (position == null) return;
    final double y = window.top + window.height * position;
    canvas.drawRect(
      Rect.fromLTWH(window.left + 6, y - 1.5, window.width - 12, 3),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            borderColor.withValues(alpha: 0),
            borderColor,
            borderColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(window.left, y - 2, window.width, 4)),
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.scanWindow != scanWindow ||
      oldDelegate.sweep != sweep;
}
