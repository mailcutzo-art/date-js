import 'package:flutter/material.dart';

import 'tap_target.dart';

/// Tap target with Android-parity press feedback: the child dims while pressed
/// (`pressableOpacity`), an optional hit slop enlarges the touch area and the
/// semantics expose a button with an optional label.
class SynkPressable extends StatefulWidget {
  const SynkPressable({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedOpacity = 0.85,
    this.hitSlop = EdgeInsets.zero,
    this.enabled = true,
    this.semanticLabel,
    this.selected,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedOpacity;
  final EdgeInsets hitSlop;
  final bool enabled;
  final String? semanticLabel;
  final bool? selected;
  final HitTestBehavior behavior;

  @override
  State<SynkPressable> createState() => _SynkPressableState();
}

class _SynkPressableState extends State<SynkPressable> {
  bool _pressed = false;

  bool get _active =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    Widget result = AnimatedOpacity(
      opacity: _pressed && _active ? widget.pressedOpacity : 1,
      duration: const Duration(milliseconds: 80),
      child: widget.child,
    );
    if (widget.hitSlop != EdgeInsets.zero) {
      result = Padding(padding: widget.hitSlop, child: result);
    }
    return TapTarget(
      properties: SemanticsProperties(
        button: true,
        enabled: _active,
        selected: widget.selected,
        label: widget.semanticLabel,
        onTap: _active ? widget.onTap : null,
        onLongPress: _active ? widget.onLongPress : null,
      ),
      child: GestureDetector(
        // The Semantics above already exposes tap / long-press: the detector's own annotation
        // would add a second, unlabelled focus stop for screen readers.
        excludeFromSemantics: true,
        behavior: widget.behavior,
        onTapDown: _active ? (_) => _set(true) : null,
        onTapUp: _active ? (_) => _set(false) : null,
        onTapCancel: _active ? () => _set(false) : null,
        onTap: _active ? widget.onTap : null,
        onLongPress: _active ? widget.onLongPress : null,
        child: result,
      ),
    );
  }
}
