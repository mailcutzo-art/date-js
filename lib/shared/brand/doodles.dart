import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Hand-drawn brand decorations (hearts, crown, starburst, swallow, sparkle). All are purely
/// decorative and excluded from semantics.
abstract final class _Doodle {
  static Widget wrap(
    double width,
    double height,
    CustomPainter painter, {
    double angle = 0,
  }) {
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: angle,
        child: CustomPaint(size: Size(width, height), painter: painter),
      ),
    );
  }
}

/// White heart with a black outline, like a sticker stuck on a photo.
class HeartSticker extends StatelessWidget {
  const HeartSticker({
    this.size = 28,
    this.angle = -0.2,
    this.fill = Colors.white,
    this.outline = SynkPalette.nightInk,
    super.key,
  });

  final double size;
  final double angle;
  final Color fill;
  final Color outline;

  @override
  Widget build(BuildContext context) => _Doodle.wrap(
    size,
    size * 0.92,
    _HeartPainter(fill, outline),
    angle: angle,
  );
}

class _HeartPainter extends CustomPainter {
  _HeartPainter(this.fill, this.outline);

  final Color fill;
  final Color outline;

  static Path heart(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(.5 * w, .94 * h)
      ..cubicTo(.2 * w, .72 * h, 0, .52 * h, 0, .3 * h)
      ..cubicTo(0, .12 * h, .14 * w, 0, .3 * w, 0)
      ..cubicTo(.4 * w, 0, .47 * w, .06 * h, .5 * w, .15 * h)
      ..cubicTo(.53 * w, .06 * h, .6 * w, 0, .7 * w, 0)
      ..cubicTo(.86 * w, 0, w, .12 * h, w, .3 * h)
      ..cubicTo(w, .52 * h, .8 * w, .72 * h, .5 * w, .94 * h)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(1.5, size.width * 0.07);
    final inner = Size(size.width - stroke, size.height - stroke);
    canvas.translate(stroke / 2, stroke / 2);
    final path = heart(inner);
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeJoin = StrokeJoin.round
          ..color = outline,
      );
  }

  @override
  bool shouldRepaint(_HeartPainter old) =>
      old.fill != fill || old.outline != outline;
}

/// Five-point crown: ink fill with a light outline and balls on the points.
class CrownDoodle extends StatelessWidget {
  const CrownDoodle({
    this.size = 56,
    this.angle = 0.12,
    this.fill = SynkPalette.nightInk,
    this.outline = Colors.white,
    super.key,
  });

  final double size;
  final double angle;
  final Color fill;
  final Color outline;

  @override
  Widget build(BuildContext context) => _Doodle.wrap(
    size,
    size * 0.78,
    _CrownPainter(fill, outline),
    angle: angle,
  );
}

class _CrownPainter extends CustomPainter {
  _CrownPainter(this.fill, this.outline);

  final Color fill;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = math.max(1.5, w * 0.045);
    final body = Path()
      ..moveTo(.14 * w, .9 * h)
      ..lineTo(.08 * w, .3 * h)
      ..lineTo(.31 * w, .58 * h)
      ..lineTo(.5 * w, .14 * h)
      ..lineTo(.69 * w, .58 * h)
      ..lineTo(.92 * w, .3 * h)
      ..lineTo(.86 * w, .9 * h)
      ..close();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = outline;
    canvas
      ..drawPath(body, Paint()..color = fill)
      ..drawPath(body, line)
      ..drawLine(Offset(.13 * w, .74 * h), Offset(.87 * w, .74 * h), line);
    final ball = w * 0.055;
    for (final tip in [
      Offset(.08 * w, .3 * h - ball),
      Offset(.5 * w, .14 * h - ball),
      Offset(.92 * w, .3 * h - ball),
    ]) {
      canvas
        ..drawCircle(tip, ball, Paint()..color = fill)
        ..drawCircle(tip, ball, line);
    }
    // Three "jewels" on the band.
    for (final x in [.32, .5, .68]) {
      canvas.drawCircle(
        Offset(x * w, .82 * h),
        stroke * 0.6,
        Paint()..color = outline,
      );
    }
  }

  @override
  bool shouldRepaint(_CrownPainter old) =>
      old.fill != fill || old.outline != outline;
}

/// Jagged starburst (the cream "explosion" behind poster mascots and the paywall crown).
class Starburst extends StatelessWidget {
  const Starburst({
    this.size = 160,
    this.color = SynkPalette.cream,
    this.points = 16,
    this.seed = 3,
    this.child,
    super.key,
  });

  final double size;
  final Color color;
  final int points;
  final int seed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: child == null,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _StarburstPainter(color, points, seed),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  _StarburstPainter(this.color, this.points, this.seed);

  final Color color;
  final int points;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final t = i / (points * 2) * math.pi * 2 - math.pi / 2;
      final r = i.isEven
          ? outer * (0.86 + rng.nextDouble() * 0.14)
          : outer * (0.62 + rng.nextDouble() * 0.1);
      final p = c + Offset(math.cos(t) * r, math.sin(t) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarburstPainter old) =>
      old.color != color || old.points != points || old.seed != seed;
}

/// Swallow in flight, white with an ink outline.
class SwallowDoodle extends StatelessWidget {
  const SwallowDoodle({this.width = 64, this.angle = -0.1, super.key});

  final double width;
  final double angle;

  @override
  Widget build(BuildContext context) =>
      _Doodle.wrap(width, width * 0.72, _SwallowPainter(), angle: angle);
}

class _SwallowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100, sy = size.height / 72;
    final path = Path()
      ..moveTo(2 * sx, 34 * sy)
      ..cubicTo(14 * sx, 26 * sy, 30 * sx, 24 * sy, 42 * sx, 30 * sy)
      ..cubicTo(52 * sx, 18 * sy, 68 * sx, 7 * sy, 97 * sx, 2 * sy)
      ..cubicTo(82 * sx, 14 * sy, 70 * sx, 26 * sy, 60 * sx, 37 * sy)
      ..cubicTo(72 * sx, 41 * sy, 84 * sx, 51 * sy, 93 * sx, 63 * sy)
      ..cubicTo(81 * sx, 57 * sy, 71 * sx, 53 * sy, 62 * sx, 49 * sy)
      ..cubicTo(69 * sx, 56 * sy, 73 * sx, 63 * sy, 74 * sx, 70 * sy)
      ..cubicTo(62 * sx, 61 * sy, 52 * sx, 51 * sy, 40 * sx, 45 * sy)
      ..cubicTo(28 * sx, 43 * sy, 16 * sx, 41 * sy, 2 * sx, 34 * sy)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = Colors.white)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, size.width * 0.025)
          ..strokeJoin = StrokeJoin.round
          ..color = SynkPalette.nightInk,
      )
      ..drawCircle(
        Offset(12 * sx, 32 * sy),
        math.max(1.0, size.width * 0.022),
        Paint()..color = SynkPalette.nightInk,
      );
  }

  @override
  bool shouldRepaint(_SwallowPainter old) => false;
}

/// Four-point sparkle.
class SparkleDoodle extends StatelessWidget {
  const SparkleDoodle({this.size = 18, this.color = Colors.white, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      _Doodle.wrap(size, size, _SparklePainter(color));
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w * .56, h * .44, w, h / 2)
      ..quadraticBezierTo(w * .56, h * .56, w / 2, h)
      ..quadraticBezierTo(w * .44, h * .56, 0, h / 2)
      ..quadraticBezierTo(w * .44, h * .44, w / 2, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}
