import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Pattern of a [WavyBackdrop].
enum WavyStyle {
  /// Wobbly concentric rings around [WavyBackdrop.focus] (topographic look).
  ripple,

  /// Horizontal wavy bands.
  stripes,

  /// A checkerboard warped by sine waves.
  checker,
}

/// The brand's psychedelic background: magenta, orange and violet bands. Fully determined by
/// [style], [seed] and [focus], so it is stable across rebuilds and in golden tests.
class WavyBackdrop extends StatelessWidget {
  const WavyBackdrop({
    this.style = WavyStyle.ripple,
    this.seed = 0,
    this.focus = Alignment.center,
    this.colors = SynkPalette.waves,
    this.child,
    super.key,
  });

  final WavyStyle style;
  final int seed;

  /// Centre of the rings ([WavyStyle.ripple] only).
  final Alignment focus;
  final List<Color> colors;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: WavyPainter(
          style: style,
          seed: seed,
          focus: focus,
          colors: colors,
        ),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

class WavyPainter extends CustomPainter {
  WavyPainter({
    required this.style,
    required this.seed,
    required this.focus,
    required this.colors,
  });

  final WavyStyle style;
  final int seed;
  final Alignment focus;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (style) {
      case WavyStyle.ripple:
        _ripple(canvas, size);
      case WavyStyle.stripes:
        _stripes(canvas, size);
      case WavyStyle.checker:
        _checker(canvas, size);
    }
    canvas.restore();
  }

  /// Band colour sequence: magenta and orange alternate, every fourth band is violet.
  Color _band(int i) {
    if (colors.length < 3) return colors[i % colors.length];
    if (i % 4 == 3) return colors[2];
    return colors[i.isEven ? 0 : 1];
  }

  void _ripple(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final center = focus.alongSize(size);
    final reach =
        math.sqrt(size.width * size.width + size.height * size.height) * 1.1;
    final step = math.max(18.0, size.shortestSide / 11);
    final rings = (reach / step).ceil();
    final k1 = 5 + rng.nextInt(3);
    final k2 = 9 + rng.nextInt(4);
    final phase = rng.nextDouble() * math.pi * 2;
    canvas.drawRect(Offset.zero & size, Paint()..color = _band(rings + 1));
    for (var i = rings; i >= 1; i--) {
      final r = step * i;
      final path = Path();
      const segments = 160;
      for (var s = 0; s <= segments; s++) {
        final t = s / segments * math.pi * 2;
        final wobble =
            0.07 * math.sin(k1 * t + phase + i * 0.55) +
            0.035 * math.sin(k2 * t - phase * 1.7 + i * 0.9);
        final rr = r * (1 + wobble);
        final p = center + Offset(math.cos(t) * rr, math.sin(t) * rr);
        s == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = _band(i));
    }
  }

  void _stripes(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final step = math.max(16.0, size.shortestSide / 9);
    final bands = (size.height / step).ceil() + 3;
    final wavelength = size.width * (0.55 + rng.nextDouble() * 0.3);
    final amp = step * 0.6;
    final phase = rng.nextDouble() * math.pi * 2;
    canvas.drawRect(Offset.zero & size, Paint()..color = _band(0));
    for (var i = 1; i < bands; i++) {
      final baseY = (i - 1.5) * step;
      final path = Path()..moveTo(0, size.height);
      const segments = 60;
      for (var s = 0; s <= segments; s++) {
        final x = size.width * s / segments;
        final y =
            baseY +
            amp * math.sin(2 * math.pi * x / wavelength + phase + i * 0.45) +
            amp * 0.35 * math.sin(4 * math.pi * x / wavelength - i * 0.8);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = _band(i));
    }
  }

  void _checker(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final cell = math.max(22.0, size.shortestSide / 7);
    final cols = (size.width / cell).ceil() + 2;
    final rows = (size.height / cell).ceil() + 2;
    final amp = cell * 0.55;
    final f = 2 * math.pi / (cell * (4 + rng.nextDouble() * 2));
    final phase = rng.nextDouble() * math.pi * 2;

    Offset warp(double x, double y) => Offset(
      x + amp * math.sin(y * f + phase),
      y + amp * 0.8 * math.sin(x * f * 0.9 - phase),
    );

    canvas.drawRect(Offset.zero & size, Paint()..color = colors.first);
    const sub = 4;
    for (var r = -1; r < rows; r++) {
      for (var c = -1; c < cols; c++) {
        final x0 = c * cell, y0 = r * cell;
        final path = Path();
        void edge(double ax, double ay, double bx, double by, bool first) {
          for (var s = first ? 0 : 1; s <= sub; s++) {
            final t = s / sub;
            final p = warp(ax + (bx - ax) * t, ay + (by - ay) * t);
            (first && s == 0)
                ? path.moveTo(p.dx, p.dy)
                : path.lineTo(p.dx, p.dy);
          }
        }

        edge(x0, y0, x0 + cell, y0, true);
        edge(x0 + cell, y0, x0 + cell, y0 + cell, false);
        edge(x0 + cell, y0 + cell, x0, y0 + cell, false);
        edge(x0, y0 + cell, x0, y0, false);
        path.close();
        final odd = (r + c).isOdd;
        final Color color;
        if (!odd) {
          color = colors.first;
        } else {
          color = colors.length > 2 && (r * 3 + c).abs() % 5 == 0
              ? colors[2]
              : colors[1 % colors.length];
        }
        canvas.drawPath(path, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(WavyPainter old) =>
      old.style != style ||
      old.seed != seed ||
      old.focus != focus ||
      !_sameColors(old.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Clips a child so its top edge is a hand-drawn wave (the black "ink" panels of the posters).
class WavyEdgeClipper extends CustomClipper<Path> {
  const WavyEdgeClipper({this.amplitude = 14, this.waves = 1.6, this.seed = 0});

  final double amplitude;
  final double waves;
  final int seed;

  @override
  Path getClip(Size size) {
    final phase = seed * 0.9;
    final path = Path()..moveTo(0, size.height);
    const segments = 48;
    for (var s = 0; s <= segments; s++) {
      final x = size.width * s / segments;
      final t = x / size.width * math.pi * 2 * waves + phase;
      final y = amplitude + amplitude * math.sin(t) * 0.8;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(WavyEdgeClipper old) =>
      old.amplitude != amplitude || old.waves != waves || old.seed != seed;
}

/// A near-black panel with a wavy top edge. [child] is padded below the wave.
class InkPanel extends StatelessWidget {
  const InkPanel({
    required this.child,
    this.amplitude = 14,
    this.seed = 0,
    this.color = SynkPalette.nightInk,
    super.key,
  });

  final Widget child;
  final double amplitude;
  final int seed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WavyEdgeClipper(amplitude: amplitude, seed: seed),
      child: ColoredBox(
        color: color,
        child: Padding(
          padding: EdgeInsets.only(top: amplitude * 2),
          child: child,
        ),
      ),
    );
  }
}
