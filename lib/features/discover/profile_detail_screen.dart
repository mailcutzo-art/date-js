import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/chat_providers.dart';
import '../../app/providers/discover_providers.dart';
import '../../app/providers/profile_lookup_providers.dart';
import '../../app/providers/session_providers.dart';
import '../../design_system/design_system.dart';
import '../../shared/brand_colors.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/swipe.dart';
import '../../shared/brand/brand.dart';
import '../../shared/widgets/interest_chips.dart';
import '../../shared/widgets/photo_carousel.dart';
import '../../shared/widgets/swipe_action_bar.dart';
import '../../shared/widgets/verified_badge.dart';
import '../chat/safety_actions.dart';

/// Full profile of one person: photo pager, facts, bio and interests (shared ones highlighted).
/// When the person is still in the user's deck, like / pass buttons float at the bottom.
class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({required this.profileId, super.key});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileByIdProvider(profileId));
    if (profile == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SubpageHeader(title: 'Profile', onBack: context.pop),
              const Expanded(
                child: EmptyState(
                  title: 'Profile not found',
                  body: 'This person may have left the app.',
                ),
              ),
            ],
          ),
        ),
      );
    }
    final colors = context.colors;
    final me = ref.watch(sessionProvider).me;
    final isMe = me?.id == profile.id;
    final inDeck = ref
        .watch(discoverProvider)
        .deck
        .any((p) => p.id == profile.id);
    final shared = {...profile.interests}.intersection({...?me?.interests});
    final height = MediaQuery.sizeOf(context).width * 1.2;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: inDeck ? 120 : 32),
            children: [
              SizedBox(
                height: height,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(SynkRadius.xxl),
                  ),
                  child: PhotoCarousel(photos: profile.photos),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _Facts(profile: profile, shared: shared),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 0),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: SynkIcons.arrowLeft,
                    semanticLabel: 'Back',
                    tone: CircleButtonTone.ink,
                    onPressed: context.pop,
                  ),
                  const Spacer(),
                  if (!isMe)
                    CircleIconButton(
                      icon: SynkIcons.more,
                      semanticLabel: 'More options',
                      tone: CircleButtonTone.ink,
                      onPressed: () => _more(context, ref, profile),
                    ),
                ],
              ),
            ),
          ),
          if (inDeck)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.background.withValues(alpha: 0),
                      colors.background,
                    ],
                    stops: const [0, 0.35],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 28, bottom: 14),
                    child: SwipeActionBar(
                      onPass: () =>
                          _swipe(context, ref, profile, SwipeAction.pass),
                      onSuperLike: () =>
                          _swipe(context, ref, profile, SwipeAction.superLike),
                      onLike: () =>
                          _swipe(context, ref, profile, SwipeAction.like),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _swipe(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    SwipeAction action,
  ) {
    ref.read(discoverProvider.notifier).swipe(profile, action);
    context.pop();
  }

  Future<void> _more(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final matched =
        ref.read(conversationsProvider.notifier).byId('c-${profile.id}') !=
        null;
    final choice = await showSynkBottomSheet<String>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(children: [SheetTitle(profile.name)]),
          const SizedBox(height: 8),
          SynkButton(
            label: 'Report',
            variant: SynkButtonVariant.secondary,
            leadingIcon: SynkIcons.alert,
            onPressed: () => Navigator.of(sheet).pop('report'),
          ),
          const SizedBox(height: 8),
          SynkButton(
            label: 'Block',
            variant: SynkButtonVariant.secondary,
            leadingIcon: SynkIcons.blocked,
            onPressed: () => Navigator.of(sheet).pop('block'),
          ),
          if (matched) ...[
            const SizedBox(height: 8),
            SynkButton(
              label: 'Unmatch',
              variant: SynkButtonVariant.destructive,
              leadingIcon: SynkIcons.userMinus,
              onPressed: () => Navigator.of(sheet).pop('unmatch'),
            ),
          ],
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    final bool left;
    if (choice == 'report') {
      left = await SafetyActions.report(context, ref, profile);
    } else if (choice == 'block') {
      left = await SafetyActions.block(context, ref, profile);
    } else {
      left = await SafetyActions.unmatch(context, ref, profile);
    }
    if (left && context.mounted) context.pop();
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.profile, required this.shared});

  final Profile profile;
  final Set<String> shared;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: SynkText(
                '${profile.name}, ${profile.age}',
                variant: SynkTextVariant.h1,
                maxLines: 1,
              ),
            ),
            if (profile.verified) ...[
              const SizedBox(width: 10),
              const VerifiedBadge(size: 22),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (profile.job != null)
          _Fact(icon: SynkIcons.user, text: profile.job!),
        _Fact(
          icon: SynkIcons.pin,
          text:
              '${profile.city.isEmpty ? 'Nearby' : profile.city}'
              '${profile.distanceKm > 0 ? '  ·  ${profile.distanceKm} km away' : ''}',
        ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 24),
          _AboutPanel(bio: profile.bio, city: profile.city),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionLabel('Interests'),
          const SizedBox(height: 10),
          InterestChips(interests: profile.interests, highlight: shared),
          if (shared.isNotEmpty) ...[
            const SizedBox(height: 10),
            SynkText(
              'You both like ${shared.length == 1 ? shared.first : '${shared.length} of these'}.',
              variant: SynkTextVariant.small,
              color: colors.brandText,
            ),
          ],
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final SynkIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SynkIcon(icon, size: 16, color: context.colors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(child: SynkText(text, variant: SynkTextVariant.muted)),
        ],
      ),
    );
  }
}

/// The "about" card: serif bio on royal purple with an orange strip and a crown doodle.
class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.bio, required this.city});

  final String bio;
  final String city;

  @override
  Widget build(BuildContext context) {
    // Always dark: the panel colour does not change with the theme.
    return Theme(
      data: SynkThemeData.dark,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: SynkPalette.royalPurple,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SynkPalette.nightInk, width: 2),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 14, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('About'),
                          const SizedBox(height: 8),
                          SynkText(
                            bio,
                            variant: SynkTextVariant.bio,
                            color: Colors.white,
                          ),
                          if (city.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SynkText(
                              city,
                              variant: SynkTextVariant.bioSmall,
                              color: SynkPalette.cream,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                    child: ColoredBox(color: SynkPalette.flameOrange),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            right: 2,
            top: -26,
            child: CrownDoodle(size: 48, angle: 0.18),
          ),
        ],
      ),
    );
  }
}
