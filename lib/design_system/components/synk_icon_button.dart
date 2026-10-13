import 'package:flutter/material.dart';

import '../icons/synk_icon.dart';
import '../tokens/synk_theme.dart';
import 'synk_button.dart';

/// Circular icon-only button. Ghost by default; the icon takes the variant's content colour
/// unless [tint] is given. [semanticLabel] is required because there is no visible text.
///
/// Disabled (`onPressed == null`) and [loading] buttons are dimmed to 50 % and ignore taps.
class SynkIconButton extends StatelessWidget {
  const SynkIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.variant = SynkButtonVariant.ghost,
    this.size = 40,
    this.iconSize = 18,
    this.strokeWidth = kDefaultIconStroke,
    this.tint,
    this.loading = false,
  });

  final SynkIcons icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final SynkButtonVariant variant;

  /// Diameter of the button.
  final double size;
  final double iconSize;
  final double strokeWidth;

  /// Overrides the icon colour.
  final Color? tint;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = SynkButtonColors.resolve(context.colors, variant);
    return SynkButtonChrome(
      variant: variant,
      shape: const CircleBorder(),
      constraints: BoxConstraints.tightFor(width: size, height: size),
      onPressed: onPressed,
      loading: loading,
      semanticLabel: semanticLabel,
      spinnerSize: (size * 0.5).clamp(12.0, 20.0),
      child: SynkIcon(
        icon,
        size: iconSize,
        strokeWidth: strokeWidth,
        color: tint ?? palette.foreground,
      ),
    );
  }
}
