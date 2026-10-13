import 'package:flutter/material.dart';

import '../tokens/synk_palette.dart';

/// Flat placeholder block in [SynkPalette.skeleton]. There is deliberately no shimmer anywhere
/// in Synkly, so a skeleton never animates.
///
/// Without an explicit [width]/[height] the block expands to the space its parent offers on that
/// axis (and collapses to zero when that axis is unbounded), like an empty `Container`.
/// Skeletons are decorative and invisible to screen readers.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height, this.radius = 4});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SynkPalette.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}
