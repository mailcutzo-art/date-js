import 'package:flutter/material.dart';

import '../tokens/synk_motion.dart';
import '../tokens/synk_theme.dart';

/// Determinate linear progress (`SynklyProgressBar`): fully rounded, `muted` track, [color]
/// fill (primary by default), 4dp tall. [progress] is clamped to 0..1 and changes animate over
/// 200 ms (instantly when the platform asks to reduce motion).
///
/// Screen readers get the percentage as the value, plus [semanticLabel] when given.
class SynkProgressBar extends StatelessWidget {
  const SynkProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 4,
    this.semanticLabel,
  });

  final double progress;
  final Color? color;
  final double height;
  final String? semanticLabel;

  /// [progress] limited to 0..1 (NaN counts as 0).
  static double clampProgress(double progress) =>
      progress.isNaN ? 0 : progress.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final target = clampProgress(progress);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final fill = color ?? colors.primary;
    return Semantics(
      label: semanticLabel,
      value: '${(target * 100).round()}%',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: target),
                duration: animate ? SynkMotion.progress : Duration.zero,
                curve: SynkMotion.fastOutSlowIn,
                builder: (context, value, _) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
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
