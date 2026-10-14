import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/discover_providers.dart';
import '../../app/providers/session_providers.dart';
import '../../app/router/app_routes.dart';
import '../../core/config/app_info.dart';
import '../../design_system/design_system.dart';
import '../../domain/models/profile.dart';
import '../../shared/widgets/match_overlay.dart';
import '../../shared/brand/brand.dart';
import '../premium/premium_prompt.dart';
import 'feed_card.dart';
import 'filters_sheet.dart';

/// Discover tab: a vertical feed of everyone nearby. Each person is a full card with their
/// interests and their own pass / super like / like buttons (or swipe the card sideways). The
/// header hides while scrolling down and snaps back on the way up; pull down to refresh.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  Future<void> _showMatch(Profile other) async {
    final me = ref.read(sessionProvider).me;
    final notifier = ref.read(discoverProvider.notifier);
    if (me == null) {
      notifier.clearMatch();
      return;
    }
    final choice = await showMatchOverlay(context, me: me, other: other);
    notifier.clearMatch();
    if (choice == MatchChoice.message && mounted) {
      await context.push(AppRoutes.chat('c-${other.id}'));
    }
  }

  Future<void> _openFilters() async {
    final session = ref.read(sessionProvider);
    final next = await showFiltersSheet(
      context,
      current: ref.read(preferencesProvider),
      premium: session.premium,
      onPremiumTap: () => showPremiumPrompt(
        context,
        title: 'Verified-only is a Premium filter',
        body: 'Premium lets you see only selfie-verified people.',
      ),
    );
    if (next != null) ref.read(preferencesProvider.notifier).set(next);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(discoverProvider.select((s) => s.newMatch), (_, next) {
      if (next != null) _showMatch(next);
    });
    ref.listen(discoverProvider.select((s) => s.notice), (_, next) async {
      if (next != DiscoverNotice.superLikeLimit) return;
      ref.read(discoverProvider.notifier).clearNotice();
      await showPremiumPrompt(
        context,
        title: 'Out of Super Likes',
        body: 'Free accounts get one Super Like. Premium gives you five every day.',
      );
    });

    final state = ref.watch(discoverProvider);
    final colors = context.colors;
    final myInterests = {...?ref.watch(sessionProvider).me?.interests};
    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.foreground,
        backgroundColor: SynkPalette.cream,
        edgeOffset: 64,
        onRefresh: ref.read(discoverProvider.notifier).load,
        child: CustomScrollView(
          key: const PageStorageKey('discover-feed'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              toolbarHeight: 64,
              backgroundColor: colors.background,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 20,
              title: Row(
                children: [
                  const SynkText(kAppName, variant: SynkTextVariant.h2),
                  if (state.deck.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    SynkBadge(text: '${state.deck.length} nearby', small: true),
                  ],
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleIconButton(
                    icon: SynkIcons.settings,
                    semanticLabel: 'Filters',
                    tone: CircleButtonTone.soft,
                    onPressed: _openFilters,
                  ),
                ),
              ],
            ),
            ..._body(state, myInterests),
          ],
        ),
      ),
    );
  }

  /// Centres feed content and caps its width on tablets.
  static Widget _column(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: child,
    ),
  );

  List<Widget> _body(DiscoverState state, Set<String> myInterests) {
    if (state.failed) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: InlineState(
            icon: SynkIcons.alert,
            title: 'Could not load people',
            body: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: ref.read(discoverProvider.notifier).load,
          ),
        ),
      ];
    }
    if (state.loading && state.deck.isEmpty) {
      return [
        SliverList.builder(
          itemCount: 2,
          itemBuilder: (context, _) => _column(
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 28),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Skeleton(radius: SynkRadius.xxl),
              ),
            ),
          ),
        ),
      ];
    }
    if (state.deck.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: SynkIcons.users,
            title: 'You\'ve seen everyone nearby',
            body: 'Widen your filters or check back later for new people.',
            actionLabel: 'Adjust filters',
            onAction: _openFilters,
          ),
        ),
      ];
    }
    final notifier = ref.read(discoverProvider.notifier);
    return [
      SliverList.builder(
        itemCount: state.deck.length,
        itemBuilder: (context, i) {
          final profile = state.deck[i];
          return _column(
            FeedCard(
              key: ValueKey(profile.id),
              profile: profile,
              shared: {...profile.interests}.intersection(myInterests),
              onInfoTap: () => context.push(AppRoutes.profile(profile.id)),
              onAction: (action) => notifier.swipe(profile, action),
            ),
          );
        },
      ),
      SliverToBoxAdapter(
        child: _column(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              children: [
                const HeartSticker(size: 34, angle: -0.15),
                const SizedBox(height: 12),
                const SynkText(
                  'That\'s everyone for now',
                  variant: SynkTextVariant.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const SynkText(
                  'Pull down to refresh, or widen your filters to meet more people.',
                  variant: SynkTextVariant.muted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SynkButton(
                  label: 'Change filters',
                  variant: SynkButtonVariant.soft,
                  onPressed: _openFilters,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
