import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/models/profile.dart';
import '../brand/brand.dart';
import 'profile_avatar.dart';

/// Result of the "It's a match" screen.
enum MatchChoice { message, keepSwiping }

/// Shows the full-screen match celebration and returns what the user picked.
Future<MatchChoice> showMatchOverlay(
  BuildContext context, {
  required Profile me,
  required Profile other,
}) async {
  final choice = await showGeneralDialog<MatchChoice>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'It\'s a match',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => MatchOverlay(me: me, other: other),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
  return choice ?? MatchChoice.keepSwiping;
}

/// Two avatars slide together, the heart pops and confetti falls (about 1.4 s in total).
class MatchOverlay extends StatefulWidget {
  const MatchOverlay({required this.me, required this.other, super.key});

  final Profile me;
  final Profile other;

  @override
  State<MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<MatchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SynkHapticsScope.of(context).play(SynkHaptic.success);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const onDark = Colors.white;
    final slide = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    final pop = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.5, 0.8, curve: Curves.elasticOut),
    );
    final fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.6, 1, curve: Curves.easeOut),
    );
    // The celebration is always on the dark brand backdrop, whatever the theme.
    return Theme(
      data: SynkThemeData.dark,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            const Positioned.fill(
              child: WavyBackdrop(seed: 8, focus: Alignment(0, 0.05)),
            ),
            const Positioned.fill(child: ColoredBox(color: Color(0x4D0C0B0D))),
            SafeArea(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: Confetti(trigger: 1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: fade,
                          child: Transform.rotate(
                            angle: -0.05,
                            child: const SynkText(
                              'It\'s a match!',
                              variant: SynkTextVariant.poster,
                              color: onDark,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: fade,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: SynkPalette.nightInk,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SynkText(
                              'You and ${widget.other.name} like each other.',
                              variant: SynkTextVariant.bio,
                              color: SynkPalette.cream,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: slide,
                                builder: (context, child) =>
                                    Transform.translate(
                                      offset: Offset(-90 * slide.value - 20, 0),
                                      child: Transform.rotate(
                                        angle: -0.12 * slide.value,
                                        child: child,
                                      ),
                                    ),
                                child: ProfileAvatar(
                                  profile: widget.me,
                                  size: 130,
                                ),
                              ),
                              AnimatedBuilder(
                                animation: slide,
                                builder: (context, child) =>
                                    Transform.translate(
                                      offset: Offset(90 * slide.value + 20, 0),
                                      child: Transform.rotate(
                                        angle: 0.12 * slide.value,
                                        child: child,
                                      ),
                                    ),
                                child: ProfileAvatar(
                                  profile: widget.other,
                                  size: 130,
                                ),
                              ),
                              ScaleTransition(
                                scale: pop,
                                child: const HeartSticker(
                                  size: 64,
                                  angle: -0.12,
                                  fill: SynkPalette.hotMagenta,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 44),
                        FadeTransition(
                          opacity: fade,
                          child: Column(
                            children: [
                              SynkButton(
                                label: 'Send a message',
                                expand: true,
                                size: SynkButtonSize.lg,
                                onPressed: () =>
                                    Navigator.of(context)
                                        .pop(MatchChoice.message),
                              ),
                              const SizedBox(height: 12),
                              SynkButton(
                                label: 'Keep swiping',
                                variant: SynkButtonVariant.secondary,
                                expand: true,
                                size: SynkButtonSize.lg,
                                onPressed: () =>
                                    Navigator.of(context)
                                        .pop(MatchChoice.keepSwiping),
                              ),
                            ],
                          ),
                        ),
                      ],
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
