import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/onboarding_providers.dart';
import '../../../core/config/app_info.dart';
import '../../../design_system/design_system.dart';
import '../setup_step_scaffold.dart';

/// Step 1: first name and birthday. Doubles as the age gate (18+).
class NameStep extends ConsumerStatefulWidget {
  const NameStep({required this.onNext, this.now, super.key});

  final VoidCallback onNext;
  final DateTime Function()? now;

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  late final TextEditingController _name = TextEditingController(
    text: ref.read(onboardingProvider).name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  DateTime get _today => (widget.now ?? DateTime.now)();

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final age = draft.ageAt(_today);
    final underage = age != null && age < kMinAge;
    final valid = draft.name.trim().length >= 2 && age != null && !underage;
    return SetupStepScaffold(
      title: 'Let\'s start with you',
      subtitle:
          'Your first name and birthday. We show your age, not your birthday.',
      ctaEnabled: valid,
      onCta: widget.onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('First name'),
          const SizedBox(height: 8),
          SynkTextField(
            controller: _name,
            hint: 'Your name',
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (v) => ref
                .read(onboardingProvider.notifier)
                .update((d) => d.copyWith(name: v)),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Birthday'),
          const SizedBox(height: 8),
          SynkBirthdayField(
            value: draft.birthday,
            now: widget.now,
            onChanged: (value) => ref
                .read(onboardingProvider.notifier)
                .update((d) => d.copyWith(birthday: value)),
          ),
          if (underage) ...[
            const SizedBox(height: 10),
            SynkText(
              'You must be $kMinAge or older to use $kAppName.',
              variant: SynkTextVariant.small,
              color: context.colors.destructive,
            ),
          ],
        ],
      ),
    );
  }
}
