import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Amber HUD palette shared by the JARVIS UI layer.
///
/// Mirrors the token values in the web frontend's `styles/globals.css` so the
/// phone and the in-browser HUD read as the same system.
class JarvisPalette {
  const JarvisPalette._();

  /// Primary amber — the Iron Man HUD accent.
  static const Color accent = Color(0xFFFFA024);

  /// Darker amber for dimmed strokes and filled surfaces.
  static const Color accentDim = Color(0xFFC2610A);

  /// Warm near-black backdrop.
  static const Color bg = Color(0xFF0B0A09);

  /// Panel / card background.
  static const Color panel = Color(0xFF14110E);

  /// Hairline separator.
  static const Color line = Color(0x33FFA024);
}

/// Animated arc-reactor mark: concentric rings around a glowing core.
///
/// Rendered as a single [CustomPainter], so the whole animation costs one
/// repaint of a small square rather than a tree of animating widgets.
class ArcReactor extends StatefulWidget {
  const ArcReactor({
    super.key,
    this.size = 96,
    this.intensity = 1.0,
    this.showOrbit = true,
  });

  /// Edge length of the square the reactor is drawn into.
  final double size;

  /// 0..1 drive value. Kept as a parameter so a future version can feed it
  /// live audio levels from the room.
  final double intensity;

  /// Whether the segmented outer ring rotates. Disabled for static contexts.
  final bool showOrbit;

  @override
  State<ArcReactor> createState() => _ArcReactorState();
}

class _ArcReactorState extends State<ArcReactor> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (ctx, _) => CustomPaint(
            size: Size.square(widget.size),
            painter: ArcReactorPainter(
              // Two nested periods: a slow orbit plus a fast heartbeat, so the
              // motion never looks like a simple loop.
              angle: widget.showOrbit ? _controller.value * math.pi * 2 / 8 : 0,
              pulse: Curves.easeInOut.transform(
                math.sin(_controller.value * math.pi).abs(),
              ),
              intensity: widget.intensity,
              accent: JarvisPalette.accent,
              accentDim: JarvisPalette.accentDim,
            ),
          ),
        ),
      );
}

/// Paints the arc reactor. Pure function of its parameters, which makes it
/// cheap to test and trivial to drive from any animation source.
class ArcReactorPainter extends CustomPainter {
  const ArcReactorPainter({
    required this.angle,
    required this.pulse,
    required this.intensity,
    required this.accent,
    required this.accentDim,
  });

  /// Rotation of the segmented ring, in radians.
  final double angle;

  /// 0..1 heartbeat, scales the glow.
  final double pulse;

  /// 0..1 external drive, currently the resting intensity.
  final double intensity;

  final Color accent;
  final Color accentDim;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    if (radius <= 0) return;

    // Levels above 1 are clamped so callers can pass raw values.
    final drive = intensity.clamp(0.0, 1.0);

    _paintGlow(canvas, center, radius, drive);
    _paintCore(canvas, center, radius, drive);
    _paintInnerRing(canvas, center, radius);
    _paintSegmentedRing(canvas, center, radius);
    _paintOuterRing(canvas, center, radius);
  }

  /// Soft bloom around the core, faked with concentric strokes — a real blur
  /// would need a separate layer and is far more expensive per frame.
  void _paintGlow(Canvas canvas, Offset center, double radius, double drive) {
    const layers = 5;
    for (var i = 0; i < layers; i++) {
      final t = i / (layers - 1);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * (0.16 - i * 0.024)
        ..color = accent.withValues(alpha: (0.11 - i * 0.019) * (0.55 + 0.45 * pulse));
      canvas.drawCircle(center, radius * (0.24 + t * 0.16 + 0.02 * drive), paint);
    }
  }

  /// The lit core, with a hotter centre to suggest a point source.
  void _paintCore(Canvas canvas, Offset center, double radius, double drive) {
    final coreRadius = radius * (0.17 + 0.03 * drive);

    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            accent.withValues(alpha: 0.75 + 0.25 * pulse),
            accentDim.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );

    // White-hot filament at the very centre.
    canvas.drawCircle(
      center,
      radius * 0.055,
      Paint()..color = Colors.white.withValues(alpha: 0.55 + 0.45 * pulse),
    );
  }

  void _paintInnerRing(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius * 0.26,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.016
        ..color = accent.withValues(alpha: 0.55),
    );
  }

  /// 24 evenly spaced segments, the "gills" of the reactor.
  void _paintSegmentedRing(Canvas canvas, Offset center, double radius) {
    const segments = 24;
    const gap = 0.28; // fraction of each slot left empty
    final trackRadius = radius * 0.40;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.055
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    for (var i = 0; i < segments; i++) {
      final start = (math.pi * 2 / segments) * (i + gap / 2);
      final sweep = (math.pi * 2 / segments) * (1 - gap);
      // Alternate brightness so the ring reads as a machined part, not a
      // dotted circle.
      final alpha = i.isEven ? 0.85 : 0.42;
      paint.color = accent.withValues(alpha: alpha * (0.7 + 0.3 * pulse));
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: trackRadius), start, sweep, false, paint);
    }

    canvas.restore();
  }

  void _paintOuterRing(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius * 0.48,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.012
        ..color = accent.withValues(alpha: 0.30),
    );

    // Four cardinal brackets, the helmet's alignment ticks.
    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.022
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.65);

    for (var i = 0; i < 4; i++) {
      final theta = math.pi / 2 * i - math.pi / 2;
      final from = Offset(
        center.dx + math.cos(theta) * radius * 0.50,
        center.dy + math.sin(theta) * radius * 0.50,
      );
      final to = Offset(
        center.dx + math.cos(theta) * radius * 0.58,
        center.dy + math.sin(theta) * radius * 0.58,
      );
      canvas.drawLine(from, to, bracketPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ArcReactorPainter old) =>
      old.angle != angle ||
      old.pulse != pulse ||
      old.intensity != intensity ||
      old.accent != accent ||
      old.accentDim != accentDim;
}
