import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/session_providers.dart';
import '../../app/providers/settings_providers.dart';
import '../../design_system/design_system.dart';
import '../../shared/widgets/settings_tile.dart';
import '../premium/premium_prompt.dart';

/// What others can see, plus safety tips.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final premium = ref.watch(sessionProvider.select((p) => p.premium));
    final settings = ref.read(settingsProvider.notifier);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            SubpageHeader(title: 'Privacy and safety', onBack: context.pop),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  SettingsSection(
                    title: 'What others see',
                    children: [
                      SettingsTile(
                        icon: SynkIcons.pin,
                        title: 'Show my distance',
                        trailing: SynkSwitch(
                          value: s.showDistance,
                          semanticLabel: 'Show my distance',
                          onChanged: (v) => settings.update(
                            (c) => c.copyWith(showDistance: v),
                          ),
                        ),
                      ),
                      SettingsTile(
                        icon: SynkIcons.cake,
                        title: 'Show my age',
                        trailing: SynkSwitch(
                          value: s.showAge,
                          semanticLabel: 'Show my age',
                          onChanged: (v) =>
                              settings.update((c) => c.copyWith(showAge: v)),
                        ),
                      ),
                      SettingsTile(
                        icon: SynkIcons.checkDouble,
                        title: 'Read receipts',
                        subtitle:
                            'Let matches see when you read their messages',
                        trailing: SynkSwitch(
                          value: s.readReceipts,
                          semanticLabel: 'Read receipts',
                          onChanged: (v) => settings.update(
                            (c) => c.copyWith(readReceipts: v),
                          ),
                        ),
                      ),
                      SettingsTile(
                        icon: SynkIcons.eyeOff,
                        title: 'Incognito mode',
                        subtitle: 'Only people you like can see you',
                        trailing: SynkSwitch(
                          value: premium && s.incognito,
                          semanticLabel: 'Incognito mode',
                          onChanged: (v) {
                            if (!premium) {
                              showPremiumPrompt(
                                context,
                                title: 'Browse privately',
                                body: 'Incognito mode is part of Premium.',
                              );
                              return;
                            }
                            settings.update((c) => c.copyWith(incognito: v));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionLabel('Stay safe'),
                  const SizedBox(height: 8),
                  const PastelCard(
                    tone: SynkTone.ice,
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Tip('Meet in a public place for the first few dates.'),
                        _Tip('Tell a friend where you are going and who with.'),
                        _Tip('Never send money to someone you have not met.'),
                        _Tip(
                          'Report anyone who makes you uncomfortable. It is anonymous.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3, right: 10),
            child: SynkIcon(SynkIcons.checkCircle, size: 16),
          ),
          Expanded(child: SynkText(text, variant: SynkTextVariant.small)),
        ],
      ),
    );
  }
}
