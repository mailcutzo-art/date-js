import 'package:flutter/material.dart';

import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';

/// Themed text. Colour resolution matches the Android `SynklyText`: explicit colour, then the
/// style's colour, then `mutedForeground` for the muted variants, otherwise `foreground`.
/// Overflow clips by default and ellipsizes when [maxLines] is set.
class SynkText extends StatelessWidget {
  const SynkText(
    this.data, {
    this.variant = SynkTextVariant.p,
    this.color,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
    this.semanticsLabel,
    super.key,
  });

  final String data;
  final SynkTextVariant variant;
  final Color? color;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;
  final String? semanticsLabel;

  static const Set<SynkTextVariant> _mutedVariants = {
    SynkTextVariant.muted,
    SynkTextVariant.cardDescription,
    SynkTextVariant.description,
    SynkTextVariant.listDescription,
    SynkTextVariant.toastDescription,
    SynkTextVariant.statUnit,
    SynkTextVariant.caption,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = SynkTypography.of(variant);
    final resolved =
        color ??
        style?.color ??
        (_mutedVariants.contains(variant)
            ? colors.mutedForeground
            : colors.foreground);
    return Text(
      data,
      style: base.merge(style).copyWith(color: resolved),
      maxLines: maxLines,
      overflow:
          overflow ??
          (maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip),
      textAlign: textAlign,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
  }
}

/// Mixed-weight headline ("Your **Groups**"): light base text with bold emphasis words.
class SynkDisplayText extends StatelessWidget {
  const SynkDisplayText({
    required this.parts,
    this.color,
    this.textAlign,
    this.maxLines,
    super.key,
  });

  /// Alternating segments; segments with `emphasis == true` render bold.
  final List<({String text, bool emphasis})> parts;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;

  /// Convenience: `SynkDisplayText.of('Your ', 'Groups')` (plain, emphasis).
  factory SynkDisplayText.of(
    String plain,
    String emphasis, {
    Color? color,
    Key? key,
  }) => SynkDisplayText(
    key: key,
    color: color,
    parts: [(text: plain, emphasis: false), (text: emphasis, emphasis: true)],
  );

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? context.colors.foreground;
    final base = SynkTypography.of(SynkTextVariant.display)
        .copyWith(color: resolved);
    final bold = SynkTypography.displayEmphasis().copyWith(color: resolved);
    return Text.rich(
      TextSpan(
        children: [
          for (final p in parts)
            TextSpan(text: p.text, style: p.emphasis ? bold : base),
        ],
        style: base,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
