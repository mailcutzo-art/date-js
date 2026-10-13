import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/onboarding_providers.dart';
import '../../../design_system/design_system.dart';
import '../setup_step_scaffold.dart';

enum _Phase { idle, scanning, done }

/// Step 6 (optional): selfie verification. The demo build only plays the scan animation and
/// marks the profile verified; a real build hands the camera frame to the verification service.
class VerifyStep extends ConsumerStatefulWidget {
  const VerifyStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  ConsumerState<VerifyStep> createState() => _VerifyStepState();
}

class _VerifyStepState extends ConsumerState<VerifyStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..addStatusListener(_onStatus);
  _Phase _phase = _Phase.idle;

  @override
  void initState() {
    super.initState();
    if (ref.read(onboardingProvider).verified) _phase = _Phase.done;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _phase = _Phase.done);
    ref
        .read(onboardingProvider.notifier)
        .update((d) => d.copyWith(verified: true));
    SynkHapticsScope.of(context).play(SynkHaptic.success);
  }

  void _start() {
    setState(() => _phase = _Phase.scanning);
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scanning = _phase == _Phase.scanning;
    final done = _phase == _Phase.done;
    return SetupStepScaffold(
      title: 'Get verified',
      subtitle:
          'A quick selfie shows you are really you. Verified profiles get a blue tick '
          'and more matches.',
      ctaLabel: done ? 'Continue' : 'Start verification',
      loading: scanning,
      onCta: done ? widget.onNext : _start,
      secondaryLabel: done || scanning ? null : 'Skip for now',
      onSecondary: widget.onNext,
      child: Center(
        child: SizedBox.square(
          dimension: 220,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _ScanRingPainter(
                progress: scanning ? _c.value : (done ? 1 : 0),
                track: colors.border,
                color: done ? SynkPalette.success : colors.primary,
                spinning: scanning,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: SynkMotion.progress,
                  child: SynkIcon(
                    done ? SynkIcons.checkCircle : SynkIcons.userCircle,
                    key: ValueKey(done),
                    size: 84,
                    color: done ? SynkPalette.success : colors.mutedForeground,
                    strokeWidth: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanRingPainter extends CustomPainter {
  _ScanRingPainter({
    required this.progress,
    required this.track,
    required this.color,
    required this.spinning,
  });

  final double progress;
  final Color track;
  final Color color;
  final bool spinning;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, base..color = track);
    canvas.drawArc(
      rect,
      -math.pi / 2 + (spinning ? progress * math.pi * 4 : 0),
      math.max(0.05, progress) * math.pi * 2,
      false,
      base..color = color,
    );
  }

  @override
  bool shouldRepaint(_ScanRingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
