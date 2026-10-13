import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/swipe.dart';
import '../../shared/widgets/interest_chips.dart';
import '../../shared/widgets/profile_card.dart';
import '../../shared/widgets/swipe_action_bar.dart';

/// One person in the Discover feed: the framed photo card, their interests (shared ones in
/// magenta) and their own pass / super like / like buttons.
///
/// Swiping the card sideways passes (left) or likes (right). A button press slides the card
/// out, then folds its space away so the next person moves up smoothly; with animations turned
/// off the action is immediate.
class FeedCard extends StatefulWidget {
  const FeedCard({
    required this.profile,
    required this.onAction,
    this.shared = const {},
    this.onInfoTap,
    super.key,
  });

  final Profile profile;
  final Set<String> shared;
  final ValueChanged<SwipeAction> onAction;
  final VoidCallback? onInfoTap;

  /// Most interests shown on a card; the full list is on the profile page.
  static const int maxInterests = 6;

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  SwipeAction? _leaving;

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  Future<void> _act(SwipeAction action) async {
    if (_leaving != null) return;
    if (!MediaQuery.disableAnimationsOf(context)) {
      setState(() => _leaving = action);
      await _exit.forward();
      if (!mounted) return;
    }
    widget.onAction(action);
    // The parent drops this card in the same frame; reset in case it is put back (a refused
    // super like).
    if (mounted) {
      _exit.value = 0;
      setState(() => _leaving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final interests = profile.interests.take(FeedCard.maxInterests).toList();
    final card = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Dismissible(
              key: ValueKey('swipe-${profile.id}'),
              resizeDuration: null,
              background: const _SwipeHint(
                text: 'LIKE',
                color: SynkPalette.hotMagenta,
                alignment: Alignment.centerLeft,
              ),
              secondaryBackground: const _SwipeHint(
                text: 'NOPE',
                color: SynkPalette.flameOrange,
                alignment: Alignment.centerRight,
              ),
              onDismissed: (direction) => widget.onAction(
                direction == DismissDirection.startToEnd
                    ? SwipeAction.like
                    : SwipeAction.pass,
              ),
              child: ProfileCard(profile: profile, onInfoTap: widget.onInfoTap),
            ),
          ),
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 14),
            InterestChips(interests: interests, highlight: widget.shared),
          ],
          const SizedBox(height: 16),
          SwipeActionBar(
            enabled: _leaving == null,
            onPass: () => _act(SwipeAction.pass),
            onSuperLike: () => _act(SwipeAction.superLike),
            onLike: () => _act(SwipeAction.like),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: _exit,
      child: card,
      builder: (context, child) {
        final leaving = _leaving;
        if (leaving == null) return child!;
        final slide = Curves.easeIn.transform(
          (_exit.value / 0.6).clamp(0.0, 1.0),
        );
        final fold = Curves.easeInOut.transform(
          ((_exit.value - 0.6) / 0.4).clamp(0.0, 1.0),
        );
        final width = MediaQuery.sizeOf(context).width;
        final (dx, dy, angle) = switch (leaving) {
          SwipeAction.pass => (-width * slide, 0.0, -0.18 * slide),
          SwipeAction.like => (width * slide, 0.0, 0.18 * slide),
          SwipeAction.superLike => (0.0, -120.0 * slide, 0.0),
        };
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1 - fold,
            child: Opacity(
              opacity: 1 - slide,
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(angle: angle, child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// What shows under a card while it is dragged sideways.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.text,
    required this.color,
    required this.alignment,
  });

  final String text;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: SynkRadius.xxlAll),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Text(
        text,
        style: SynkTypography.of(SynkTextVariant.poster)
            .copyWith(color: SynkPalette.nightInk),
      ),
    );
  }
}
