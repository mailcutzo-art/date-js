import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/session_providers.dart';
import '../../app/shell/root_shell.dart';
import '../../core/config/app_info.dart';
import '../../design_system/design_system.dart';
import '../../shared/brand/brand.dart';
import '../../shared/brand_colors.dart';

class _Plan {
  const _Plan(this.months, this.price, this.perMonth, {this.tag});

  final int months;
  final String price;
  final String perMonth;
  final String? tag;

  String get title => months == 1 ? '1 month' : '$months months';
}

const List<_Plan> _plans = [
  _Plan(1, '₹499', '₹499 / month'),
  _Plan(3, '₹999', '₹333 / month', tag: 'Save 33%'),
  _Plan(12, '₹2,999', '₹250 / month', tag: 'Best value'),
];

/// Premium paywall. The demo build has no billing, so "Continue" asks to unlock Premium for
/// this session only. Wire the plan picker to Play Billing (`in_app_purchase`) later.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  int _selected = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the system "remove animations" setting: the glow rests instead of looping.
    if (MediaQuery.disableAnimationsOf(context)) {
      _glow.stop();
    } else if (!_glow.isAnimating) {
      _glow.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final ok = await showConfirmSheet(
      context,
      title: 'Billing is not connected',
      description:
          'This is a demo build, so nothing is charged. Unlock Premium on this '
          'device to try the features?',
      cancelLabel: 'Not now',
      confirmLabel: 'Unlock for demo',
      destructive: false,
    );
    if (!ok || !mounted) return;
    ref.read(sessionProvider.notifier).setPremium(value: true);
    ref
        .read(toastControllerProvider)
        .show('Premium unlocked (demo)', variant: ToastVariant.success);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final premium = ref.watch(sessionProvider.select((s) => s.premium));
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: CircleIconButton(
                  icon: SynkIcons.close,
                  semanticLabel: 'Close',
                  tone: CircleButtonTone.soft,
                  diameter: 40,
                  onPressed: context.pop,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                children: [
                  _Hero(glow: _glow),
                  const SizedBox(height: 20),
                  SynkText(
                    premium ? 'Premium is active' : 'Go Premium',
                    variant: SynkTextVariant.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const SynkText(
                    'Meet people faster, with more control.',
                    variant: SynkTextVariant.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const _Benefit(SynkIcons.heart, 'See everyone who likes you'),
                  const _Benefit(SynkIcons.gem, '5 Super Likes every day'),
                  const _Benefit(
                    SynkIcons.checkCircle,
                    'Filter to verified profiles only',
                  ),
                  const _Benefit(SynkIcons.eyeOff, 'Incognito mode'),
                  if (!premium) ...[
                    const SizedBox(height: 24),
                    for (var i = 0; i < _plans.length; i++) ...[
                      _PlanCard(
                        plan: _plans[i],
                        selected: i == _selected,
                        onTap: () => setState(() => _selected = i),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (premium)
                    SynkButton(
                      label: 'Switch back to free (demo)',
                      variant: SynkButtonVariant.outline,
                      size: SynkButtonSize.lg,
                      expand: true,
                      onPressed: () {
                        ref
                            .read(sessionProvider.notifier)
                            .setPremium(value: false);
                        context.pop();
                      },
                    )
                  else ...[
                    SynkButton(
                      label: 'Continue with ${_plans[_selected].title}',
                      size: SynkButtonSize.lg,
                      expand: true,
                      onPressed: _continue,
                    ),
                    const SizedBox(height: 4),
                    SynkButton(
                      label: 'Restore purchases',
                      variant: SynkButtonVariant.ghost,
                      expand: true,
                      onPressed: () => ref
                          .read(toastControllerProvider)
                          .show(
                            'Nothing to restore',
                            description: 'Demo build.',
                          ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const SynkText(
                    '$kAppName Premium renews automatically until cancelled in Google Play.',
                    variant: SynkTextVariant.listDescription,
                    textAlign: TextAlign.center,
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

/// Poster hero: rippling brand waves, a crown on a cream starburst and "Date like a queen".
/// The waves slowly breathe (the starburst scales) unless animations are turned off.
class _Hero extends StatelessWidget {
  const _Hero({required this.glow});

  final Animation<double> glow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: SynkRadius.xxlAll,
      child: SizedBox(
        height: 236,
        child: Stack(
          children: [
            const Positioned.fill(
              child: WavyBackdrop(seed: 5, focus: Alignment(0.6, 0.3)),
            ),
            Positioned(
              right: -18,
              bottom: -26,
              child: AnimatedBuilder(
                animation: glow,
                builder: (context, child) => Transform.scale(
                  scale: 1 + 0.06 * Curves.easeInOut.transform(glow.value),
                  child: child,
                ),
                child: const Starburst(
                  size: 170,
                  child: CrownDoodle(size: 78, angle: -0.1),
                ),
              ),
            ),
            const Positioned(
              left: 18,
              top: 26,
              child: PosterTitle(
                lines: [
                  PosterLine('Date like a', scale: 0.55),
                  PosterLine('queen', scale: 1.2),
                ],
                size: 46,
                align: CrossAxisAlignment.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.text);

  final SynkIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SynkPalette.nightInk,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SynkPalette.cream, width: 1.5),
            ),
            alignment: Alignment.center,
            child: SynkIcon(icon, size: 18, color: SynkPalette.cream),
          ),
          const SizedBox(width: 14),
          Expanded(child: SynkText(text, variant: SynkTextVariant.p)),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final _Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: SynkPressable(
        onTap: onTap,
        semanticLabel:
            '${plan.title}, ${plan.price}'
            '${plan.tag == null ? '' : ', ${plan.tag}'}',
        selected: selected,
        child: AnimatedContainer(
          duration: SynkMotion.progress,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colors.creamSurface : colors.card,
            borderRadius: SynkRadius.lgAll,
            border: Border.all(
              color: selected ? colors.foreground : colors.border,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SynkText(plan.title, variant: SynkTextVariant.large),
                        if (plan.tag != null) ...[
                          const SizedBox(width: 8),
                          SynkBadge(text: plan.tag!, small: true),
                        ],
                      ],
                    ),
                    SynkText(plan.perMonth, variant: SynkTextVariant.muted),
                  ],
                ),
              ),
              SynkText(plan.price, variant: SynkTextVariant.large),
            ],
          ),
        ),
      ),
    );
  }
}
