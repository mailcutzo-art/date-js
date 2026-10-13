import 'package:flutter/material.dart';

import '../foundation/tap_target.dart';
import '../tokens/synk_motion.dart';
import '../tokens/synk_theme.dart';

/// iOS-style switch (the Android `SynklySwitch`): 51x31 track, 27dp white knob with a 2dp
/// shadow, 2dp inset, 220 ms `cubic(0.32, 0.72, 0, 1)` slide. On is the primary colour, off is
/// `switchTrackOff`. Without [onChanged], or with [enabled] false, it is dimmed to 50 % and inert.
///
/// The touch area extends [hitSlop] (6dp) around the track; that margin is part of the widget's
/// layout box, pass `EdgeInsets.zero` for the bare 51x31 footprint.
class SynkSwitch extends StatelessWidget {
  const SynkSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.semanticLabel,
    this.hitSlop = const EdgeInsets.all(6),
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final String? semanticLabel;
  final EdgeInsets hitSlop;

  static const double trackWidth = 51;
  static const double trackHeight = 31;
  static const double knobSize = 27;
  static const double inset = 2;

  /// Soft 2dp elevation under the knob.
  static const List<BoxShadow> _knobShadow = <BoxShadow>[
    BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x14000000), blurRadius: 1, offset: Offset(0, 0.5)),
  ];

  bool get _active => enabled && onChanged != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const travel = trackWidth - knobSize - 2 * inset;

    final track = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value ? 1 : 0),
      duration: SynkMotion.switchToggle,
      curve: SynkMotion.smooth,
      builder: (context, t, _) {
        final trackColor = Color.lerp(colors.switchTrackOff, colors.primary, t);
        final knobOffset = travel * t;
        return Container(
          width: trackWidth,
          height: trackHeight,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(trackHeight / 2),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                start: inset + knobOffset,
                top: inset,
                child: Container(
                  width: knobSize,
                  height: knobSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: _knobShadow,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return TapTarget(
      properties: SemanticsProperties(
        toggled: value,
        enabled: _active,
        label: semanticLabel,
        onTap: _active ? () => onChanged!(!value) : null,
      ),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _active ? () => onChanged!(!value) : null,
          child: Opacity(
            opacity: _active ? 1 : 0.5,
            child: Padding(padding: hitSlop, child: track),
          ),
        ),
      ),
    );
  }
}
