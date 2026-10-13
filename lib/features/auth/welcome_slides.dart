import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../shared/brand/brand.dart';
import '../../shared/widgets/interest_chips.dart';
import '../../shared/widgets/photo_art.dart';

/// The five poster slides of the welcome screen. Each slide paints its own wavy background
/// full-bleed and lays its artwork out on a fixed 360 x 540 canvas that scales to fit, so the
/// composition is identical on every screen size.
class WelcomeSlide extends StatelessWidget {
  const WelcomeSlide({required this.index, super.key});

  final int index;

  static const int count = 5;

  static const Size canvas = Size(360, 540);

  @override
  Widget build(BuildContext context) {
    final (style, seed, focus) = switch (index) {
      0 => (WavyStyle.stripes, 4, Alignment.center),
      1 => (WavyStyle.checker, 7, Alignment.center),
      2 => (WavyStyle.checker, 2, Alignment.center),
      3 => (WavyStyle.ripple, 5, const Alignment(0.2, 0.4)),
      _ => (WavyStyle.ripple, 9, const Alignment(-0.6, -0.2)),
    };
    final Widget art = switch (index) {
      0 => const _InterestsSlide(),
      1 => const _GhostingSlide(),
      2 => const _PeopleSlide(),
      3 => const _QueenSlide(),
      _ => const _KingSlide(),
    };
    return WavyBackdrop(
      style: style,
      seed: seed,
      focus: focus,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
          child: FittedBox(
            child: SizedBox.fromSize(size: canvas, child: art),
          ),
        ),
      ),
    );
  }
}

/// White phone-screen card with a black bezel.
class _Phone extends StatelessWidget {
  const _Phone({
    required this.width,
    required this.height,
    required this.child,
    this.screen = Colors.white,
  });

  final double width;
  final double height;
  final Widget child;
  final Color screen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: SynkPalette.nightInk,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(color: screen, child: child),
      ),
    );
  }
}

/// Organic black shape behind the artwork.
class _Blob extends StatelessWidget {
  const _Blob({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SynkPalette.nightInk,
        borderRadius: BorderRadius.all(
          Radius.elliptical(width / 2, height / 2),
        ),
      ),
    );
  }
}

/// Black, cream-outlined leg striding out from under the phone (the "ghosting" slide).
class _Leg extends StatelessWidget {
  const _Leg({required this.angle});

  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      alignment: Alignment.topCenter,
      child: Container(
        width: 74,
        height: 330,
        decoration: BoxDecoration(
          color: SynkPalette.nightInk,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(18),
            bottom: Radius.circular(37),
          ),
          border: Border.all(color: SynkPalette.cream, width: 5),
        ),
      ),
    );
  }
}

class _InterestsSlide extends StatelessWidget {
  const _InterestsSlide();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: PosterTitle(
            lines: [
              PosterLine('Match', scale: 0.9),
              PosterLine('via mutual', scale: 0.8),
              PosterLine('interests', scale: 1.15),
            ],
          ),
        ),
        const Positioned(
          left: -70,
          top: 180,
          child: _Blob(width: 150, height: 230),
        ),
        const Positioned(left: 8, top: 200, child: SwallowDoodle(width: 58)),
        Positioned(
          left: 70,
          top: 268,
          width: 240,
          height: 236,
          child: Transform.rotate(
            angle: 0.04,
            child: const _Phone(
              width: 240,
              height: 236,
              child: PhotoArt(seed: 12),
            ),
          ),
        ),
        const Positioned(
          left: 100,
          top: 206,
          child: CreamChip(label: 'Fun dates'),
        ),
        const Positioned(
          left: 222,
          top: 222,
          child: CreamChip(label: 'Cuddles'),
        ),
        const Positioned(
          left: 72,
          top: 262,
          child: CreamChip(label: 'Fantasies'),
        ),
        const Positioned(left: 168, top: 276, child: CreamChip(label: 'Artsy')),
        const Positioned(
          left: 240,
          top: 266,
          child: CreamChip(label: 'Nearby'),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.text, {required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? SynkPalette.nightInk : SynkPalette.cream,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: SynkTypography.of(SynkTextVariant.small).copyWith(
            color: mine ? Colors.white : SynkPalette.nightInk,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _GhostingSlide extends StatelessWidget {
  const _GhostingSlide();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(left: 46, top: 236, child: _Leg(angle: 0.16)),
        const Positioned(left: 210, top: 236, child: _Leg(angle: -0.14)),
        Positioned(
          left: 20,
          right: 20,
          top: -40,
          child: _Phone(
            width: 320,
            height: 300,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
              child: Column(
                children: [
                  const _Bubble('No disappearing acts?', mine: true),
                  const _Bubble('Not my style.', mine: false),
                  const _Bubble('Sounds rare', mine: true),
                  const _Bubble('So is my texting game.', mine: false),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final icon in const [
                        SynkIcons.discover,
                        SynkIcons.chats,
                        SynkIcons.cards,
                      ])
                        SynkIcon(
                          icon,
                          size: 20,
                          color: const Color(0xFF9A928A),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PosterTitle(
            lines: [
              PosterLine('No space', scale: 0.9),
              PosterLine('for', scale: 0.8),
              PosterLine('ghosting', scale: 1.3),
            ],
            angle: -0.05,
          ),
        ),
      ],
    );
  }
}

class _PeopleSlide extends StatelessWidget {
  const _PeopleSlide();

  @override
  Widget build(BuildContext context) {
    const people = [
      ('Michelle, 28', 21),
      ('Ana, 25', 33),
      ('Jordan, 27', 45),
      ('Max, 25', 57),
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 30,
          right: 30,
          top: -40,
          child: _Phone(
            width: 300,
            height: 380,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 40, 12, 10),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.9,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final (name, seed) in people)
                          FramedPhoto(
                            seed: seed,
                            label: name,
                            frame: 4,
                            radius: 12,
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final icon in const [
                        SynkIcons.discover,
                        SynkIcons.chats,
                        SynkIcons.cards,
                        SynkIcons.userCircle,
                      ])
                        SynkIcon(
                          icon,
                          size: 18,
                          color: const Color(0xFF9A928A),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 240,
          top: -6,
          child: HeartSticker(size: 30, angle: 0.3),
        ),
        const Positioned(
          left: 268,
          top: 34,
          child: HeartSticker(size: 22, angle: -0.2),
        ),
        const Positioned(
          left: 150,
          top: 136,
          child: HeartSticker(size: 20, angle: 0.1),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -10,
          child: Container(
            padding: const EdgeInsets.only(top: 26, bottom: 6),
            decoration: const BoxDecoration(
              color: SynkPalette.nightInk,
              borderRadius: BorderRadius.vertical(top: Radius.circular(60)),
            ),
            child: const PosterTitle(
              lines: [
                PosterLine('Real,', scale: 1.1),
                PosterLine('like-minded', scale: 0.8),
                PosterLine('people', scale: 0.8),
              ],
              size: 42,
              angle: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _QueenSlide extends StatelessWidget {
  const _QueenSlide();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: PosterTitle(
            lines: [
              PosterLine('Date like a', scale: 0.62),
              PosterLine('queen', scale: 1.5),
            ],
          ),
        ),
        Positioned(
          left: 40,
          top: 200,
          child: Transform.rotate(
            angle: -0.12,
            child: _Phone(
              width: 280,
              height: 360,
              screen: SynkPalette.plum,
              child: Stack(
                children: [
                  const Positioned(
                    left: 16,
                    top: 14,
                    child: SparkleDoodle(size: 14, color: SynkPalette.cream),
                  ),
                  const Positioned(
                    left: 40,
                    top: 48,
                    child: Starburst(
                      size: 200,
                      color: SynkPalette.hotMagenta,
                      seed: 11,
                    ),
                  ),
                  const Positioned(
                    left: 80,
                    top: 88,
                    width: 120,
                    height: 128,
                    child: FramedPhoto(seed: 64, frame: 0, radius: 6),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 22,
                    child: Text(
                      'I\'ve been told I bring too many good vibes',
                      style: SynkTypography.of(SynkTextVariant.bio)
                          .copyWith(color: SynkPalette.cream, fontSize: 19),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KingSlide extends StatelessWidget {
  const _KingSlide();

  @override
  Widget build(BuildContext context) {
    Widget square(SynkIcons icon) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: SynkPalette.nightInk,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: SynkIcon(icon, size: 16, color: Colors.white),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 20,
          right: 20,
          top: -40,
          child: _Phone(
            width: 320,
            height: 210,
            screen: SynkPalette.royalPurple,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 52, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attracted to authenticity, creativity and imagination',
                          style: SynkTypography.of(SynkTextVariant.bioSmall)
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'New York',
                          style: SynkTypography.of(SynkTextVariant.bioSmall)
                              .copyWith(
                                color: SynkPalette.cream.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: SynkPalette.flameOrange,
                    child: Stack(
                      children: [
                        const Positioned(
                          right: 14,
                          top: 44,
                          child: CrownDoodle(size: 46, angle: 0.15),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Row(
                            children: [
                              square(SynkIcons.gem),
                              const SizedBox(width: 8),
                              square(SynkIcons.heart),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 80,
          top: 170,
          child: Starburst(
            size: 200,
            child: CrownDoodle(size: 96, angle: -0.08),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PosterTitle(
            lines: [
              PosterLine('King of', scale: 0.9),
              PosterLine('the hill', scale: 1.05),
              PosterLine('always on top', scale: 0.62),
            ],
          ),
        ),
      ],
    );
  }
}
