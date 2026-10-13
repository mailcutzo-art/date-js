import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Three dots that bounce in sequence inside an incoming-style bubble.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Typing',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: _bubbleRadius(fromMe: false),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                    child: Transform.translate(
                      offset: Offset(0, -4 * _bounce(_c.value, i)),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors.mutedForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 0..1 bump that travels across the three dots.
  double _bounce(double t, int index) {
    final phase = (t - index * 0.14) % 1;
    return phase < 0.4 ? math.sin(phase / 0.4 * math.pi) : 0;
  }
}

BorderRadius _bubbleRadius({required bool fromMe}) => BorderRadius.only(
  topLeft: const Radius.circular(20),
  topRight: const Radius.circular(20),
  bottomLeft: Radius.circular(fromMe ? 20 : 6),
  bottomRight: Radius.circular(fromMe ? 6 : 20),
);
