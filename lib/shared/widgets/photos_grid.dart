import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../brand_colors.dart';
import 'photo_art.dart';

/// 3 x 2 grid of photo slots: filled slots show the photo with a remove button (the first is
/// the "Main" photo), empty slots are an add button.
class PhotosGrid extends StatelessWidget {
  const PhotosGrid({
    required this.seeds,
    required this.onAdd,
    required this.onRemove,
    this.maxPhotos = 6,
    super.key,
  });

  final List<int> seeds;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.72,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < maxPhotos; i++)
          i < seeds.length
              ? _Filled(
                  seed: seeds[i],
                  main: i == 0,
                  onRemove: () => onRemove(i),
                )
              : _Empty(onTap: onAdd, highlight: i == seeds.length),
      ],
    );
  }
}

class _Filled extends StatelessWidget {
  const _Filled({
    required this.seed,
    required this.main,
    required this.onRemove,
  });

  final int seed;
  final bool main;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: SynkRadius.lgAll,
          child: PhotoArt(seed: seed),
        ),
        if (main)
          const Positioned(
            left: 8,
            bottom: 8,
            child: SynkBadge(
              text: 'Main',
              variant: SynkBadgeVariant.ink,
              small: true,
            ),
          ),
        Positioned(
          right: 4,
          top: 4,
          child: Semantics(
            container: true,
            child: SynkPressable(
              semanticLabel: 'Remove photo',
              onTap: onRemove,
              hitSlop: const EdgeInsets.all(4),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0x99000000),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const SynkIcon(
                  SynkIcons.close,
                  size: 14,
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onTap, required this.highlight});

  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      child: SynkPressable(
        semanticLabel: 'Add photo',
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: SynkRadius.lgAll,
            border: Border.all(
              color: highlight ? colors.brandText : colors.border,
              width: highlight ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: SynkIcon(
            SynkIcons.add,
            size: 26,
            color: highlight ? colors.brandText : colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
