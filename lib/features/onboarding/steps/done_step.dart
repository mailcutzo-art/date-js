import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/onboarding_providers.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../setup_step_scaffold.dart';

/// Last step: a recap and the way into discovery.
class DoneStep extends ConsumerWidget {
  const DoneStep({required this.onFinish, this.now, super.key});

  final VoidCallback onFinish;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final profile = draft.toProfile((now ?? DateTime.now)());
    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(child: Confetti(trigger: 1)),
        ),
        SetupStepScaffold(
          title: 'You\'re all set, ${profile.name}!',
          subtitle:
              'Here is how your profile looks. You can change it any time.',
          ctaLabel: 'Start discovering',
          onCta: onFinish,
          child: Column(
            children: [
              Center(
                child: ProfileAvatar(profile: profile, size: 120, ring: true),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SynkText(
                    '${profile.name}, ${profile.age}',
                    variant: SynkTextVariant.h2,
                  ),
                  if (profile.verified) ...[
                    const SizedBox(width: 8),
                    const VerifiedBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              SynkText(profile.city, variant: SynkTextVariant.muted),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final i in profile.interests)
                    SynkChip(label: i, selected: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
