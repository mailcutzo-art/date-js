import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/synk_palette.dart';

/// One of the four layers of a Bauhaus avatar, in the 80 x 80 design space.
@immutable
class BauhausShape {
  const BauhausShape({
    required this.colorIndex,
    required this.translateX,
    required this.translateY,
    required this.rotation,
    required this.isSquare,
  });

  /// Index into the palette.
  final int colorIndex;
  final double translateX;
  final double translateY;

  /// Rotation in degrees (about the centre of the 80 x 80 space).
  final double rotation;

  /// Whether the rectangle layer is a full square (otherwise a thin bar). Same for every layer.
  final bool isSquare;

  @override
  bool operator ==(Object other) =>
      other is BauhausShape &&
      other.colorIndex == colorIndex &&
      other.translateX == translateX &&
      other.translateY == translateY &&
      other.rotation == rotation &&
      other.isSquare == isSquare;

  @override
  int get hashCode =>
      Object.hash(colorIndex, translateX, translateY, rotation, isSquare);

  @override
  String toString() =>
      'BauhausShape(color: $colorIndex, t: ($translateX, $translateY), '
      'rot: $rotation, square: $isSquare)';
}

/// Deterministic generative avatar: an exact port of `react-native-boring-avatars@1.0.1`
/// "bauhaus" (used for group avatars). The name's char-code sum drives four layers (background,
/// rotated bar or square, circle, line) drawn in an 80 x 80 space and clipped to a circle.
class BauhausAvatar extends StatelessWidget {
  const BauhausAvatar({
    required this.name,
    this.size = 40,
    this.colors = SynkPalette.groupAvatarPalette,
    this.semanticLabel,
    super.key,
  });

  final String name;
  final double size;
  final List<Color> colors;

  /// Decorative by default; pass the group name where the avatar stands alone.
  final String? semanticLabel;

  /// Side of the design space the algorithm works in.
  static const double viewSize = 80;

  /// The four layers for [name] on a palette of [paletteSize] colours (pure; no drawing).
  ///
  /// `sum` is the total, over the code points of [name], of the first UTF-16 unit of each code
  /// point (JS `Array.from(name)` then `charCodeAt(0)`).
  static List<BauhausShape> compute(String name, int paletteSize) {
    if (paletteSize <= 0) {
      throw ArgumentError.value(paletteSize, 'paletteSize', 'must be positive');
    }
    final sum = _charCodeSum(name);
    final isSquare = _digit(sum, 2).isEven;
    return List<BauhausShape>.generate(4, (idx) {
      final scaled = sum * (idx + 1);
      final translateRange = (viewSize / 2 - (idx + 17)).toInt();
      return BauhausShape(
        colorIndex: (sum + idx) % paletteSize,
        translateX: _unit(scaled, translateRange, 1).toDouble(),
        translateY: _unit(scaled, translateRange, 2).toDouble(),
        rotation: _unit(scaled, 360, null).toDouble(),
        isSquare: isSquare,
      );
    }, growable: false);
  }

  static int _charCodeSum(String name) {
    var sum = 0;
    var i = 0;
    while (i < name.length) {
      final unit = name.codeUnitAt(i);
      sum += unit;
      final isHigh = unit >= 0xD800 && unit <= 0xDBFF;
      final hasLow =
          isHigh &&
          i + 1 < name.length &&
          name.codeUnitAt(i + 1) >= 0xDC00 &&
          name.codeUnitAt(i + 1) <= 0xDFFF;
      i += hasLow ? 2 : 1;
    }
    return sum;
  }

  /// `floor(number / 10^ntn % 10)`.
  static int _digit(int number, int ntn) {
    var divisor = 1;
    for (var i = 0; i < ntn; i++) {
      divisor *= 10;
    }
    return (number ~/ divisor) % 10;
  }

  static int _unit(int number, int range, int? index) {
    final value = number % range;
    if (index != null && index != 0 && _digit(number, index).isEven) {
      return -value;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final palette = colors.isEmpty ? SynkPalette.groupAvatarPalette : colors;
    final painted = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: BauhausPainter(
          shapes: compute(name, palette.length),
          colors: palette,
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: painted);
    return Semantics(image: true, label: semanticLabel, child: painted);
  }
}

/// Paints the four Bauhaus layers scaled from the 80 x 80 design space to the widget size.
class BauhausPainter extends CustomPainter {
  BauhausPainter({required this.shapes, required this.colors});

  final List<BauhausShape> shapes;
  final List<Color> colors;

  static const double _s = BauhausAvatar.viewSize;
  static const double _c = _s / 2;
  static const Rect _background = Rect.fromLTWH(0, 0, _s, _s);

  final Paint _paint = Paint()..isAntiAlias = true;

  Color _colorOf(int layer) => colors[shapes[layer].colorIndex % colors.length];

  void _layer(Canvas canvas, BauhausShape shape, {required bool rotate}) {
    canvas.translate(shape.translateX, shape.translateY);
    if (rotate) {
      canvas
        ..translate(_c, _c)
        ..rotate(shape.rotation * math.pi / 180)
        ..translate(-_c, -_c);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (shapes.length < 4 || colors.isEmpty) return;
    final unit = size.shortestSide / _s;
    canvas
      ..save()
      ..clipPath(Path()..addOval(Offset.zero & size))
      ..scale(unit);

    // 1. Full square background.
    _paint
      ..style = PaintingStyle.fill
      ..color = _colorOf(0);
    canvas.drawRect(_background, _paint);

    // 2. Bar (or square), translated then rotated about the centre.
    final bar = shapes[1];
    canvas.save();
    _layer(canvas, bar, rotate: true);
    _paint.color = _colorOf(1);
    canvas.drawRect(
      Rect.fromLTWH(
        (_s - 60) / 2,
        (_s - 20) / 2,
        _s,
        bar.isSquare ? _s : _s / 8,
      ),
      _paint,
    );
    canvas.restore();

    // 3. Circle.
    final circle = shapes[2];
    canvas.save();
    _layer(canvas, circle, rotate: false);
    _paint.color = _colorOf(2);
    canvas.drawCircle(const Offset(_c, _c), _s / 5, _paint);
    canvas.restore();

    // 4. Line.
    final line = shapes[3];
    canvas.save();
    _layer(canvas, line, rotate: true);
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.butt
      ..color = _colorOf(3);
    canvas.drawLine(const Offset(0, _c), const Offset(_s, _c), _paint);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(BauhausPainter oldDelegate) =>
      !_listEq(oldDelegate.shapes, shapes) ||
      !_listEq(oldDelegate.colors, colors);

  static bool _listEq<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
