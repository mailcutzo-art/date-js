import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Pass / super like / like buttons under the swipe deck: ink rounded squares with a light
/// outline (X, gem, heart). Each pops slightly while pressed.
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
          size: 58,
          onTap: enabled ? onPass : null,
        ),
        const SizedBox(width: 18),
        _RoundAction(
          icon: SynkIcons.gem,
          label: 'Super like',
          size: 50,
          accent: true,
          onTap: enabled ? onSuperLike : null,
        ),
        const SizedBox(width: 18),
        _RoundAction(
          icon: SynkIcons.heart,
          label: 'Like',
          size: 58,
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
    required this.size,
    required this.onTap,
    this.accent = false,
  });

  final SynkIcons icon;
  final String label;
  final double size;

  /// Magenta icon (super like) instead of white.
  final bool accent;
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
    final outline = colors.isDark ? SynkPalette.cream : Colors.white;
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
                color: SynkPalette.nightInk,
                borderRadius: BorderRadius.circular(widget.size * 0.28),
                border: Border.all(color: outline, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: SynkIcon(
                widget.icon,
                size: widget.size * 0.44,
                color: widget.accent ? SynkPalette.hotMagenta : Colors.white,
                strokeWidth: 2.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
