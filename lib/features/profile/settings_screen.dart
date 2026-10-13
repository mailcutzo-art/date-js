import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/onboarding_providers.dart';
import '../../app/providers/session_providers.dart';
import '../../app/router/app_routes.dart';
import '../../core/config/app_info.dart';
import '../../design_system/design_system.dart';
import '../../shared/widgets/settings_tile.dart';

/// Account settings: contact info, notification and privacy entry points, sign out and delete.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Sign out?',
      description: 'You can sign back in with your phone number any time.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Sign out',
      destructive: false,
    );
    if (!ok) return;
    ref.read(onboardingProvider.notifier).reset();
    ref.read(sessionProvider.notifier).signOut();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Delete your account?',
      description:
          'Your profile, matches and messages are removed for good. '
          'This cannot be undone.',
      cancelLabel: 'Keep my account',
      confirmLabel: 'Delete account',
    );
    if (!ok) return;
    // Demo build: signing out stands in for the delete-account API call.
    ref.read(onboardingProvider.notifier).reset();
    ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            SubpageHeader(title: 'Settings', onBack: context.pop),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  SettingsSection(
                    title: 'Account',
                    children: [
                      SettingsTile(
                        icon: SynkIcons.mail,
                        title: 'Phone number',
                        subtitle: session.phone.isEmpty
                            ? 'Signed in with Google'
                            : session.phone,
                      ),
                      SettingsTile(
                        icon: SynkIcons.crown,
                        title: 'Premium',
                        subtitle: session.premium
                            ? 'Active (demo)'
                            : 'Not subscribed',
                        onTap: () => context.push(AppRoutes.premium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SettingsSection(
                    title: 'Preferences',
                    children: [
                      SettingsTile(
                        icon: SynkIcons.chat,
                        title: 'Notifications',
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      SettingsTile(
                        icon: SynkIcons.lock,
                        title: 'Privacy and safety',
                        onTap: () => context.push(AppRoutes.privacy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SettingsSection(
                    title: 'Session',
                    children: [
                      SettingsTile(
                        icon: SynkIcons.signOut,
                        title: 'Sign out',
                        onTap: () => _signOut(context, ref),
                      ),
                      SettingsTile(
                        icon: SynkIcons.trash,
                        title: 'Delete account',
                        destructive: true,
                        onTap: () => _delete(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: SynkText(
                      '$kAppName demo build',
                      variant: SynkTextVariant.listDescription,
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
