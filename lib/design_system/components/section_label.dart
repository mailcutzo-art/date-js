import 'package:flutter/material.dart';

import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Upper-cased muted section heading ("YOUR GROUPS"): `sectionLabel` (12/20/600, 1.0 tracking),
/// or the compact `sectionLabelSmall` (11/700, 0.6 tracking) when [small]. One line.
/// Screen readers get the text as written, announced as a heading.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.small = false});

  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: SynkText(
      text.toUpperCase(),
      variant: small
          ? SynkTextVariant.sectionLabelSmall
          : SynkTextVariant.sectionLabel,
      color: context.colors.mutedForeground,
      maxLines: 1,
      semanticsLabel: text,
    ),
  );
}
