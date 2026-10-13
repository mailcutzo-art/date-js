import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/session_providers.dart';
import '../../app/shell/root_shell.dart';
import '../../core/config/app_info.dart';
import '../../design_system/design_system.dart';

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
  )..repeat(reverse: true);
  int _selected = 1;

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
                  const SizedBox(height: 24),
                  const _Benefit(SynkIcons.heart, 'See everyone who likes you'),
                  const _Benefit(SynkIcons.spark, '5 Super Likes every day'),
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

class _Hero extends StatelessWidget {
  const _Hero({required this.glow});

  final Animation<double> glow;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(glow.value);
        return Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: SynkRadius.xxlAll,
            gradient: LinearGradient(
              begin: Alignment(-1 + t, -1),
              end: Alignment(1, 1 - t),
              colors: const [
                Color(0xFFFFC371),
                Color(0xFFFF5F6D),
                Color(0xFFC6005C),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Transform.scale(
            scale: 1 + 0.08 * t,
            child: const SynkIcon(
              SynkIcons.crown,
              size: 64,
              color: Colors.white,
              strokeWidth: 1.6,
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SynkIcon(icon, size: 18, color: context.colors.primary),
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
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.card,
            borderRadius: SynkRadius.lgAll,
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 2 : 1,
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
                          SynkBadge(
                            text: plan.tag!,
                            variant: SynkBadgeVariant.amber,
                            small: true,
                          ),
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
