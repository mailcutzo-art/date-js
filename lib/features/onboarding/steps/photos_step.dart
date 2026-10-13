import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/onboarding_providers.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/photos_grid.dart';
import '../setup_step_scaffold.dart';
import 'photo_source_sheet.dart';

const int kMinPhotos = 2;

/// Step 3: at least [kMinPhotos] photos.
class PhotosStep extends ConsumerWidget {
  const PhotosStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seeds = ref.watch(onboardingProvider).photoSeeds;
    final notifier = ref.read(onboardingProvider.notifier);
    return SetupStepScaffold(
      title: 'Add your photos',
      subtitle:
          'Pick at least $kMinPhotos. Your first photo is the one people see first.',
      ctaEnabled: seeds.length >= kMinPhotos,
      onCta: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotosGrid(
            seeds: seeds,
            onAdd: () async {
              final seed = await showPhotoSourceSheet(context, seeds.length);
              if (seed == null) return;
              notifier.update(
                (d) => d.copyWith(photoSeeds: [...d.photoSeeds, seed]),
              );
            },
            onRemove: (i) => notifier.update(
              (d) => d.copyWith(photoSeeds: [...d.photoSeeds]..removeAt(i)),
            ),
          ),
          const SizedBox(height: 14),
          SynkText(
            '${seeds.length} of 6 added'
            '${seeds.length < kMinPhotos ? '  ·  ${kMinPhotos - seeds.length} more needed' : ''}',
            variant: SynkTextVariant.muted,
          ),
        ],
      ),
    );
  }
}
