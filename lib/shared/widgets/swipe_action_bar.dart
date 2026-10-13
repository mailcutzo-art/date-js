import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Pass / super like / like buttons under the swipe deck. Each pops slightly while pressed.
class SwipeActionBar extends StatelessWidget {
  const SwipeActionBar({
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundAction(
          icon: SynkIcons.close,
          label: 'Pass',
          color: SynkPalette.youtubeRed,
          size: 60,
          onTap: enabled ? onPass : null,
        ),
        const SizedBox(width: 20),
        _RoundAction(
          icon: SynkIcons.spark,
          label: 'Super like',
          color: SynkPalette.indigo,
          size: 50,
          onTap: enabled ? onSuperLike : null,
        ),
        const SizedBox(width: 20),
        _RoundAction(
          icon: SynkIcons.heart,
          label: 'Like',
          color: SynkPalette.success,
          size: 60,
          onTap: enabled ? onLike : null,
        ),
      ],
    );
  }
}

class _RoundAction extends StatefulWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final SynkIcons icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  State<_RoundAction> createState() => _RoundActionState();
}

class _RoundActionState extends State<_RoundAction> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                SynkHapticsScope.of(context).play(SynkHaptic.impactLight);
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down ? 0.88 : 1,
          duration: const Duration(milliseconds: 90),
          curve: SynkMotion.easeOutQuad,
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: colors.card,
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withValues(alpha: 0.5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: SynkIcon(
                widget.icon,
                size: widget.size * 0.44,
                color: widget.color,
                strokeWidth: 2.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
