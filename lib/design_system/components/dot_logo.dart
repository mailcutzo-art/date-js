import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated dot-matrix brand mark (RN `dot-logo.tsx`). Every cell of every 5 x 7 glyph is a dot:
/// "X" cells are large (2.2 d), "." cells small (d). One shared 2.4 s linear loop drives a
/// per-dot pseudo-random phase, so large dots breathe to 94 % and small dots shrink to 55 % while
/// fading by 55 %. Drawn by a single painter that only repaints (never rebuilds).
class DotLogo extends StatefulWidget {
  const DotLogo({
    this.text = 'SYNKLY',
    this.color = Colors.white,
    this.animate = true,
    this.maxWidthFraction,
    this.semanticLabel = 'Synkly',
    super.key,
  });

  final String text;
  final Color color;

  /// When false (or when the system asks for reduced motion) the logo rests, every dot at full
  /// size and opacity.
  final bool animate;

  /// Fraction of the screen width the mark may fill; replaces the default 0.7.
  final double? maxWidthFraction;
  final String semanticLabel;

  @override
  State<DotLogo> createState() => _DotLogoState();
}

class _DotLogoState extends State<DotLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: DotLogoGeometry.loopDuration,
  );

  DotLogoGeometry? _geometry;
  String? _geometryText;
  double? _geometryDot;

  bool _shouldAnimate(BuildContext context) =>
      widget.animate && !MediaQuery.disableAnimationsOf(context);

  void _syncTicker(BuildContext context) {
    if (_shouldAnimate(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker(context);
  }

  @override
  void didUpdateWidget(DotLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dot = DotLogoGeometry.dotDiameter(
      text: widget.text,
      screenWidth: screenWidth,
      widthFraction: widget.maxWidthFraction ?? DotLogoGeometry.defaultFraction,
    );
    if (_geometry == null ||
        _geometryText != widget.text ||
        _geometryDot != dot) {
      _geometry = DotLogoGeometry(text: widget.text, dot: dot);
      _geometryText = widget.text;
      _geometryDot = dot;
    }
    final geometry = _geometry!;
    final animating = _shouldAnimate(context);
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: geometry.width,
          height: geometry.height,
          child: CustomPaint(
            painter: DotLogoPainter(
              geometry: geometry,
              color: widget.color,
              progress: animating ? _controller : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dot positions of a logo (all in logical pixels), computed once per text and dot size.
class DotLogoGeometry {
  DotLogoGeometry({required this.text, required this.dot})
    : spacing = _spacingK * dot,
      letterSpacing = _letterSpacingK * dot,
      large = _spacingK * dot {
    advance = 4 * spacing + letterSpacing;
    final pad = large / 2;
    final glyphs = text.toUpperCase().characters.toList(growable: false);
    final count = glyphs.length;
    width = count == 0 ? 0 : (count - 1) * advance + 4 * spacing + large;
    height = count == 0 ? 0 : 6 * spacing + large;
    final built = <DotLogoDot>[];
    for (var charIdx = 0; charIdx < count; charIdx++) {
      final glyph = dotFont[glyphs[charIdx]] ?? dotFont[' ']!;
      for (var row = 0; row < 7; row++) {
        for (var col = 0; col < 5; col++) {
          built.add(
            DotLogoDot(
              x: charIdx * advance + col * spacing + pad,
              y: row * spacing + pad,
              large: glyph[row][col] == 'X',
              phase: dotPhase(charIdx, row, col),
            ),
          );
        }
      }
    }
    dots = List<DotLogoDot>.unmodifiable(built);
  }

  static const double _spacingK = 2.2;
  static const double _letterSpacingK = 3.4;

  /// Share of the screen width used when no fraction is given.
  static const double defaultFraction = 0.7;

  static const Duration loopDuration = Duration(milliseconds: 2400);

  final String text;

  /// Diameter `d` of a small dot.
  final double dot;
  final double spacing;
  final double letterSpacing;

  /// Diameter of a large dot (2.2 d).
  final double large;
  late final double advance;
  late final double width;
  late final double height;
  late final List<DotLogoDot> dots;

  /// `d = clamp(fraction * screenWidth / (cols * 2.2 + 2.2), 2.5, 8)` with
  /// `cols = len * 4 + (len - 1) * 3.4`.
  static double dotDiameter({
    required String text,
    required double screenWidth,
    double widthFraction = defaultFraction,
  }) {
    final len = text.characters.length;
    final cols = len * 4 + (len - 1) * 3.4;
    final raw = widthFraction * screenWidth / (cols * 2.2 + 2.2);
    return raw.clamp(2.5, 8.0).toDouble();
  }

  /// `frac(sin((charIdx*1009 + row*31 + col*7 + 9001) * 12.9898) * 43758.5453)`.
  static double dotPhase(int charIdx, int row, int col) {
    final seed = (charIdx * 1009 + row * 31 + col * 7 + 9001) * 12.9898;
    final v = math.sin(seed) * 43758.5453;
    return v - v.floorToDouble();
  }
}

/// A single dot of the matrix.
@immutable
class DotLogoDot {
  const DotLogoDot({
    required this.x,
    required this.y,
    required this.large,
    required this.phase,
  });

  final double x;
  final double y;
  final bool large;
  final double phase;
}

/// Paints the dots at an animation [progress] (0..1, repeating). A null [progress] paints the
/// resting logo.
class DotLogoPainter extends CustomPainter {
  DotLogoPainter({required this.geometry, required this.color, this.progress})
    : super(repaint: progress);

  final DotLogoGeometry geometry;
  final Color color;
  final Animation<double>? progress;

  final Paint _paint = Paint()..isAntiAlias = true;

  /// Breathing wave of a dot at loop position [p].
  static double wave(double p, double phase) =>
      (math.sin((p + phase) * 2 * math.pi) + 1) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress?.value;
    final baseAlpha = color.a;
    final large = geometry.large;
    final small = geometry.dot;
    for (final dot in geometry.dots) {
      final w = p == null ? 0.0 : wave(p, dot.phase);
      final center = Offset(dot.x, dot.y);
      if (dot.large) {
        _paint.color = color;
        canvas.drawCircle(center, large / 2 * (1 - 0.06 * w), _paint);
      } else {
        _paint.color = color.withValues(alpha: baseAlpha * (1 - 0.55 * w));
        canvas.drawCircle(center, small / 2 * (1 - 0.45 * w), _paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotLogoPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.color != color ||
      oldDelegate.progress != progress;
}

/// 5 x 7 font (A-Z, 0-9, '.', '-', ' ') from `dot-logo.tsx`; "X" is a large dot.
const Map<String, List<String>> dotFont = <String, List<String>>{
  'A': ['.XXX.', 'X...X', 'X...X', 'XXXXX', 'X...X', 'X...X', 'X...X'],
  'B': ['XXXX.', 'X...X', 'X...X', 'XXXX.', 'X...X', 'X...X', 'XXXX.'],
  'C': ['.XXXX', 'X....', 'X....', 'X....', 'X....', 'X....', '.XXXX'],
  'D': ['XXXX.', 'X...X', 'X...X', 'X...X', 'X...X', 'X...X', 'XXXX.'],
  'E': ['XXXXX', 'X....', 'X....', 'XXXX.', 'X....', 'X....', 'XXXXX'],
  'F': ['XXXXX', 'X....', 'X....', 'XXXX.', 'X....', 'X....', 'X....'],
  'G': ['.XXXX', 'X....', 'X....', 'X.XXX', 'X...X', 'X...X', '.XXX.'],
  'H': ['X...X', 'X...X', 'X...X', 'XXXXX', 'X...X', 'X...X', 'X...X'],
  'I': ['XXXXX', '..X..', '..X..', '..X..', '..X..', '..X..', 'XXXXX'],
  'J': ['XXXXX', '....X', '....X', '....X', '....X', 'X...X', '.XXX.'],
  'K': ['X...X', 'X..X.', 'X.X..', 'XX...', 'X.X..', 'X..X.', 'X...X'],
  'L': ['X....', 'X....', 'X....', 'X....', 'X....', 'X....', 'XXXXX'],
  'M': ['X...X', 'XX.XX', 'X.X.X', 'X...X', 'X...X', 'X...X', 'X...X'],
  'N': ['X...X', 'XX..X', 'X.X.X', 'X..XX', 'X...X', 'X...X', 'X...X'],
  'O': ['.XXX.', 'X...X', 'X...X', 'X...X', 'X...X', 'X...X', '.XXX.'],
  'P': ['XXXX.', 'X...X', 'X...X', 'XXXX.', 'X....', 'X....', 'X....'],
  'Q': ['.XXX.', 'X...X', 'X...X', 'X...X', 'X.X.X', 'X..X.', '.XX.X'],
  'R': ['XXXX.', 'X...X', 'X...X', 'XXXX.', 'X.X..', 'X..X.', 'X...X'],
  'S': ['.XXXX', 'X....', 'X....', '.XXX.', '....X', '....X', 'XXXX.'],
  'T': ['XXXXX', '..X..', '..X..', '..X..', '..X..', '..X..', '..X..'],
  'U': ['X...X', 'X...X', 'X...X', 'X...X', 'X...X', 'X...X', '.XXX.'],
  'V': ['X...X', 'X...X', 'X...X', 'X...X', 'X...X', '.X.X.', '..X..'],
  'W': ['X...X', 'X...X', 'X...X', 'X...X', 'X.X.X', 'XX.XX', 'X...X'],
  'X': ['X...X', 'X...X', '.X.X.', '..X..', '.X.X.', 'X...X', 'X...X'],
  'Y': ['X...X', 'X...X', '.X.X.', '..X..', '..X..', '..X..', '..X..'],
  'Z': ['XXXXX', '....X', '...X.', '..X..', '.X...', 'X....', 'XXXXX'],
  '0': ['.XXX.', 'X...X', 'X..XX', 'X.X.X', 'XX..X', 'X...X', '.XXX.'],
  '1': ['..X..', '.XX..', '..X..', '..X..', '..X..', '..X..', '.XXX.'],
  '2': ['.XXX.', 'X...X', '....X', '...X.', '..X..', '.X...', 'XXXXX'],
  '3': ['XXXX.', '....X', '....X', '.XXX.', '....X', '....X', 'XXXX.'],
  '4': ['...X.', '..XX.', '.X.X.', 'X..X.', 'XXXXX', '...X.', '...X.'],
  '5': ['XXXXX', 'X....', 'XXXX.', '....X', '....X', 'X...X', '.XXX.'],
  '6': ['.XXX.', 'X....', 'X....', 'XXXX.', 'X...X', 'X...X', '.XXX.'],
  '7': ['XXXXX', '....X', '...X.', '..X..', '.X...', '.X...', '.X...'],
  '8': ['.XXX.', 'X...X', 'X...X', '.XXX.', 'X...X', 'X...X', '.XXX.'],
  '9': ['.XXX.', 'X...X', 'X...X', '.XXXX', '....X', '....X', '.XXX.'],
  '.': ['.....', '.....', '.....', '.....', '.....', '.....', '..X..'],
  '-': ['.....', '.....', '.....', '.XXX.', '.....', '.....', '.....'],
  ' ': ['.....', '.....', '.....', '.....', '.....', '.....', '.....'],
};
