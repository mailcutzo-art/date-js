import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A [TapTarget] is described with the same properties as a `Semantics` widget.
export 'package:flutter/semantics.dart' show SemanticsProperties;

/// The smallest touch target the platform guidelines accept (Android 48 x 48 dp).
const Size kMinTapTarget = Size.square(48);

/// Semantics for a control whose tap area is at least [minSize], without changing its layout.
///
/// The child keeps its own size (a 44 dp circle stays 44 dp, so no screen reflows), but the
/// semantics node, and so TalkBack / VoiceOver focus, Switch Access and the platform's own
/// hit-testing of the node, spans [minSize] around it, and touches in that ring reach the child
/// too. It stands in for `Semantics(container: ..., ...)` on a button: pass the same
/// [properties].
///
/// The ring is only as large as the parent lets it be: a control that touches the edge of its
/// parent can only be enlarged on the sides that have room, so give small controls a little
/// breathing space (the design already spaces them by 8 dp or more).
class TapTarget extends SingleChildRenderObjectWidget {
  const TapTarget({
    required this.properties,
    this.container = false,
    this.excludeSemantics = false,
    this.minSize = kMinTapTarget,
    super.child,
    super.key,
  });

  final SemanticsProperties properties;

  /// Makes the control its own node (siblings never merge into one). A control whose size is
  /// grown here must be a container, or an ancestor that is one forms the node instead and the
  /// bounds are that ancestor's.
  final bool container;

  /// Drops the semantics of the descendants (the node is described by [properties] alone).
  final bool excludeSemantics;
  final Size minSize;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderTapTarget(
    properties: properties,
    container: container,
    excludeSemantics: excludeSemantics,
    minSize: minSize,
    textDirection: Directionality.maybeOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderTapTarget renderObject) {
    renderObject
      ..properties = properties
      ..container = container
      ..excludeSemantics = excludeSemantics
      ..minSize = minSize
      ..textDirection = Directionality.maybeOf(context);
  }
}

/// The render object of [TapTarget]: a semantics annotation whose bounds and hit-test area are
/// grown to the minimum tap target.
class RenderTapTarget extends RenderSemanticsAnnotations {
  RenderTapTarget({
    required super.properties,
    required Size minSize,
    super.container,
    super.excludeSemantics,
    super.textDirection,
  }) {
    _minSize = minSize;
  }

  late Size _minSize;
  Size get minSize => _minSize;
  set minSize(Size value) {
    if (value == _minSize) return;
    _minSize = value;
    markNeedsSemanticsUpdate();
  }

  /// How far the target reaches beyond the child on each side.
  EdgeInsets get _grow => EdgeInsets.symmetric(
    horizontal: math.max(0, (_minSize.width - size.width) / 2),
    vertical: math.max(0, (_minSize.height - size.height) / 2),
  );

  @override
  Rect get semanticBounds => _grow.inflateRect(Offset.zero & size);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_grow.inflateRect(Offset.zero & size).contains(position)) return false;
    // A touch in the ring lands on the nearest point of the child.
    final inside = Offset(
      position.dx.clamp(0.0, math.max(0.0, size.width - 0.01)),
      position.dy.clamp(0.0, math.max(0.0, size.height - 0.01)),
    );
    if (hitTestChildren(result, position: inside) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
