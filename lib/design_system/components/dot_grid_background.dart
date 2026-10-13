import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tokens/synk_theme.dart';

/// The refreshed UI's faint dotted-grid backdrop: a regular lattice of tiny dots in the
/// foreground colour at ~6 % opacity. Paints behind [child] (or alone, filling its parent when
/// there is no child) and lives in its own repaint boundary, so a busy child never re-paints it.
class DotGridBackground extends StatelessWidget {
  const DotGridBackground({
    this.spacing = 14,
    this.dotRadius = 0.8,
    this.color,
    this.child,
    super.key,
  }) : assert(spacing > 0, 'spacing must be positive'),
       assert(dotRadius >= 0, 'dotRadius must not be negative');

  /// Distance between dot centres.
  final double spacing;
  final double dotRadius;

  /// Dot colour; defaults to the theme foreground at [defaultOpacity].
  final Color? color;
  final Widget? child;

  /// Foreground opacity of the default dot colour.
  static const double defaultOpacity = 0.06;

  @override
  Widget build(BuildContext context) {
    final dotColor =
        color ?? context.colors.foreground.withValues(alpha: defaultOpacity);
    final grid = RepaintBoundary(
      child: CustomPaint(
        isComplex: true,
        painter: DotGridPainter(
          spacing: spacing,
          dotRadius: dotRadius,
          color: dotColor,
        ),
      ),
    );
    if (child == null) return SizedBox.expand(child: grid);
    return Stack(
      children: [
        Positioned.fill(child: grid),
        child!,
      ],
    );
  }
}

/// Paints the lattice with a single `drawRawPoints` call.
class DotGridPainter extends CustomPainter {
  DotGridPainter({
    required this.spacing,
    required this.dotRadius,
    required this.color,
  });

  final double spacing;
  final double dotRadius;
  final Color color;

  /// Dot centres inside [size]: the lattice is offset by half a step so the margins are even.
  static Float32List pointsFor(Size size, double spacing) {
    if (size.isEmpty) return Float32List(0);
    final cols = (size.width / spacing).floor() + 1;
    final rows = (size.height / spacing).floor() + 1;
    final out = <double>[];
    final inset = spacing / 2;
    for (var r = 0; r < rows; r++) {
      final y = inset + r * spacing;
      if (y > size.height) break;
      for (var c = 0; c < cols; c++) {
        final x = inset + c * spacing;
        if (x > size.width) break;
        out
          ..add(x)
          ..add(y);
      }
    }
    return Float32List.fromList(out);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (dotRadius <= 0) return;
    final points = pointsFor(size, spacing);
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = dotRadius * 2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawRawPoints(ui.PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(DotGridPainter oldDelegate) =>
      oldDelegate.spacing != spacing ||
      oldDelegate.dotRadius != dotRadius ||
      oldDelegate.color != color;
}
