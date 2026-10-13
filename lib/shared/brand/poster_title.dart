import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// One line of a [PosterTitle]; [scale] is relative to the title's base size.
class PosterLine {
  const PosterLine(this.text, {this.scale = 1});

  final String text;
  final double scale;
}

/// Stacked, hand-lettered uppercase headline with lines of different sizes, slightly tilted
/// ("MATCH / VIA MUTUAL / INTERESTS"). Each line shrinks to fit the width instead of wrapping.
/// Screen readers get the lines joined into one sentence.
class PosterTitle extends StatelessWidget {
  const PosterTitle({
    required this.lines,
    this.size = 44,
    this.color = Colors.white,
    this.angle = -0.035,
    this.align = CrossAxisAlignment.center,
    super.key,
  });

  final List<PosterLine> lines;
  final double size;
  final Color color;

  /// Rotation in radians (negative tilts up to the right).
  final double angle;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final base = SynkTypography.of(SynkTextVariant.poster);
    final label = lines.map((l) => l.text).join(' ');
    return Semantics(
      header: true,
      label: label,
      child: ExcludeSemantics(
        child: Transform.rotate(
          angle: angle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: align,
            children: [
              for (final line in lines)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    line.text.toUpperCase(),
                    maxLines: 1,
                    textScaler: TextScaler.noScaling,
                    style: base.copyWith(
                      color: color,
                      fontSize: size * line.scale,
                      height: 1.02,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
