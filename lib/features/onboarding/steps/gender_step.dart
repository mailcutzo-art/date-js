import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/onboarding_providers.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/brand_colors.dart';
import '../../../domain/models/gender.dart';
import '../setup_step_scaffold.dart';

/// Step 2: who you are and who you want to meet.
class GenderStep extends ConsumerWidget {
  const GenderStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    return SetupStepScaffold(
      title: 'About you',
      subtitle: 'This helps us show you the right people.',
      ctaEnabled: draft.gender != null && draft.interestedIn.isNotEmpty,
      onCta: onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('I am a'),
          const SizedBox(height: 10),
          for (final g in Gender.values) ...[
            _ChoiceCard(
              label: g.label,
              selected: draft.gender == g,
              onTap: () => notifier.update((d) => d.copyWith(gender: g)),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          const SectionLabel('Show me'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in Gender.values)
                SynkChip(
                  label: g.label,
                  selected: draft.interestedIn.contains(g),
                  onTap: () => notifier.update((d) {
                    final next = {...d.interestedIn};
                    if (!next.add(g)) next.remove(g);
                    return d.copyWith(interestedIn: next);
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: SynkPressable(
        onTap: onTap,
        semanticLabel: label,
        selected: selected,
        child: AnimatedContainer(
          duration: SynkMotion.progress,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.card,
            borderRadius: SynkRadius.lgAll,
            border: Border.all(
              color: selected ? colors.brandText : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: SynkText(label, variant: SynkTextVariant.large)),
              if (selected)
                SynkIcon(SynkIcons.checkCircle, color: colors.brandText),
            ],
          ),
        ),
      ),
    );
  }
}
