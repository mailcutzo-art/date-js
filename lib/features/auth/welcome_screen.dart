import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/session_providers.dart';
import '../../app/router/app_routes.dart';
import '../../core/config/app_info.dart';
import '../../design_system/design_system.dart';
import '../../shared/widgets/photo_art.dart';

/// First screen for a signed-out user: floating photo cards, the pitch and the two sign-in
/// choices.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: _FloatingCards()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: SynkSpace.columnMax,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SynkText(
                      'Dating that starts with a real hello.',
                      variant: SynkTextVariant.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const SynkText(
                      kAppTagline,
                      variant: SynkTextVariant.muted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SynkButton(
                      label: 'Continue with phone',
                      size: SynkButtonSize.lg,
                      expand: true,
                      onPressed: () => context.push(AppRoutes.signIn),
                    ),
                    const SizedBox(height: 12),
                    SynkButton(
                      label: 'Continue with Google',
                      variant: SynkButtonVariant.outline,
                      size: SynkButtonSize.lg,
                      expand: true,
                      onPressed: () => ref
                          .read(sessionProvider.notifier)
                          .continueWithGoogle(),
                    ),
                    const SizedBox(height: 16),
                    const SynkText(
                      'By continuing you agree to our Terms and Privacy Policy. '
                      'You must be 18 or older.',
                      variant: SynkTextVariant.listDescription,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three tilted photo cards that drift up and down out of phase (a 7 s loop).
class _FloatingCards extends StatefulWidget {
  const _FloatingCards();

  @override
  State<_FloatingCards> createState() => _FloatingCardsState();
}

class _FloatingCardsState extends State<_FloatingCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: DotGridBackground()),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_c.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                _card(seed: 12, angle: -0.16, dx: -92, dy: 22 - 16 * t),
                _card(seed: 33, angle: 0.15, dx: 92, dy: 6 + 14 * t),
                _card(seed: 52, angle: -0.02, dx: 0, dy: -10 + 12 * t),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _card({
    required int seed,
    required double angle,
    required double dx,
    required double dy,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 150,
          height: 210,
          decoration: const BoxDecoration(
            borderRadius: SynkRadius.xlAll,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: SynkRadius.xlAll,
            child: PhotoArt(seed: seed),
          ),
        ),
      ),
    );
  }
}
