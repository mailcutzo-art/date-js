import 'package:flutter/material.dart';

import '../tokens/synk_theme.dart';
import 'synk_glyph.dart';
import 'synk_glyphs.g.dart';

export 'synk_glyphs.g.dart' show SynkIcons;

/// Icon size tokens.
abstract final class SynkIconSize {
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 16;
  static const double base = 18;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
}

/// Default stroke width in logical pixels, constant at every icon size.
const double kDefaultIconStroke = 1.8;

/// Draws a Hugeicons glyph. Unlike a font icon the stroke stays [strokeWidth] logical pixels at
/// every [size] (the Android `absoluteStrokeWidth`), so small and large icons look identical.
class SynkIcon extends StatelessWidget {
  const SynkIcon(
    this.icon, {
    this.size = SynkIconSize.lg,
    this.color,
    this.strokeWidth = kDefaultIconStroke,
    this.semanticLabel,
    super.key,
  });

  final SynkIcons icon;
  final double size;

  /// Defaults to the theme foreground.
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.colors.foreground;
    final painted = CustomPaint(
      size: Size.square(size),
      painter: SynkGlyphPainter(
        glyph: icon.glyph,
        color: tint,
        strokeWidth: strokeWidth,
      ),
    );
    final sized = SizedBox.square(dimension: size, child: painted);
    if (semanticLabel == null) return ExcludeSemantics(child: sized);
    return Semantics(label: semanticLabel, image: true, child: sized);
  }
}

class SynkGlyphPainter extends CustomPainter {
  const SynkGlyphPainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
  });

  final SynkGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / SynkGlyph.viewport;
    if (scale <= 0) return;
    canvas
      ..save()
      ..scale(scale);
    final strokeInViewport = strokeWidth / scale;
    for (final part in glyph.parts) {
      final alpha = (color.a * part.alpha).clamp(0.0, 1.0);
      final tint = color.withValues(alpha: alpha);
      if (part.fill) {
        canvas.drawPath(
          part.path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = tint
            ..isAntiAlias = true,
        );
      }
      if (part.stroke) {
        canvas.drawPath(
          part.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = tint
            ..strokeWidth = strokeInViewport
            ..strokeCap = part.cap
            ..strokeJoin = part.join
            ..strokeMiterLimit = 4
            ..isAntiAlias = true,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SynkGlyphPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
