import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/discover_providers.dart';
import '../../app/providers/session_providers.dart';
import '../../app/router/app_routes.dart';
import '../../core/config/app_info.dart';
import '../../design_system/design_system.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/swipe.dart';
import '../../shared/widgets/match_overlay.dart';
import '../../shared/widgets/swipe_action_bar.dart';
import '../../shared/widgets/swipe_deck.dart';
import '../premium/premium_prompt.dart';
import 'filters_sheet.dart';

/// Discover tab: the swipe deck with pass / super like / like buttons, filters and the match
/// celebration.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _deck = SwipeDeckController();

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
    final hasDeck = state.deck.isNotEmpty;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: SynkText(kAppName, variant: SynkTextVariant.h2),
                  ),
                  CircleIconButton(
                    icon: SynkIcons.settings,
                    semanticLabel: 'Filters',
                    tone: CircleButtonTone.soft,
                    onPressed: _openFilters,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _body(state),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SwipeActionBar(
                enabled: hasDeck,
                onPass: () => _deck.swipe(SwipeAction.pass),
                onSuperLike: () => _deck.swipe(SwipeAction.superLike),
                onLike: () => _deck.swipe(SwipeAction.like),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(DiscoverState state) {
    if (state.failed) {
      return InlineState(
        icon: SynkIcons.alert,
        title: 'Could not load people',
        body: 'Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: ref.read(discoverProvider.notifier).load,
      );
    }
    if (state.loading && state.deck.isEmpty) {
      return const Skeleton(radius: SynkRadius.xxl);
    }
    if (state.deck.isEmpty) {
      return EmptyState(
        icon: SynkIcons.users,
        title: 'You\'ve seen everyone nearby',
        body: 'Widen your filters or check back later for new people.',
        actionLabel: 'Adjust filters',
        onAction: _openFilters,
      );
    }
    return SwipeDeck(
      controller: _deck,
      profiles: state.deck,
      onInfoTap: (p) => context.push(AppRoutes.profile(p.id)),
      onSwiped: (profile, action) =>
          ref.read(discoverProvider.notifier).swipe(profile, action),
    );
  }
}
