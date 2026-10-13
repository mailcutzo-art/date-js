import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/onboarding_providers.dart';
import '../../../core/config/app_info.dart';
import '../../../design_system/design_system.dart';
import '../setup_step_scaffold.dart';

/// Step 5: where you are. "Use my location" runs the permission explainer; the demo build then
/// fills in a sample city (a real build reads the GPS fix and reverse-geocodes it).
class LocationStep extends ConsumerStatefulWidget {
  const LocationStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  ConsumerState<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<LocationStep> {
  late final TextEditingController _city = TextEditingController(
    text: ref.read(onboardingProvider).city,
  );

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Future<void> _useLocation() async {
    final allowed = await showSynkBottomSheet<bool>(
      context,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHeader(
            children: [
              SheetTitle('Allow location access?'),
              SheetDescription(
                '$kAppName uses your location to show people near you. '
                'It is never shown as an exact spot.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SynkButton(
            label: 'Allow while using the app',
            expand: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          SynkButton(
            label: 'Not now',
            variant: SynkButtonVariant.ghost,
            expand: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (allowed != true || !mounted) return;
    _city.text = 'Bengaluru';
    ref
        .read(onboardingProvider.notifier)
        .update((d) => d.copyWith(city: 'Bengaluru'));
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(onboardingProvider).city;
    return SetupStepScaffold(
      title: 'Where are you?',
      subtitle: 'We use this to find people nearby.',
      ctaEnabled: city.trim().isNotEmpty,
      onCta: widget.onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SynkButton(
            label: 'Use my location',
            leadingIcon: SynkIcons.pin,
            variant: SynkButtonVariant.secondary,
            expand: true,
            size: SynkButtonSize.lg,
            onPressed: _useLocation,
          ),
          const SizedBox(height: 24),
          const SectionLabel('Or type your city'),
          const SizedBox(height: 8),
          SynkTextField(
            controller: _city,
            hint: 'City',
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => ref
                .read(onboardingProvider.notifier)
                .update((d) => d.copyWith(city: v)),
          ),
        ],
      ),
    );
  }
}
