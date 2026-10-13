import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// The reference's dashed circular counter: a small label ("Used") over a bold value ("1066")
/// inside a dashed ring. The text shrinks to fit rather than overflow, so large system text
/// scales never break the circle.
class RingCounter extends StatelessWidget {
  const RingCounter({
    required this.label,
    required this.value,
    this.size = 56,
    this.color,
    super.key,
  });

  final String label;
  final String value;
  final double size;

  /// Ring colour; defaults to the muted foreground at 55 %.
  final Color? color;

  /// Stroke width of the dashed ring.
  static const double strokeWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ring = color ?? colors.mutedForeground.withValues(alpha: 0.55);
    final inset = size * 0.16;
    return Semantics(
      container: true,
      label: '$label $value',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: DashedRingPainter(color: ring, strokeWidth: strokeWidth),
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SynkText(
                      label,
                      variant: SynkTextVariant.caption,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: math.max(9, size * 0.17),
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                    SynkText(
                      value,
                      variant: SynkTextVariant.statUnit,
                      color: colors.foreground,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: math.max(11, size * 0.27),
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed circle: the dash count is chosen so the dashes (and their gaps) divide the circumference
/// evenly, with no short dash at the seam.
class DashedRingPainter extends CustomPainter {
  DashedRingPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 3.5,
    this.gapLength = 3,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  /// Number of dashes around a ring of [radius].
  static int dashCount(double radius, double dash, double gap) {
    final circumference = 2 * math.pi * radius;
    return math.max(4, (circumference / (dash + gap)).round());
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - strokeWidth) / 2;
    if (radius <= 0) return;
    final center = size.center(Offset.zero);
    final count = dashCount(radius, dashLength, gapLength);
    final step = 2 * math.pi / count;
    // Keep the dash/gap proportion of the request while filling the circle exactly.
    final sweep = step * dashLength / (dashLength + gapLength);
    final path = Path();
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < count; i++) {
      path.addArc(rect, i * step - sweep / 2, sweep);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(DashedRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}
