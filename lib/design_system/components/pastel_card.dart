import 'package:flutter/material.dart';

import '../foundation/pressable.dart';
import '../tokens/synk_colors.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';

/// Soft pastel surface of the refreshed UI (lavender / ice / blush) with generous padding and
/// the large 28dp corner radius. Dark mode uses the tinted dark equivalents of [SynkColors].
///
/// The pastel tones carry no outline (the fill alone separates them from the page); the
/// [SynkTone.neutral] tone is the plain card colour and therefore keeps the hairline border.
///
/// [background] is decorative art painted behind [child] and clipped to the card shape.
/// With [onTap] the card is a pressable button; [semanticLabel] names the card for screen
/// readers (merged with its text content when tappable).
class PastelCard extends StatelessWidget {
  const PastelCard({
    super.key,
    this.tone = SynkTone.lavender,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = SynkRadius.xxl,
    this.onTap,
    this.background,
    this.semanticLabel,
  });

  final SynkTone tone;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Widget? background;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget content = Padding(padding: padding, child: child);
    if (background != null) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: background!),
          content,
        ],
      );
    }
    Widget card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.toneSurface(tone),
        borderRadius: BorderRadius.circular(radius),
        border: tone == SynkTone.neutral
            ? Border.all(color: colors.border)
            : null,
      ),
      child: content,
    );
    if (onTap != null) {
      card = SynkPressable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: card,
      );
    } else if (semanticLabel != null) {
      card = Semantics(container: true, label: semanticLabel, child: card);
    }
    return card;
  }
}
