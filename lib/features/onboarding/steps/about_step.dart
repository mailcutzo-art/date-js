import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/onboarding_providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/interest.dart';
import '../../../shared/widgets/interest_chips.dart';
import '../setup_step_scaffold.dart';

const int kMinInterests = 3;

/// Step 4: a short bio and 3 to 6 interests.
class AboutStep extends ConsumerStatefulWidget {
  const AboutStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  ConsumerState<AboutStep> createState() => _AboutStepState();
}

class _AboutStepState extends ConsumerState<AboutStep> {
  late final TextEditingController _bio = TextEditingController(
    text: ref.read(onboardingProvider).bio,
  );

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final full = draft.interests.length >= kMaxInterests;
    return SetupStepScaffold(
      title: 'What are you into?',
      subtitle:
          'A line about you, then pick $kMinInterests to $kMaxInterests interests.',
      ctaEnabled: draft.interests.length >= kMinInterests,
      onCta: widget.onNext,
      secondaryLabel: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Bio'),
          const SizedBox(height: 8),
          SynkTextField(
            controller: _bio,
            hint: 'Something that makes people want to say hi',
            maxLength: 300,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (v) => notifier.update((d) => d.copyWith(bio: v)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: SectionLabel('Interests')),
              SynkText(
                '${draft.interests.length}/$kMaxInterests',
                variant: SynkTextVariant.small,
                color: full ? context.colors.primary : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          InterestChips(
            interests: kAllInterests,
            selected: draft.interests,
            onToggle: (interest) => notifier.update((d) {
              final next = {...d.interests};
              if (!next.remove(interest)) {
                if (next.length >= kMaxInterests) return d;
                next.add(interest);
              }
              return d.copyWith(interests: next);
            }),
          ),
        ],
      ),
    );
  }
}
