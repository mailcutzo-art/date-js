import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/synk_palette.dart';

/// One confetti piece. Created once per burst; everything else derives from it and the burst time.
@immutable
class ConfettiPiece {
  const ConfettiPiece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
    required this.phase,
  });

  /// Launch angle in radians, upward fan `-(0.35 + r * 2.44)` (screen y grows downwards).
  final double angle;

  /// Launch speed in container heights per second (0.45 .. 1.2).
  final double speed;

  /// Spin in turns per second (-1.5 .. 1.5).
  final double spin;

  /// Edge (rect) or diameter (circle) in logical pixels (5 .. 11).
  final double size;
  final Color color;

  /// 25 % of the pieces are discs, the rest 2:1 rectangles.
  final bool round;

  /// Initial rotation in degrees (0 .. 360).
  final double phase;

  /// Draws a piece from [random] (the consumption order matches the Android implementation).
  factory ConfettiPiece.random(math.Random random) {
    final angle = -(0.35 + random.nextDouble() * 2.44);
    final speed = 0.45 + random.nextDouble() * 0.75;
    final spin = -1.5 + random.nextDouble() * 3;
    final size = 5 + random.nextDouble() * 6;
    final color =
        SynkPalette.confetti[random.nextInt(SynkPalette.confetti.length)];
    final round = random.nextInt(4) == 0;
    final phase = random.nextDouble() * 360;
    return ConfettiPiece(
      angle: angle,
      speed: speed,
      spin: spin,
      size: size,
      color: color,
      round: round,
      phase: phase,
    );
  }

  /// [count] pieces; a [seed] makes the burst reproducible.
  static List<ConfettiPiece> burst(int count, {int? seed}) {
    final random = seed == null ? math.Random() : math.Random(seed);
    return List<ConfettiPiece>.generate(
      count,
      (_) => ConfettiPiece.random(random),
      growable: false,
    );
  }

  /// Centre of the piece [seconds] after launch inside [area]: launched from `(w/2, 0.62h)`,
  /// flying at `speed * h` per second along [angle] and pulled down by `1.7h` gravity.
  Offset positionAt(double seconds, Size area) {
    final h = area.height;
    final gravity = h * Confetti.gravityFactor;
    return Offset(
      area.width / 2 + math.cos(angle) * speed * h * seconds,
      h * Confetti.originY +
          math.sin(angle) * speed * h * seconds +
          0.5 * gravity * seconds * seconds,
    );
  }

  /// Rotation in radians [seconds] after launch.
  double rotationAt(double seconds) =>
      (spin * seconds * 360 + phase) * math.pi / 180;
}

/// One-shot confetti popper: pieces burst up from the middle of the area, fall under gravity and
/// fade. It replays every time [trigger] changes to a value above zero, honours reduced motion
/// (no burst, [onEnd] fires straight away) and never intercepts touches.
///
/// It fills its parent, so place it in a `Stack` (`Positioned.fill`) above the content.
class Confetti extends StatefulWidget {
  const Confetti({
    required this.trigger,
    this.onEnd,
    this.count = 70,
    this.duration = const Duration(milliseconds: 2400),
    this.seed,
    super.key,
  });

  /// Plays the burst whenever it changes to a value greater than zero.
  final int trigger;

  /// Called when a burst has finished (or was skipped for reduced motion).
  final VoidCallback? onEnd;
  final int count;
  final Duration duration;

  /// Fixes the random pieces (tests, goldens). Each burst of the same widget reuses it.
  final int? seed;

  /// Gravity in container heights per second squared.
  static const double gravityFactor = 1.7;

  /// Vertical origin of the burst as a fraction of the height.
  static const double originY = 0.62;

  /// Opacity of the burst at [t] (0..1 of its duration): 1 until 0.7, then a linear fade.
  static double alphaAt(double t) =>
      t < 0.7 ? 1.0 : ((1 - t) / 0.3).clamp(0.0, 1.0).toDouble();

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener(_onStatus);

  List<ConfettiPiece> _pieces = const <ConfettiPiece>[];
  bool _started = false;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onEnd?.call();
  }

  void _play() {
    if (widget.trigger <= 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0;
      // Reduced motion: no burst, but callers waiting on onEnd are still released.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onEnd?.call();
      });
      return;
    }
    _pieces = ConfettiPiece.burst(widget.count, seed: widget.seed);
    _controller.duration = widget.duration;
    _controller.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _play();
    } else if (_controller.isAnimating &&
        MediaQuery.disableAnimationsOf(context)) {
      // "Remove animations" was switched on mid-burst: end it now (the pieces are faded out at
      // the end of the run, and onEnd is told).
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(Confetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.expand(
          child: CustomPaint(
            painter: ConfettiPainter(
              pieces: _pieces,
              progress: _controller,
              duration: widget.duration,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints [pieces] at [progress] (0..1 of [duration]). Nothing is drawn at 0 pieces, at the
/// rest value 0 before the first play, or once the burst has ended (1).
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({
    required this.pieces,
    required this.progress,
    this.duration = const Duration(milliseconds: 2400),
  }) : super(repaint: progress);

  final List<ConfettiPiece> pieces;
  final Animation<double> progress;
  final Duration duration;

  final Paint _paint = Paint()..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (pieces.isEmpty || t <= 0 || t >= 1) return;
    final seconds = t * duration.inMilliseconds / 1000;
    final alpha = Confetti.alphaAt(t);
    for (final piece in pieces) {
      final at = piece.positionAt(seconds, size);
      _paint.color = piece.color.withValues(alpha: piece.color.a * alpha);
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(piece.rotationAt(seconds));
      if (piece.round) {
        canvas.drawCircle(Offset.zero, piece.size / 2, _paint);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(
            -piece.size / 2,
            -piece.size / 4,
            piece.size,
            piece.size / 2,
          ),
          _paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces ||
      oldDelegate.progress != progress ||
      oldDelegate.duration != duration;
}
