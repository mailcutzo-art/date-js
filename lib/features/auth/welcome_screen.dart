import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/session_providers.dart';
import '../../app/router/app_routes.dart';
import '../../design_system/design_system.dart';
import '../../shared/brand/brand.dart';
import 'welcome_slides.dart';

/// First screen for a signed-out user: swipeable poster slides on wavy backgrounds, then the
/// pitch and the two sign-in choices on a black panel with a wavy top edge.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pages = PageController();
  int _page = 0;

  /// Height of the panel's wave; the panel is pulled up by this much so the slide shows
  /// through the wave instead of a flat edge.
  static const double _wave = 16;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SynkPalette.nightInk,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pages,
                  itemCount: WelcomeSlide.count,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => WelcomeSlide(index: i),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _wave * 2 + 8,
                  child: _Dots(count: WelcomeSlide.count, index: _page),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -_wave * 2),
            // The panel is always black, so it always uses the dark tokens (cream button).
            child: Theme(
              data: SynkThemeData.dark,
              child: InkPanel(
                amplitude: _wave,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: SynkSpace.columnMax,
                        ),
                        child: _Actions(
                          onPhone: () => context.push(AppRoutes.signIn),
                          onGoogle: () => ref
                              .read(sessionProvider.notifier)
                              .continueWithGoogle(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onPhone, required this.onGoogle});

  final VoidCallback onPhone;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SynkText(
          'Dating that starts with a real hello.',
          variant: SynkTextVariant.h2,
          color: Colors.white,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        SynkButton(
          label: 'Continue with phone',
          size: SynkButtonSize.lg,
          expand: true,
          onPressed: onPhone,
        ),
        const SizedBox(height: 10),
        SynkButton(
          label: 'Continue with Google',
          variant: SynkButtonVariant.outline,
          size: SynkButtonSize.lg,
          expand: true,
          contentColor: Colors.white,
          onPressed: onGoogle,
        ),
        const SizedBox(height: 12),
        const SynkText(
          'By continuing you agree to our Terms and Privacy Policy. '
          'You must be 18 or older.',
          variant: SynkTextVariant.listDescription,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Page indicator: the current page is a wide white pill, the others small dots.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Slide ${index + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: SynkMotion.progress,
                curve: SynkMotion.fastOutSlowIn,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                  borderRadius: SynkRadius.fullAll,
                  border: Border.all(color: SynkPalette.nightInk, width: 1.2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
