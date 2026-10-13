import 'package:flutter/material.dart';

import '../foundation/hairline.dart';
import '../tokens/synk_theme.dart';

/// Hairline divider (`SynklySeparator`): exactly one physical pixel thick, in the `border`
/// colour. The horizontal separator fills the available width; the vertical one fills the
/// available height with a 12dp minimum. It is purely decorative and invisible to screen readers.
class SynkSeparator extends StatelessWidget {
  const SynkSeparator({super.key, this.axis = Axis.horizontal});

  final Axis axis;

  /// Minimum length of a vertical separator.
  static const double minVerticalLength = 12;

  @override
  Widget build(BuildContext context) {
    final thickness = hairline(context);
    final line = ColoredBox(color: context.colors.border);
    return ExcludeSemantics(
      child: switch (axis) {
        Axis.horizontal => SizedBox(
          height: thickness,
          width: double.infinity,
          child: line,
        ),
        Axis.vertical => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minVerticalLength),
          child: SizedBox(width: thickness, child: line),
        ),
      },
    );
  }
}
