import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Wrapping list of interest chips. With [onToggle] the chips are selectable; without it they
/// are read-only labels (profile detail). [highlight] marks interests shared with the viewer.
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
          SynkChip(
            label: interest,
            selected: onToggle != null
                ? selected.contains(interest)
                : highlight.contains(interest),
            onTap: onToggle == null ? null : () => onToggle!(interest),
          ),
      ],
    );
  }
}
