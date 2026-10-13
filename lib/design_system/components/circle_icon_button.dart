import 'package:flutter/material.dart';

import '../icons/synk_icon.dart';
import '../tokens/synk_theme.dart';
import 'synk_button.dart';

/// Tone of a [CircleIconButton].
enum CircleButtonTone {
  /// Near-black fill with a light icon (the reference's black circle buttons).
  ink,

  /// Transparent with a thin border.
  outline,

  /// Muted / off-white fill.
  soft,
}

/// The reference's 44dp circular icon button. An optional [badge] (a dot, a count pill ...) is
/// pinned to the top-right corner and may overflow the circle. A [loading] button shows a small
/// spinner instead of the icon; disabled and loading buttons are dimmed to 50 % and ignore taps.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.tone = CircleButtonTone.ink,
    this.diameter = 44,
    this.iconSize = 20,
    this.badge,
    this.loading = false,
  });

  final SynkIcons icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final CircleButtonTone tone;
  final double diameter;
  final double iconSize;

  /// Overlay pinned to the top-right (top-left in RTL). Not interactive.
  final Widget? badge;
  final bool loading;

  SynkButtonVariant get _variant => switch (tone) {
    CircleButtonTone.ink => SynkButtonVariant.ink,
    CircleButtonTone.outline => SynkButtonVariant.outline,
    CircleButtonTone.soft => SynkButtonVariant.soft,
  };

  @override
  Widget build(BuildContext context) {
    final palette = SynkButtonColors.resolve(context.colors, _variant);
    final button = SynkButtonChrome(
      variant: _variant,
      shape: const CircleBorder(),
      constraints: BoxConstraints.tightFor(width: diameter, height: diameter),
      onPressed: onPressed,
      loading: loading,
      semanticLabel: semanticLabel,
      spinnerSize: (diameter * 0.4).clamp(12.0, 20.0),
      child: SynkIcon(icon, size: iconSize, color: palette.foreground),
    );
    if (badge == null) return button;
    // The badge is a sibling of the button (not inside its tap area or its semantics node);
    // fold a count into [semanticLabel] when it matters to screen-reader users.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        PositionedDirectional(
          top: -2,
          end: -2,
          child: IgnorePointer(child: badge),
        ),
      ],
    );
  }
}
