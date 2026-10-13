import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

import '../foundation/tap_target.dart';
import '../icons/synk_icon.dart';
import '../tokens/synk_motion.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_button.dart' show synkSoftFill;

/// One pill of a [SynkPillTabs]: a label, an optional trailing [count] and an optional icon.
@immutable
class SynkPillOption<T> {
  const SynkPillOption({
    required this.value,
    required this.label,
    this.count,
    this.icon,
  });

  final T value;
  final String label;

  /// Rendered after the label in a lighter weight ("All 1273").
  final int? count;
  final SynkIcons? icon;
}

/// The reference's pill tabs ("Organization / Teams / Users"): full-radius pills, at least 40dp
/// tall with 18dp side padding. The selected pill is the near-black `ink` pill with light text,
/// the others are muted. Colours animate over 180 ms.
///
/// By default the pills scroll horizontally, fade out at an edge that has more content and the
/// selected pill is scrolled into view when it changes. With `scrollable: false` they wrap onto
/// several lines instead. [padding] is applied around the pills inside the scroll area, so the
/// first pill can line up with the page gutter while the list still bleeds to the screen edge.
/// [onChanged] only fires when a different pill is tapped.
class SynkPillTabs<T> extends StatelessWidget {
  const SynkPillTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
  });

  final List<SynkPillOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool scrollable;
  final EdgeInsets padding;

  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = options.indexWhere((o) => o.value == selected);

    Widget pillAt(int index, {Key? key}) {
      final option = options[index];
      return _Pill(
        key: key,
        label: option.label,
        count: option.count,
        icon: option.icon,
        selected: index == selectedIndex,
        onTap: () {
          if (option.value != selected) onChanged(option.value);
        },
      );
    }

    final Widget body = scrollable
        ? _PillScroller(
            padding: padding,
            itemCount: options.length,
            selectedIndex: selectedIndex,
            itemBuilder: (index, key) => pillAt(index, key: key),
          )
        : Padding(
            padding: padding,
            child: Semantics(
              container: true,
              role: SemanticsRole.tabBar,
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (var i = 0; i < options.length; i++) pillAt(i)],
              ),
            ),
          );
    return body;
  }
}

class _Pill extends StatefulWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final SynkIcons? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;
    final background = selected ? colors.ink : synkSoftFill(colors);
    final labelColor = selected
        ? colors.inkForeground
        : colors.foreground.withValues(alpha: 0.72);
    final countColor = selected
        ? colors.inkForeground.withValues(alpha: 0.65)
        : colors.mutedForeground;
    final base = SynkTypography.of(SynkTextVariant.tab);
    const duration = Duration(milliseconds: 180);

    final count = widget.count;
    final icon = widget.icon;
    final semanticsLabel = count == null
        ? widget.label
        : '${widget.label}, $count';

    return TapTarget(
      properties: SemanticsProperties(
        role: SemanticsRole.tab,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        label: semanticsLabel,
        onTap: widget.onTap,
      ),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.85 : 1,
            duration: const Duration(milliseconds: 80),
            child: AnimatedContainer(
              duration: duration,
              curve: SynkMotion.fastOutSlowIn,
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: background,
                borderRadius: SynkRadius.fullAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    SynkIcon(icon, size: SynkIconSize.md, color: labelColor),
                    const SizedBox(width: 6),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: base.copyWith(color: labelColor),
                    maxLines: 1,
                    child: Text(widget.label),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    AnimatedDefaultTextStyle(
                      duration: duration,
                      style: base.copyWith(
                        color: countColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      child: Text('$count'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scroller with edge fades (only on the side that has more content) that keeps the
/// selected item visible.
class _PillScroller extends StatefulWidget {
  const _PillScroller({
    required this.padding,
    required this.itemCount,
    required this.selectedIndex,
    required this.itemBuilder,
  });

  final EdgeInsets padding;
  final int itemCount;
  final int selectedIndex;
  final Widget Function(int index, Key key) itemBuilder;

  @override
  State<_PillScroller> createState() => _PillScrollerState();
}

class _PillScrollerState extends State<_PillScroller> {
  static const double _fadeWidth = 28;

  final ScrollController _controller = ScrollController();
  List<GlobalKey> _keys = const <GlobalKey>[];
  bool _fadeStart = false;
  bool _fadeEnd = false;

  @override
  void initState() {
    super.initState();
    _syncKeys();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _revealSelected(animate: false),
    );
  }

  @override
  void didUpdateWidget(_PillScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _revealSelected(animate: true),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncKeys() {
    if (_keys.length != widget.itemCount) {
      _keys = List<GlobalKey>.generate(widget.itemCount, (_) => GlobalKey());
    }
  }

  /// Scrolls the selected pill to the middle when it is not fully inside the viewport.
  void _revealSelected({required bool animate}) {
    if (!mounted || !_controller.hasClients) return;
    final index = widget.selectedIndex;
    if (index < 0 || index >= _keys.length) return;
    final itemContext = _keys[index].currentContext;
    final viewport = context.findRenderObject();
    final item = itemContext?.findRenderObject();
    if (itemContext == null ||
        viewport is! RenderBox ||
        item is! RenderBox ||
        !viewport.hasSize ||
        !item.hasSize) {
      return;
    }
    final viewportRect = viewport.localToGlobal(Offset.zero) & viewport.size;
    final itemRect = item.localToGlobal(Offset.zero) & item.size;
    final inside =
        itemRect.left >= viewportRect.left &&
        itemRect.right <= viewportRect.right;
    if (inside) return;
    Scrollable.ensureVisible(
      itemContext,
      alignment: 0.5,
      duration: animate ? SynkMotion.page : Duration.zero,
      curve: SynkMotion.fastOutSlowIn,
    ).ignore();
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    _updateFades(notification.metrics);
    return false;
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0) _updateFades(notification.metrics);
    return false;
  }

  void _updateFades(ScrollMetrics metrics) {
    final start = metrics.extentBefore > 0.5;
    final end = metrics.extentAfter > 0.5;
    if (start == _fadeStart && end == _fadeEnd) return;
    setState(() {
      _fadeStart = start;
      _fadeEnd = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < widget.itemCount; i++) {
      if (i > 0) children.add(const SizedBox(width: SynkPillTabs.gap));
      children.add(widget.itemBuilder(i, _keys[i]));
    }
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) {
            final fade = (_fadeWidth / rect.width).clamp(0.0, 0.5);
            const clear = Color(0x00FFFFFF);
            const solid = Color(0xFFFFFFFF);
            return LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [
                _fadeStart ? clear : solid,
                solid,
                solid,
                _fadeEnd ? clear : solid,
              ],
              stops: [0, fade, 1 - fade, 1],
            ).createShader(rect, textDirection: Directionality.of(context));
          },
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            // The tab bar role lives inside the scroll view so that its direct children are the
            // tabs (a scroll view adds its own semantics node in between otherwise).
            child: Semantics(
              container: true,
              role: SemanticsRole.tabBar,
              child: Row(children: children),
            ),
          ),
        ),
      ),
    );
  }
}
