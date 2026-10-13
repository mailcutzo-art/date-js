import 'package:flutter/material.dart';

import '../foundation/pressable.dart';
import '../icons/synk_icon.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';

/// Small selectable pill (RSVP chips, filters): radius full, padding h14 v7, 12/600 label.
/// Selected is `primary` with `primaryForeground` text, unselected is `muted` with `foreground`
/// text. An optional [icon] leads and a [count] follows the label in a lighter weight.
///
/// With an [onTap] the chip is a button (pressed dims to 80 %, `selected` is exposed); without
/// one it is a read-only label.
class SynkChip extends StatelessWidget {
  const SynkChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final SynkIcons? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = selected ? colors.primary : colors.muted;
    final foreground = selected ? colors.primaryForeground : colors.foreground;
    final base = SynkTypography.of(SynkTextVariant.badge);
    final countValue = count;

    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: SynkRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            SynkIcon(icon!, size: SynkIconSize.sm, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(color: foreground),
            ),
          ),
          if (countValue != null) ...[
            const SizedBox(width: 6),
            Text(
              '$countValue',
              maxLines: 1,
              style: base.copyWith(
                color: foreground.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );

    final semanticsLabel = countValue == null ? label : '$label, $countValue';
    if (onTap == null) {
      return Semantics(
        label: semanticsLabel,
        selected: selected,
        child: ExcludeSemantics(child: pill),
      );
    }
    return SynkPressable(
      onTap: onTap,
      pressedOpacity: 0.8,
      selected: selected,
      semanticLabel: semanticsLabel,
      child: ExcludeSemantics(child: pill),
    );
  }
}
