import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/settings_providers.dart';
import '../../design_system/design_system.dart';
import '../../shared/widgets/settings_tile.dart';

/// Which events send a push notification.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final settings = ref.read(settingsProvider.notifier);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            SubpageHeader(title: 'Notifications', onBack: context.pop),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  SettingsSection(
                    title: 'Push notifications',
                    children: [
                      SettingsTile(
                        icon: SynkIcons.heart,
                        title: 'New matches',
                        trailing: SynkSwitch(
                          value: s.pushMatches,
                          semanticLabel: 'New matches',
                          onChanged: (v) => settings.update(
                            (c) => c.copyWith(pushMatches: v),
                          ),
                        ),
                      ),
                      SettingsTile(
                        icon: SynkIcons.chat,
                        title: 'Messages',
                        trailing: SynkSwitch(
                          value: s.pushMessages,
                          semanticLabel: 'Messages',
                          onChanged: (v) => settings.update(
                            (c) => c.copyWith(pushMessages: v),
                          ),
                        ),
                      ),
                      SettingsTile(
                        icon: SynkIcons.flame,
                        title: 'Likes',
                        trailing: SynkSwitch(
                          value: s.pushLikes,
                          semanticLabel: 'Likes',
                          onChanged: (v) =>
                              settings.update((c) => c.copyWith(pushLikes: v)),
                        ),
                      ),
                    ],
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
