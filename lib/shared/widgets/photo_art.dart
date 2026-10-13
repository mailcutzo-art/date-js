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

  static const List<List<Color>> _palettes = [
    [Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFFFFD3A5)],
    [Color(0xFF84FAB0), Color(0xFF8FD3F4), Color(0xFFCFF3E0)],
    [Color(0xFFA18CD1), Color(0xFFFBC2EB), Color(0xFFE0C3FC)],
    [Color(0xFFF6D365), Color(0xFFFDA085), Color(0xFFFFE9B0)],
    [Color(0xFF5EE7DF), Color(0xFFB490CA), Color(0xFFBFF2EE)],
    [Color(0xFFFF758C), Color(0xFFFF7EB3), Color(0xFFFFC2D4)],
    [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFB4C0FF)],
    [Color(0xFF43E97B), Color(0xFF38F9D7), Color(0xFFC8FBE0)],
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
