import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Top bar of the multi-step setup: back button (hidden on the first step) and a progress bar.
class StepProgressHeader extends StatelessWidget {
  const StepProgressHeader({
    required this.step,
    required this.total,
    this.onBack,
    super.key,
  });

  /// Zero-based index of the current step.
  final int step;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: onBack == null
                ? null
                : CircleIconButton(
                    icon: SynkIcons.arrowLeft,
                    semanticLabel: 'Back',
                    tone: CircleButtonTone.soft,
                    diameter: 40,
                    onPressed: onBack,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (step + 1) / total),
              duration: SynkMotion.progress * 1.5,
              curve: SynkMotion.fastOutSlowIn,
              builder: (context, value, _) => SynkProgressBar(
                progress: value,
                height: 6,
                semanticLabel: 'Step ${step + 1} of $total',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
