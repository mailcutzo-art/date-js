import 'dart:ui';

import 'package:path_parsing/path_parsing.dart';

/// One drawable part of an icon (an SVG path on a 24x24 viewport).
class SynkGlyphPart {
  const SynkGlyphPart(
    this.d, {
    required this.stroke,
    required this.fill,
    required this.cap,
    required this.join,
    this.alpha = 1.0,
  });

  final String d;
  final bool stroke;
  final bool fill;
  final StrokeCap cap;
  final StrokeJoin join;
  final double alpha;

  /// Parsed once per distinct path string and shared by every icon instance.
  Path get path => _SvgPathCache.parse(d);
}

/// A Hugeicons glyph: one or more parts on a 24x24 viewport.
class SynkGlyph {
  const SynkGlyph(this.parts);

  final List<SynkGlyphPart> parts;

  /// Viewport edge length shared by every glyph.
  static const double viewport = 24;
}

abstract final class _SvgPathCache {
  static final Map<String, Path> _cache = <String, Path>{};

  static Path parse(String d) => _cache.putIfAbsent(d, () {
    final builder = _PathBuilder();
    writeSvgPathDataToPath(d, builder);
    return builder.path;
  });
}

class _PathBuilder extends PathProxy {
  final Path path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

/// Parses an SVG path string into a [Path] (shared helper for custom glyphs).
Path parseSvgPath(String d) => _SvgPathCache.parse(d);
