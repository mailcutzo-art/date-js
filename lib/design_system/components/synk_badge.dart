import 'package:flutter/material.dart';

import '../tokens/synk_colors.dart';
import '../tokens/synk_palette.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Colourways of [SynkBadge].
///
/// [primary] .. [destructive] port the Android `BadgeVariant`; [ink] is the black pill of the
/// refreshed UI ("72% Used"); [success] and [amber] are tinted status pills.
enum SynkBadgeVariant {
  primary,
  secondary,
  muted,
  outline,
  destructive,
  ink,
  success,
  amber,
}

/// Pill badge (`SynklyBadge`). Normal badges are 26dp tall; [small] badges are 20dp tall and
/// render their text upper-cased ("Owner" shows as "OWNER"). Screen readers still read the text
/// as given.
class SynkBadge extends StatelessWidget {
  const SynkBadge({
    super.key,
    required this.text,
    this.variant = SynkBadgeVariant.primary,
    this.small = false,
    this.leading,
  });

  final String text;
  final SynkBadgeVariant variant;
  final bool small;

  /// Optional widget before the text (typically a 10-12dp icon).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = _resolve(colors, variant);
    final style = small
        ? SynkTypography.of(SynkTextVariant.badgeSmall)
        : SynkTypography.of(SynkTextVariant.badge);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.background,
        shape: StadiumBorder(
          side: scheme.border == null
              ? BorderSide.none
              : BorderSide(color: scheme.border!),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: small ? 20 : 26),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              ?leading,
              Flexible(
                child: SynkText(
                  small ? text.toUpperCase() : text,
                  style: style,
                  color: scheme.foreground,
                  maxLines: 1,
                  semanticsLabel: text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ({Color background, Color foreground, Color? border}) _resolve(
    SynkColors c,
    SynkBadgeVariant variant,
  ) {
    switch (variant) {
      case SynkBadgeVariant.primary:
        return (
          background: c.primary,
          foreground: c.primaryForeground,
          border: null,
        );
      case SynkBadgeVariant.secondary:
        return (
          background: c.secondary,
          foreground: c.secondaryForeground,
          border: null,
        );
      case SynkBadgeVariant.muted:
        return (
          background: c.muted,
          foreground: c.mutedForeground,
          border: null,
        );
      case SynkBadgeVariant.outline:
        return (
          background: Colors.transparent,
          foreground: c.foreground,
          border: c.border,
        );
      case SynkBadgeVariant.destructive:
        // The dark-theme destructive red is light: dark text keeps the 12sp label legible.
        return (
          background: c.destructive,
          foreground: c.isDark ? c.inkForeground : c.primaryForeground,
          border: null,
        );
      case SynkBadgeVariant.ink:
        return (background: c.ink, foreground: c.inkForeground, border: null);
      case SynkBadgeVariant.success:
        return (
          background: SynkPalette.success.withValues(alpha: 0.15),
          foreground: c.isDark
              ? SynkPalette.success
              : Color.lerp(SynkPalette.successText, c.foreground, 0.35)!,
          border: null,
        );
      case SynkBadgeVariant.amber:
        return (
          background: SynkPalette.amber.withValues(alpha: 0.15),
          foreground: c.isDark
              ? SynkPalette.amberLight
              : Color.lerp(SynkPalette.amberDark, c.foreground, 0.25)!,
          border: null,
        );
    }
  }
}
