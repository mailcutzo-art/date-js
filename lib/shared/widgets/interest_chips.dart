import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Wrapping list of interest chips. With [onToggle] the chips are selectable; without it they
/// are read-only cream labels (profile detail) and [highlight] (interests shared with the
/// viewer) turns magenta.
class InterestChips extends StatelessWidget {
  const InterestChips({
    required this.interests,
    this.selected = const {},
    this.highlight = const {},
    this.onToggle,
    super.key,
  });

  final List<String> interests;
  final Set<String> selected;
  final Set<String> highlight;
  final ValueChanged<String>? onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final interest in interests)
          if (onToggle != null)
            SynkChip(
              label: interest,
              selected: selected.contains(interest),
              onTap: () => onToggle!(interest),
            )
          else
            CreamChip(
              label: interest,
              highlighted: highlight.contains(interest),
            ),
      ],
    );
  }
}

/// Read-only cream pill (the brand's interest tag). [highlighted] fills it magenta.
class CreamChip extends StatelessWidget {
  const CreamChip({required this.label, this.highlighted = false, super.key});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: highlighted,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: highlighted ? SynkPalette.hotMagenta : SynkPalette.cream,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SynkTypography.of(SynkTextVariant.badge)
                .copyWith(color: SynkPalette.nightInk),
          ),
        ),
      ),
    );
  }
}
