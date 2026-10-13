import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/chat_providers.dart';
import '../../app/providers/discover_providers.dart';
import '../../app/providers/session_providers.dart';
import '../../app/router/app_routes.dart';
import '../../design_system/design_system.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/profile.dart';
import '../../shared/brand/brand.dart';
import '../../shared/widgets/photo_art.dart';
import '../../shared/widgets/verified_badge.dart';
import '../premium/premium_prompt.dart';

enum _MatchesTab { matches, likes }

/// Matches tab: everyone you matched with, and (for Premium) everyone who already likes you.
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  _MatchesTab _tab = _MatchesTab.matches;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final conversations = ref.watch(conversationsProvider);
    final likes = ref.watch(likesYouProvider);
    final likeCount = likes.maybeWhen(data: (l) => l.length, orElse: () => 0);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SynkText('Matches', variant: SynkTextVariant.h2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SynkSegmentedTabs<_MatchesTab>(
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
                options: [
                  const SynkTabOption(
                    value: _MatchesTab.matches,
                    label: 'Matches',
                  ),
                  SynkTabOption(
                    value: _MatchesTab.likes,
                    label: likeCount > 0
                        ? 'Likes you ($likeCount)'
                        : 'Likes you',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tab == _MatchesTab.matches
                  ? _MatchesGrid(
                      items: conversations.items,
                      loading: conversations.loading,
                    )
                  : _LikesGrid(likes: likes),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchesGrid extends StatelessWidget {
  const _MatchesGrid({required this.items, required this.loading});

  final List<Conversation> items;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) return const _GridSkeleton();
    if (items.isEmpty) {
      return EmptyState(
        icon: SynkIcons.heart,
        title: 'No matches yet',
        body: 'Keep swiping. When someone likes you back, they show up here.',
        actionLabel: 'Go to Discover',
        onAction: () => context.go(AppRoutes.discover),
      );
    }
    return _TileGrid(
      children: [
        for (final c in items)
          _ProfileTile(
            profile: c.other,
            badge: c.hasMessages ? null : 'New',
            onTap: () => context.push(AppRoutes.chat(c.id)),
          ),
      ],
    );
  }
}

class _LikesGrid extends ConsumerWidget {
  const _LikesGrid({required this.likes});

  final AsyncValue<List<Profile>> likes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(sessionProvider.select((s) => s.premium));
    return likes.when(
      loading: () => const _GridSkeleton(),
      error: (_, _) => InlineState(
        icon: SynkIcons.alert,
        title: 'Could not load likes',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(likesYouProvider),
      ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return const EmptyState(
            icon: SynkIcons.heart,
            title: 'No likes yet',
            body: 'People who like you will show up here.',
          );
        }
        final grid = _TileGrid(
          children: [
            for (final p in profiles)
              _ProfileTile(
                profile: p,
                blurred: !premium,
                onTap: () => premium
                    ? context.push(AppRoutes.profile(p.id))
                    : showPremiumPrompt(
                        context,
                        title: 'See who likes you',
                        body: 'Premium shows everyone who already likes you, so you can match instantly.',
                      ),
              ),
          ],
        );
        return Column(
          children: [
            if (!premium)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SynkCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => context.push(AppRoutes.premium),
                  child: Row(
                    children: [
                      const CrownDoodle(size: 28, angle: -0.1),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SynkText(
                          '${profiles.length} people like you. Unlock them with Premium.',
                          variant: SynkTextVariant.small,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: grid),
          ],
        );
      },
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: children,
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return _TileGrid(
      children: [
        for (var i = 0; i < 4; i++) const Skeleton(radius: SynkRadius.xl),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.onTap,
    this.badge,
    this.blurred = false,
  });

  final Profile profile;
  final VoidCallback onTap;
  final String? badge;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final seed = profile.photos.first.seed;
    Widget photo = PhotoArt(seed: seed);
    if (blurred) {
      photo = ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: photo,
        ),
      );
    }
    return SynkPressable(
      onTap: onTap,
      semanticLabel: blurred
          ? 'Locked profile, Premium'
          : '${profile.name}, ${profile.age}',
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          FramedPhoto(
            photo: photo,
            label: blurred ? null : '${profile.name}, ${profile.age}',
            radius: 18,
            frame: 6,
          ),
          if (blurred)
            const Center(
              child: SynkIcon(SynkIcons.lock, size: 28, color: Colors.white),
            ),
          if (badge != null) ...[
            Positioned(
              left: 12,
              top: 12,
              child: SynkBadge(text: badge!, small: true),
            ),
            const Positioned(
              right: -6,
              top: -8,
              child: HeartSticker(size: 30, angle: 0.25),
            ),
          ],
          if (profile.verified && !blurred)
            const Positioned(
              right: 12,
              bottom: 12,
              child: VerifiedBadge(size: 16),
            ),
        ],
      ),
    );
  }
}
