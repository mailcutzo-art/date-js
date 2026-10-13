import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/onboarding_providers.dart';
import '../../app/providers/session_providers.dart';
import '../../design_system/design_system.dart';
import '../../shared/widgets/step_progress_header.dart';
import 'steps/about_step.dart';
import 'steps/done_step.dart';
import 'steps/gender_step.dart';
import 'steps/location_step.dart';
import 'steps/name_step.dart';
import 'steps/photos_step.dart';
import 'steps/verify_step.dart';

/// Seven-step profile setup in one screen. Steps slide horizontally; the system back button
/// walks one step back before it leaves the screen.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({this.now, super.key});

  /// Injectable clock (age checks), for tests.
  final DateTime Function()? now;

  static const int stepCount = 7;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _pages = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _go(int step) async {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    await _pages.animateToPage(
      step,
      duration: SynkMotion.page,
      curve: SynkMotion.smooth,
    );
  }

  void _next() => _go(_step + 1);

  void _finish() {
    final draft = ref.read(onboardingProvider);
    final now = (widget.now ?? DateTime.now)();
    ref
        .read(sessionProvider.notifier)
        .completeOnboarding(draft.toProfile(now), draft.toPreferences());
    ref.read(onboardingProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      NameStep(onNext: _next, now: widget.now),
      GenderStep(onNext: _next),
      PhotosStep(onNext: _next),
      AboutStep(onNext: _next),
      LocationStep(onNext: _next),
      VerifyStep(onNext: _next),
      DoneStep(onFinish: _finish, now: widget.now),
    ];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _go(_step - 1);
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          child: Column(
            children: [
              StepProgressHeader(
                step: _step,
                total: SetupScreen.stepCount,
                onBack: _step == 0 ? null : () => _go(_step - 1),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: steps,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
