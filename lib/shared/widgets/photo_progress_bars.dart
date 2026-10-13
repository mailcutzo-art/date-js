import 'package:flutter/material.dart';

/// Segmented "story style" indicator for a photo stack: one bar per photo, the current one lit.
class PhotoProgressBars extends StatelessWidget {
  const PhotoProgressBars({
    required this.count,
    required this.index,
    super.key,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Semantics(
      label: 'Photo ${index + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: i == index ? 0.95 : 0.35,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
