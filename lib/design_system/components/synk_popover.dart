import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../icons/synk_icon.dart';
import '../tokens/synk_motion.dart';
import '../tokens/synk_palette.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Gap between the anchor and the popover and the minimum distance to the screen edges.
const double _kAnchorGap = 12;
const double _kEdgeMargin = 8;

/// Opens an anchored popover menu.
///
/// The popover sits below [anchor] (a rect in global coordinates) with a 12 dp gap plus
/// [offsetY], flips above when it does not fit and is clamped 8 dp from the screen edges;
/// [alignEnd] aligns the right edges instead of the left ones. The scrim is 20 % black and
/// absent when [glass] (which also gives the card a translucent, blurred surface).
///
/// The card is as wide as its widest content, between [minWidth] and [maxWidth]; the content
/// is measured intrinsically, so build a compact column (for example of [PopoverItem]s), not a
/// scrolling list. Tapping an item does not close the popover: call
/// `Navigator.of(context).pop(value)` from `onTap`.
Future<T?> showSynkPopover<T>(
  BuildContext context, {
  required Rect anchor,
  required WidgetBuilder builder,
  double minWidth = 200,
  double maxWidth = 320,
  double offsetY = 0,
  bool alignEnd = false,
  bool glass = false,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    _SynkPopoverRoute<T>(
      anchor: anchor,
      builder: builder,
      minWidth: minWidth,
      maxWidth: maxWidth,
      offsetY: offsetY,
      alignEnd: alignEnd,
      glass: glass,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
    ),
  );
}

/// The popover surface: radius 14, 1dp border, padding h8 v6.
///
/// This is what [showSynkPopover] renders; golden tests pump it directly.
class SynkPopoverCard extends StatelessWidget {
  const SynkPopoverCard({required this.child, this.glass = false, super.key});

  final Widget child;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final decoration = BoxDecoration(
      color: glass ? colors.glassOverlay : colors.card,
      borderRadius: SynkRadius.mdAll,
      border: Border.all(color: glass ? colors.glassBorder : colors.border),
      boxShadow: glass
          ? null
          : [
              BoxShadow(
                color: const Color(0xFF000000)
                    .withValues(alpha: colors.isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
    );
    Widget card = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        // Scrolls (instead of overflowing) when the menu is taller than the screen allows;
        // a single-child scroll view still reports intrinsic sizes.
        child: IntrinsicWidth(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child],
            ),
          ),
        ),
      ),
    );
    if (glass) {
      card = ClipRRect(
        borderRadius: SynkRadius.mdAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: card,
        ),
      );
    }
    return card;
  }
}

/// A row of a popover menu: padding h14 v10, radius 6, 15sp text (semibold and primary when
/// [selected]), foreground-at-8% press feedback. A null [onTap] renders it disabled.
class PopoverItem extends StatelessWidget {
  const PopoverItem({
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.destructive = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final SynkIcons? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The dark theme's primary is a fill colour and too dim as text on the dark card.
    final accent = colors.primaryText;
    final color = destructive
        ? colors.destructive
        : (selected ? accent : colors.foreground);
    final press = colors.foreground.withValues(alpha: 0.08);
    final enabled = onTap != null;
    final style = SynkTypography.of(SynkTextVariant.p).copyWith(
      fontSize: 15,
      fontWeight: selected || destructive ? FontWeight.w600 : FontWeight.w400,
    );
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            splashColor: press,
            highlightColor: press,
            hoverColor: press,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (icon != null) ...[
                    SynkIcon(icon!, size: SynkIconSize.base, color: color),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SynkText(label, color: color, style: style),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Route
// ---------------------------------------------------------------------------------------

class _SynkPopoverRoute<T> extends PopupRoute<T> {
  _SynkPopoverRoute({
    required this.anchor,
    required this.builder,
    required this.minWidth,
    required this.maxWidth,
    required this.offsetY,
    required this.alignEnd,
    required this.glass,
    required this.capturedThemes,
  });

  final Rect anchor;
  final WidgetBuilder builder;
  final double minWidth;
  final double maxWidth;
  final double offsetY;
  final bool alignEnd;
  final bool glass;
  final CapturedThemes capturedThemes;

  @override
  Color? get barrierColor => glass ? null : SynkPalette.popoverBackdrop;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Curve get barrierCurve => SynkMotion.popover;

  @override
  Duration get transitionDuration => SynkMotion.popoverIn;

  @override
  Duration get reverseTransitionDuration => SynkMotion.popoverOut;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return capturedThemes.wrap(
      Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: Material(
          type: MaterialType.transparency,
          child: CustomSingleChildLayout(
            delegate: _PopoverLayoutDelegate(
              anchor: anchor,
              minWidth: minWidth,
              maxWidth: maxWidth,
              offsetY: offsetY,
              alignEnd: alignEnd,
            ),
            child: AnimatedBuilder(
              animation: animation,
              child: SynkPopoverCard(
                glass: glass,
                child: Builder(builder: builder),
              ),
              builder: (context, child) {
                final v = animation.value.clamp(0.0, 1.0);
                // Closing mirrors the opening curve (1 - ease(t)) instead of easing in.
                final t = animation.status == AnimationStatus.reverse
                    ? 1 - SynkMotion.popover.transform(1 - v)
                    : SynkMotion.popover.transform(v);
                return Opacity(
                  opacity: t,
                  child: Transform.scale(
                    scale: 0.97 + 0.03 * t,
                    alignment: alignEnd
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    child: child,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Places the popover below the anchor (flipping above when it does not fit) and clamps it to
/// the screen with an 8 dp margin.
class _PopoverLayoutDelegate extends SingleChildLayoutDelegate {
  const _PopoverLayoutDelegate({
    required this.anchor,
    required this.minWidth,
    required this.maxWidth,
    required this.offsetY,
    required this.alignEnd,
  });

  final Rect anchor;
  final double minWidth;
  final double maxWidth;
  final double offsetY;
  final bool alignEnd;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final available = math.max(0.0, constraints.maxWidth - 2 * _kEdgeMargin);
    final max = math.min(maxWidth, available);
    return BoxConstraints(
      minWidth: math.min(minWidth, max),
      maxWidth: max,
      maxHeight: math.max(0.0, constraints.maxHeight - 2 * _kEdgeMargin),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = alignEnd ? anchor.right - childSize.width : anchor.left;
    final belowTop = anchor.bottom + _kAnchorGap + offsetY;
    final fitsBelow = belowTop + childSize.height + _kEdgeMargin <= size.height;
    final aboveTop = anchor.top - _kAnchorGap - offsetY - childSize.height;
    final top = fitsBelow ? belowTop : aboveTop;
    return Offset(
      _clamp(x, _kEdgeMargin, size.width - childSize.width - _kEdgeMargin),
      _clamp(top, _kEdgeMargin, size.height - childSize.height - _kEdgeMargin),
    );
  }

  /// `clamp` that tolerates `max < min` (a child larger than the screen).
  static double _clamp(double value, double min, double max) =>
      math.max(min, math.min(value, max));

  @override
  bool shouldRelayout(_PopoverLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.minWidth != minWidth ||
      oldDelegate.maxWidth != maxWidth ||
      oldDelegate.offsetY != offsetY ||
      oldDelegate.alignEnd != alignEnd;
}
