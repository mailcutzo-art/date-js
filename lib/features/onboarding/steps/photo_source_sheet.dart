import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Asks where a new photo comes from. The demo build has no camera or gallery plumbing yet, so
/// both choices add a generated sample photo; swap the returned seed for a picked image later
/// (`image_picker`).
Future<int?> showPhotoSourceSheet(BuildContext context, int existingCount) {
  final seed = 200 + existingCount * 17 + 3;
  return showSynkBottomSheet<int>(
    context,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetHeader(
          children: [
            SheetTitle('Add a photo'),
            SheetDescription(
              'Demo build: this adds a sample photo. Camera and gallery '
              'pickers plug in here.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        SynkButton(
          label: 'Take a photo',
          leadingIcon: SynkIcons.camera,
          variant: SynkButtonVariant.secondary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(seed),
        ),
        const SizedBox(height: 10),
        SynkButton(
          label: 'Choose from gallery',
          leadingIcon: SynkIcons.image,
          variant: SynkButtonVariant.secondary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(seed),
        ),
      ],
    ),
  );
}
