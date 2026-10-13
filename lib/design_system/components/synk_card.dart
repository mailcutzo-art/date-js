import 'package:flutter/material.dart';

import '../foundation/pressable.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Solid card surface (`SynklyCard`): radius 18, card background, 1dp border, no elevation.
///
/// Compose it with [SynkCardHeader], [SynkCardContent] and [SynkCardFooter]:
///
/// ```dart
/// SynkCard(
///   child: Column(
///     crossAxisAlignment: CrossAxisAlignment.stretch,
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       SynkCardHeader(children: [SynkCardTitle('Plan'), SynkCardDescription('Billed monthly')]),
///       SynkCardContent(child: Text('...')),
///     ],
///   ),
/// )
/// ```
///
/// With [onTap] the whole card is a pressable button (dims while pressed).
class SynkCard extends StatelessWidget {
  const SynkCard({
    super.key,
    this.child,
    this.radius,
    this.padding,
    this.color,
    this.bordered = true,
    this.onTap,
  });

  final Widget? child;

  /// Defaults to [SynkRadius.lgAll] (18).
  final BorderRadius? radius;

  /// Extra padding around [child]. The header/content/footer helpers carry their own padding,
  /// so this is null by default.
  final EdgeInsetsGeometry? padding;

  /// Defaults to `colors.card`.
  final Color? color;

  /// Paints the 1dp `border` outline (default true).
  final bool bordered;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget card = Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? colors.card,
        borderRadius: radius ?? SynkRadius.lgAll,
        border: bordered ? Border.all(color: colors.border) : null,
      ),
      child: child,
    );
    if (onTap != null) {
      card = SynkPressable(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Combines the optional [child] with [children] into one list.
List<Widget> _slotChildren(Widget? child, List<Widget> children) => [
  ?child,
  ...children,
];

/// Card header: padding (20, 20, 20, 8), 6dp between its children. Fills the card width.
class SynkCardHeader extends StatelessWidget {
  const SynkCardHeader({super.key, this.child, this.children = const []});

  final Widget? child;
  final List<Widget> children;

  static const EdgeInsets padding = EdgeInsets.fromLTRB(20, 20, 20, 8);

  @override
  Widget build(BuildContext context) {
    final items = _slotChildren(child, children);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: items,
        ),
      ),
    );
  }
}

/// Card title (`cardTitle`, card foreground). Announced as a heading.
class SynkCardTitle extends StatelessWidget {
  const SynkCardTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: SynkText(
      text,
      variant: SynkTextVariant.cardTitle,
      color: context.colors.cardForeground,
    ),
  );
}

/// Card description (`cardDescription`, muted).
class SynkCardDescription extends StatelessWidget {
  const SynkCardDescription(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => SynkText(
    text,
    variant: SynkTextVariant.cardDescription,
    color: context.colors.mutedForeground,
  );
}

/// Card body: horizontal 20, vertical 12. Fills the card width.
class SynkCardContent extends StatelessWidget {
  const SynkCardContent({super.key, this.child, this.children = const []});

  final Widget? child;
  final List<Widget> children;

  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 12,
  );

  @override
  Widget build(BuildContext context) {
    final items = _slotChildren(child, children);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: padding,
        child: items.length == 1
            ? items.single
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items,
              ),
      ),
    );
  }
}

/// Card footer row: padding (20, 8, 20, 20), 8dp between its children.
class SynkCardFooter extends StatelessWidget {
  const SynkCardFooter({super.key, this.child, this.children = const []});

  final Widget? child;
  final List<Widget> children;

  static const EdgeInsets padding = EdgeInsets.fromLTRB(20, 8, 20, 20);

  @override
  Widget build(BuildContext context) {
    final items = _slotChildren(child, children);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: padding,
        child: Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: items,
        ),
      ),
    );
  }
}
