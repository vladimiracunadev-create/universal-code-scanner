import 'package:flutter/material.dart';

/// What the camera is doing right now, from the user's point of view.
enum ScanPhase {
  /// The camera was asked to start and has not delivered frames yet.
  starting,

  /// Frames are being analysed: any code in front of the lens will be read.
  scanning,

  /// The user stopped the reading, or a result is being shown.
  paused,

  /// The camera could not start: no permission, no device, or an error.
  unavailable,
}

/// Permanent, always-visible answer to "is it scanning right now?".
///
/// The first version of the scanner showed only a hint text, so a camera that
/// silently failed to start looked exactly like a camera waiting for a code.
/// The moving bar is the part that makes the difference legible at a glance,
/// and the action button gives the user a way out without leaving the screen.
class ScanStatusBar extends StatelessWidget {
  const ScanStatusBar({
    required this.phase,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.animate = true,
    super.key,
  });

  final ScanPhase phase;

  /// Secondary line: what the user should do next.
  final String message;

  final String? actionLabel;
  final VoidCallback? onAction;

  /// False when the user asked for reduced motion: the bar is then drawn
  /// filled and still, so the state is still readable without movement.
  final bool animate;

  String get _title => switch (phase) {
        ScanPhase.starting => 'Iniciando cámara…',
        ScanPhase.scanning => 'Escaneando',
        ScanPhase.paused => 'Escaneo en pausa',
        ScanPhase.unavailable => 'Cámara no disponible',
      };

  IconData get _icon => switch (phase) {
        ScanPhase.starting => Icons.hourglass_top_outlined,
        ScanPhase.scanning => Icons.qr_code_scanner,
        ScanPhase.paused => Icons.pause_circle_outline,
        ScanPhase.unavailable => Icons.videocam_off_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = switch (phase) {
      ScanPhase.starting || ScanPhase.scanning => colors.primary,
      ScanPhase.paused => Colors.white,
      ScanPhase.unavailable => colors.error,
    };
    return Semantics(
      liveRegion: true,
      label: '$_title. $message',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(_icon, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            _ScanProgressBar(phase: phase, accent: accent, animate: animate),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(phase == ScanPhase.paused ? Icons.play_arrow : Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The horizontal bar itself: it moves only while the camera is really
/// analysing frames.
class _ScanProgressBar extends StatelessWidget {
  const _ScanProgressBar({required this.phase, required this.accent, required this.animate});

  final ScanPhase phase;
  final Color accent;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final bool busy = phase == ScanPhase.starting || phase == ScanPhase.scanning;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        // A null value is the moving, indeterminate bar; a fixed value draws a
        // still bar, which is what a paused camera or reduced motion needs.
        value: busy && animate ? null : (busy ? 1 : 0),
        minHeight: 6,
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );
  }
}
