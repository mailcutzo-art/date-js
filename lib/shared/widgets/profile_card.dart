import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/models/profile.dart';
import 'photo_art.dart';
import 'photo_progress_bars.dart';
import 'verified_badge.dart';

/// Full-bleed profile card used by the swipe deck. Tapping the left/right third of the photo
/// steps through the photos; the stamps fade in with the drag ([likeOpacity] etc.).
class ProfileCard extends StatefulWidget {
  const ProfileCard({
    required this.profile,
    this.likeOpacity = 0,
    this.nopeOpacity = 0,
    this.superOpacity = 0,
    this.onInfoTap,
    super.key,
  });

  final Profile profile;
  final double likeOpacity;
  final double nopeOpacity;
  final double superOpacity;
  final VoidCallback? onInfoTap;

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _index = 0;

  void _step(int delta) {
    final count = widget.profile.photos.length;
    final next = (_index + delta).clamp(0, count - 1);
    if (next != _index) setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final photo = profile.photos[_index.clamp(0, profile.photos.length - 1)];
    return ClipRRect(
      borderRadius: SynkRadius.xxlAll,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: PhotoArt(key: ValueKey(photo.id), seed: photo.seed),
          ),
          // Tap zones for the photo stack.
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _step(-1),
                ),
              ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _step(1),
                ),
              ),
            ],
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent],
                  stops: [0, 0.22],
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.55, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 12,
            child: PhotoProgressBars(
              count: profile.photos.length,
              index: _index,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _Caption(profile: profile, onInfoTap: widget.onInfoTap),
          ),
          Positioned(
            left: 24,
            top: 48,
            child: _Stamp(
              text: 'LIKE',
              color: SynkPalette.success,
              opacity: widget.likeOpacity,
              angle: -0.22,
            ),
          ),
          Positioned(
            right: 24,
            top: 48,
            child: _Stamp(
              text: 'NOPE',
              color: SynkPalette.youtubeRed,
              opacity: widget.nopeOpacity,
              angle: 0.22,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 140,
            child: Center(
              child: _Stamp(
                text: 'SUPER LIKE',
                color: SynkPalette.indigo,
                opacity: widget.superOpacity,
                angle: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.profile, required this.onInfoTap});

  final Profile profile;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    const onPhoto = Colors.white;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: SynkText(
                      '${profile.name}, ${profile.age}',
                      variant: SynkTextVariant.h2,
                      color: onPhoto,
                      maxLines: 1,
                    ),
                  ),
                  if (profile.verified) ...[
                    const SizedBox(width: 8),
                    const VerifiedBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SynkIcon(SynkIcons.pin, size: 14, color: onPhoto),
                  const SizedBox(width: 4),
                  Flexible(
                    child: SynkText(
                      '${profile.distanceKm} km away'
                      '${profile.job == null ? '' : '  ·  ${profile.job}'}',
                      variant: SynkTextVariant.small,
                      color: onPhoto,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (onInfoTap != null)
          CircleIconButton(
            icon: SynkIcons.info,
            semanticLabel: 'View ${profile.name}\'s profile',
            tone: CircleButtonTone.outline,
            diameter: 40,
            iconSize: 18,
            onPressed: onInfoTap,
          ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.text,
    required this.color,
    required this.opacity,
    required this.angle,
  });

  final String text;
  final Color color;
  final double opacity;
  final double angle;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
