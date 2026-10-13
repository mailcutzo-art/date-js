import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Generated placeholder artwork for a profile photo: a soft gradient with overlapping shapes,
/// fully determined by [seed]. Stands in for real photos until an image backend exists.
class PhotoArt extends StatelessWidget {
  const PhotoArt({required this.seed, this.child, super.key});

  final int seed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: PhotoArtPainter(seed),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

class PhotoArtPainter extends CustomPainter {
  PhotoArtPainter(this.seed);

  final int seed;

  // Warm, saturated duotones that sit well next to the magenta / orange / violet brand art.
  static const List<List<Color>> _palettes = [
    [Color(0xFFFF6A3D), Color(0xFFFF2BD1), Color(0xFFFFD3A5)],
    [Color(0xFF6B3FA0), Color(0xFFFF7EB3), Color(0xFFE0C3FC)],
    [Color(0xFFE2C891), Color(0xFFB4654A), Color(0xFFFFF1DE)],
    [Color(0xFF3A1230), Color(0xFFC2185B), Color(0xFFFFB3D9)],
    [Color(0xFFFF9A62), Color(0xFFA63CF2), Color(0xFFFFE0C2)],
    [Color(0xFF2E3A59), Color(0xFF8E6CC9), Color(0xFFC9D2FF)],
    [Color(0xFFD9485F), Color(0xFFFFB86B), Color(0xFFFFE3E8)],
    [Color(0xFF34296B), Color(0xFFFF5BDC), Color(0xFFEFDDB6)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final palette = _palettes[seed.abs() % _palettes.length];
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + rng.nextDouble() * 0.6, -1),
          end: Alignment(1, 0.6 + rng.nextDouble() * 0.4),
          colors: [palette[0], palette[1]],
        ).createShader(rect),
    );

    final shortest = size.shortestSide;
    for (var i = 0; i < 4; i++) {
      final center = Offset(
        size.width * rng.nextDouble(),
        size.height * rng.nextDouble(),
      );
      final radius = shortest * (0.25 + rng.nextDouble() * 0.45);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = palette[2].withValues(alpha: 0.18 + rng.nextDouble() * 0.2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.25),
      );
    }

    // A simple "figure": head and shoulders, so the cards read as portraits.
    final figure = Paint()..color = Colors.white.withValues(alpha: 0.28);
    final cx = size.width * (0.4 + rng.nextDouble() * 0.2);
    final headR = shortest * 0.17;
    final headY = size.height * 0.40;
    canvas.drawCircle(Offset(cx, headY), headR, figure);
    final shoulders = Rect.fromCenter(
      center: Offset(cx, headY + headR * 3.4),
      width: headR * 5.2,
      height: headR * 4.4,
    );
    canvas.drawOval(shoulders, figure);
  }

  @override
  bool shouldRepaint(PhotoArtPainter oldDelegate) => oldDelegate.seed != seed;
}
