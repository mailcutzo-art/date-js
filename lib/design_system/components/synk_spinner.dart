import 'package:flutter/material.dart';

import '../tokens/synk_theme.dart';
import 'synk_button.dart' show SynkButtonSpinner;

/// Indeterminate circular spinner (`SynklySpinner`): Material 3 indeterminate arc with a 2dp
/// stroke, round cap and a transparent track. [color] defaults to the primary colour. With the
/// platform's "remove animations" setting on it is a still arc instead of a turning one.
///
/// Pass [semanticLabel] (for example "Loading") when the spinner is the only thing telling a
/// screen-reader user that work is in progress.
class SynkSpinner extends StatelessWidget {
  const SynkSpinner({
    super.key,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });

  final double size;
  final Color? color;
  final String? semanticLabel;

  static const double strokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.primary;
    if (MediaQuery.disableAnimationsOf(context)) {
      return Semantics(
        label: semanticLabel,
        child: ExcludeSemantics(
          child: SynkButtonSpinner(size: size, color: color),
        ),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        color: color,
        backgroundColor: Colors.transparent,
        strokeWidth: strokeWidth,
        strokeAlign: CircularProgressIndicator.strokeAlignInside,
        strokeCap: StrokeCap.round,
        constraints: BoxConstraints.tight(Size.square(size)),
        padding: EdgeInsets.zero,
        semanticsLabel: semanticLabel,
      ),
    );
  }
}
