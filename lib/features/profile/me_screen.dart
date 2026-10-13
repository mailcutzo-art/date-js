import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/session_providers.dart';
import '../../app/router/app_routes.dart';
import '../../design_system/design_system.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../../shared/widgets/settings_tile.dart';
import '../../shared/widgets/verified_badge.dart';

/// Profile tab: your card, the Premium upsell and the way into settings.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final me = session.me;
    final colors = context.colors;
    if (me == null) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const SynkText('Profile', variant: SynkTextVariant.h2),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(profile: me, size: 120, ring: true),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleIconButton(
                      icon: SynkIcons.pencil,
                      semanticLabel: 'Edit profile',
                      diameter: 38,
                      iconSize: 17,
                      onPressed: () => context.push(AppRoutes.editProfile),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SynkText('${me.name}, ${me.age}', variant: SynkTextVariant.h2),
                if (me.verified) ...[
                  const SizedBox(width: 8),
                  const VerifiedBadge(size: 20),
                ],
                if (session.premium) ...[
                  const SizedBox(width: 8),
                  const SynkBadge(
                    text: 'Premium',
                    variant: SynkBadgeVariant.amber,
                    small: true,
                  ),
                ],
              ],
            ),
            if (me.city.isNotEmpty) ...[
              const SizedBox(height: 4),
              SynkText(
                me.city,
                variant: SynkTextVariant.muted,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            if (!session.premium) ...[
              _PremiumCard(onTap: () => context.push(AppRoutes.premium)),
              const SizedBox(height: 24),
            ],
            SettingsSection(
              title: 'Your account',
              children: [
                SettingsTile(
                  icon: SynkIcons.pencil,
                  title: 'Edit profile',
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                SettingsTile(
                  icon: SynkIcons.lock,
                  title: 'Privacy and safety',
                  onTap: () => context.push(AppRoutes.privacy),
                ),
                SettingsTile(
                  icon: SynkIcons.settings,
                  title: 'Settings',
                  onTap: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PastelCard(
      tone: SynkTone.blush,
      onTap: onTap,
      semanticLabel: 'Go Premium',
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SynkText('Go Premium', variant: SynkTextVariant.cardTitle),
                SizedBox(height: 4),
                SynkText(
                  'See who likes you, get more Super Likes and browse privately.',
                  variant: SynkTextVariant.cardDescription,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SynkPalette.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const SynkIcon(SynkIcons.crown, color: SynkPalette.amber),
          ),
        ],
      ),
    );
  }
}
