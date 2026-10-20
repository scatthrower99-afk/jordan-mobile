import 'package:flutter/material.dart';

import 'arc_reactor.dart' show JarvisPalette;

/// Full-bleed in-helmet display layer: scanlines, a faint grid, corner
/// brackets and a vignette.
///
/// Sits on top of the content and ignores pointer input. Every alpha is kept
/// deliberately low so it reads as glass etching rather than a filter — the
/// moment it competes with text it has failed at its job.
class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    this.scanlineSpacing = 3,
    this.gridSpacing = 56,
    this.showVignette = true,
    this.showBrackets = true,
  });

  final double scanlineSpacing;
  final double gridSpacing;
  final bool showVignette;
  final bool showBrackets;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: HudPainter(
              scanlineSpacing: scanlineSpacing,
              gridSpacing: gridSpacing,
              showVignette: showVignette,
              showBrackets: showBrackets,
              tint: JarvisPalette.accent,
            ),
          ),
        ),
      );
}

class HudPainter extends CustomPainter {
  const HudPainter({
    required this.scanlineSpacing,
    required this.gridSpacing,
    required this.showVignette,
    required this.showBrackets,
    required this.tint,
  });

  final double scanlineSpacing;
  final double gridSpacing;
  final bool showVignette;
  final bool showBrackets;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    if (scanlineSpacing > 0) _paintScanlines(canvas, size);
    if (gridSpacing > 0) _paintGrid(canvas, size);
    if (showBrackets) _paintBrackets(canvas, size);
    if (showVignette) _paintVignette(canvas, size);
  }

  void _paintScanlines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tint.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += scanlineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tint.withValues(alpha: 0.035)
      ..strokeWidth = 0.5;

    for (var x = gridSpacing; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = gridSpacing; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintBrackets(Canvas canvas, Size size) {
    const length = 22.0;
    const inset = 12.0;
    final paint = Paint()
      ..color = tint.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;

    final corners = <(Offset, Offset, Offset)>[
      // top-left: horizontal then vertical arm
      (Offset(inset, inset), Offset(inset + length, inset), Offset(inset, inset + length)),
      // top-right
      (
        Offset(size.width - inset, inset),
        Offset(size.width - inset - length, inset),
        Offset(size.width - inset, inset + length)
      ),
      // bottom-right
      (
        Offset(size.width - inset, size.height - inset),
        Offset(size.width - inset - length, size.height - inset),
        Offset(size.width - inset, size.height - inset - length)
      ),
      // bottom-left
      (
        Offset(inset, size.height - inset),
        Offset(inset + length, size.height - inset),
        Offset(inset, size.height - inset - length)
      ),
    ];

    for (final (corner, a, b) in corners) {
      canvas.drawLine(corner, a, paint);
      canvas.drawLine(corner, b, paint);
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.30),
            Colors.black.withValues(alpha: 0.55),
          ],
          stops: const [0.45, 0.78, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant HudPainter old) =>
      old.scanlineSpacing != scanlineSpacing ||
      old.gridSpacing != gridSpacing ||
      old.showVignette != showVignette ||
      old.showBrackets != showBrackets ||
      old.tint != tint;
}
