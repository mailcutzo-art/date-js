import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../tokens/synk_motion.dart';
import '../tokens/synk_palette.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Geometry and gesture constants of the bottom sheet (ported from `SynklyBottomSheet`).
abstract final class _SheetSpec {
  static const double minHeight = 120;
  static const double handleAreaHeight = 28;
  static const double handleWidth = 56;
  static const double handleHeight = 5;
  static const double contentStart = 20;
  static const double contentTop = 2;

  /// Drag distance (dp) past which a release dismisses the sheet.
  static const double dismissDistance = 120;

  /// Fling velocity (dp/s) past which a release dismisses the sheet.
  static const double dismissVelocity = 800;
}

/// Opens a Synkly bottom sheet on the navigator.
///
/// The sheet is a custom overlay (not a Material sheet): it opens with the
/// [SynkMotion.sheetOpen] spring, closes with a 220 ms tween, follows the finger and dismisses
/// past 120 dp / 800 dp/s, otherwise springs back. It lifts above the keyboard and clears any
/// focused field when it closes.
///
/// * [canDismiss] is consulted for every user dismissal (scrim tap, Back, drag). Returning
///   `false` refuses and the sheet springs back. Programmatic `Navigator.pop` is never refused.
/// * [isDismissible] `false` turns every user dismissal off (scrim, Back and drag).
/// * [scrollable] wraps the content in a scroll view so content taller than the sheet scrolls.
///   Pass `false` when the content manages its own scrolling (for example a scrolling body with
///   pinned buttons); the content then receives bounded height and may use `Flexible`.
/// * The content is built below the keyboard lift and the bottom safe area, so it must not add
///   `viewInsets` or `SafeArea` padding of its own (both are removed from its `MediaQuery`).
///
/// Close from inside the content with `Navigator.of(context).pop(result)`.
Future<T?> showSynkBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool solid = true,
  double maxHeightFraction = 0.92,
  bool showHandle = true,
  bool isDismissible = true,
  bool Function()? canDismiss,
  bool useRootNavigator = true,
  bool scrollable = true,
  String? semanticLabel,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    _SynkSheetRoute<T>(
      builder: builder,
      solid: solid,
      maxHeightFraction: maxHeightFraction,
      showHandle: showHandle,
      isDismissible: isDismissible,
      canDismiss: canDismiss,
      scrollable: scrollable,
      semanticLabel: semanticLabel,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
    ),
  );
}

/// The visual sheet: rounded top, 1dp border, drag handle and padded, scrolling content.
///
/// This is what [showSynkBottomSheet] renders; golden tests pump it directly. Its height is
/// clamped between 120 dp and [maxHeightFraction] of the bounded parent height (the screen
/// height when the parent is unbounded). It needs a bounded width.
class SynkBottomSheetFrame extends StatelessWidget {
  const SynkBottomSheetFrame({
    required this.child,
    this.solid = true,
    this.showHandle = true,
    this.maxHeightFraction = 0.92,
    this.scrollable = true,
    super.key,
  });

  final Widget child;

  /// `true` paints the card colour, `false` the drawer colour.
  final bool solid;
  final bool showHandle;
  final double maxHeightFraction;

  /// Wrap [child] in a scroll view (default). See [showSynkBottomSheet].
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final navInset = MediaQuery.viewPaddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final host = _SheetScope.maybeOf(context);
    final background = solid ? colors.card : colors.drawer;
    final handleColor = colors.mutedForeground.withValues(
      alpha: colors.isDark ? 0.45 : 0.35,
    );
    final padding = EdgeInsets.fromLTRB(
      _SheetSpec.contentStart,
      _SheetSpec.contentTop,
      _SheetSpec.contentStart,
      math.max(12, navInset + 8),
    );

    // Everything below consumes the bottom safe area and the keyboard, so content never
    // pads for them a second time.
    final mediaQuery = MediaQuery.of(context);
    final content = MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(bottom: 0),
        viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0),
        viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0),
      ),
      child: child,
    );

    final scrollBehavior = ScrollConfiguration.of(context).copyWith(
      overscroll: false,
      physics: host == null
          ? const ClampingScrollPhysics()
          : _SheetScrollPhysics(host, parent: const ClampingScrollPhysics()),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : screenHeight;
        final maxHeight = math.max(
          _SheetSpec.minHeight,
          available * maxHeightFraction,
        );
        final body = scrollable
            ? SingleChildScrollView(padding: padding, child: content)
            : Padding(padding: padding, child: content);
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _SheetSpec.minHeight,
            maxHeight: maxHeight,
          ),
          child: ClipRRect(
            borderRadius: SynkRadius.sheetTop,
            child: CustomPaint(
              foregroundPainter: _SheetBorderPainter(
                color: colors.border,
                radius: SynkRadius.xl,
              ),
              child: ColoredBox(
                color: background,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showHandle)
                      ExcludeSemantics(
                        child: SizedBox(
                          height: _SheetSpec.handleAreaHeight,
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: handleColor,
                                borderRadius: BorderRadius.circular(
                                  _SheetSpec.handleHeight / 2,
                                ),
                              ),
                              child: const SizedBox(
                                width: _SheetSpec.handleWidth,
                                height: _SheetSpec.handleHeight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: ScrollConfiguration(
                        behavior: scrollBehavior,
                        child: body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 1dp outline of the sheet; the bottom edge is drawn outside the clip so only the top and
/// the sides show.
class _SheetBorderPainter extends CustomPainter {
  const _SheetBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 1.0;
    final rrect = RRect.fromLTRBAndCorners(
      0,
      0,
      size.width,
      size.height + 2 * radius,
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    ).deflate(width / 2);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SheetBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Header block of a sheet: children stacked with a 6 dp gap and 8 dp below.
class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Sheet title (`drawerTitle` style).
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: SynkText(text, variant: SynkTextVariant.drawerTitle),
    );
  }
}

/// Muted sheet description.
class SheetDescription extends StatelessWidget {
  const SheetDescription(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SynkText(text, variant: SynkTextVariant.description);
  }
}

/// Button row at the bottom of a sheet: 10 dp gap, 8 dp above. Wrap children in `Expanded`
/// for equal-width buttons.
class SheetFooter extends StatelessWidget {
  const SheetFooter({
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    super.key,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Route
// ---------------------------------------------------------------------------------------

class _SynkSheetRoute<T> extends PopupRoute<T> {
  _SynkSheetRoute({
    required this.builder,
    required this.solid,
    required this.maxHeightFraction,
    required this.showHandle,
    required this.isDismissible,
    required this.canDismiss,
    required this.scrollable,
    required this.semanticLabel,
    required this.capturedThemes,
  });

  final WidgetBuilder builder;
  final bool solid;
  final double maxHeightFraction;
  final bool showHandle;
  final bool isDismissible;
  final bool Function()? canDismiss;
  final bool scrollable;
  final String? semanticLabel;
  final CapturedThemes capturedThemes;

  // The page draws its own scrim (it follows the drag) and handles taps itself.
  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  /// The open spring is driven by the page, so the route is "open" at once; only the close
  /// keeps the route alive for the length of the 220 ms close tween.
  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => SynkMotion.sheetOut;

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
    return capturedThemes.wrap(_SheetPage<T>(route: this));
  }
}

/// What nested scrollables (and the sheet's own scroll view) need from the sheet.
abstract interface class _SheetDragHost {
  bool get dragEnabled;

  /// Current downward displacement of the sheet in dp.
  double get offsetPx;

  void nestedDragBy(double dy);

  void nestedRelease(double velocityDown);
}

class _SheetScope extends InheritedWidget {
  const _SheetScope({required this.host, required super.child});

  final _SheetDragHost host;

  static _SheetDragHost? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SheetScope>()?.host;

  @override
  bool updateShouldNotify(_SheetScope oldWidget) => host != oldWidget.host;
}

/// Nested-scroll handoff: while the sheet is displaced an upward drag first brings the sheet
/// back before it scrolls the content, and a downward drag with the content at its start moves
/// the sheet instead of overscrolling.
class _SheetScrollPhysics extends ScrollPhysics {
  const _SheetScrollPhysics(this.host, {super.parent});

  final _SheetDragHost host;

  @override
  _SheetScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SheetScrollPhysics(host, parent: buildParent(ancestor));

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    var delta = super.applyPhysicsToUserOffset(position, offset);
    if (!host.dragEnabled || delta == 0) return delta;
    if (delta < 0) {
      // Finger moves up.
      final displaced = host.offsetPx;
      if (displaced > 0) {
        final used = math.min(displaced, -delta);
        host.nestedDragBy(-used);
        delta += used;
      }
    } else if (position.pixels <= position.minScrollExtent) {
      // Finger moves down with the content already at its start.
      host.nestedDragBy(delta);
      delta = 0;
    }
    return delta;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // The scroll drag just ended: `velocity` is negative for a downward fling.
    host.nestedRelease(-velocity);
    return super.createBallisticSimulation(position, velocity);
  }
}

class _SheetPage<T> extends StatefulWidget {
  const _SheetPage({required this.route});

  final _SynkSheetRoute<T> route;

  @override
  State<_SheetPage<T>> createState() => _SheetPageState<T>();
}

class _SheetPageState<T> extends State<_SheetPage<T>>
    with SingleTickerProviderStateMixin
    implements _SheetDragHost {
  /// Closed fraction of the sheet extent: 1 is fully off-screen, 0 fully open. Drags add to
  /// it, so a single value covers opening, dragging, snapping back and closing.
  late final AnimationController _closed = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  final GlobalKey _extentKey = GlobalKey();
  late final Animation<double> _routeAnimation;

  bool _closing = false;
  bool _gestureDrag = false;
  bool _nestedDrag = false;

  _SynkSheetRoute<T> get _route => widget.route;

  @override
  void initState() {
    super.initState();
    _routeAnimation = _route.animation!;
    _routeAnimation.addStatusListener(_onRouteStatus);
    final status = _routeAnimation.status;
    if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) {
      _closing = true;
    } else {
      unawaited(
        _closed.animateWith(SpringSimulation(SynkMotion.sheetOpen, 1, 0, 0)),
      );
    }
  }

  @override
  void dispose() {
    _routeAnimation.removeStatusListener(_onRouteStatus);
    _closed.dispose();
    super.dispose();
  }

  // -- state --------------------------------------------------------------------------

  /// Height of the sheet plus its keyboard lift, i.e. the distance to slide off-screen.
  double get _extent {
    final box = _extentKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0;
  }

  @override
  bool get dragEnabled => !_closing && _route.isDismissible;

  @override
  double get offsetPx => math.max(0.0, _closed.value) * _extent;

  // -- closing ------------------------------------------------------------------------

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) {
      _startClosing();
    }
  }

  void _startClosing() {
    if (_closing) return;
    setState(() => _closing = true);
    _clearFocus();
    unawaited(
      _closed.animateTo(
        1,
        duration: SynkMotion.sheetOut,
        curve: SynkMotion.sheetClose,
      ),
    );
  }

  /// A field inside the sheet that still has focus is force-cleared (hiding the keyboard) as
  /// the sheet closes.
  void _clearFocus() {
    final focused = FocusManager.instance.primaryFocus;
    final inside =
        focused?.context?.findAncestorStateOfType<_SheetPageState<T>>() == this;
    if (inside) focused!.unfocus();
  }

  /// Scrim tap, Back or a drag release past the threshold. Returns whether the sheet closes.
  bool _tryDismiss() {
    if (_closing || !_route.isCurrent || !_route.isDismissible) return false;
    final canDismiss = _route.canDismiss;
    if (canDismiss != null && !canDismiss()) return false;
    _route.navigator?.pop();
    return true;
  }

  void _requestDismiss() {
    if (_closing) return;
    if (!_tryDismiss()) _snapBack(0);
  }

  void _snapBack(double velocityDown) {
    final extent = _extent;
    if (extent <= 0) return;
    unawaited(
      _closed.animateWith(
        SpringSimulation(
          SynkMotion.sheetSnapBack,
          _closed.value,
          0,
          velocityDown / extent,
        ),
      ),
    );
  }

  // -- dragging -----------------------------------------------------------------------

  void _dragBy(double dy) {
    final extent = _extent;
    if (!dragEnabled || extent <= 0) return;
    _closed.value = math.max(0.0, _closed.value + dy / extent);
  }

  void _release(double velocityDown) {
    if (_closing) return;
    final dismiss =
        offsetPx > _SheetSpec.dismissDistance ||
        velocityDown > _SheetSpec.dismissVelocity;
    if (dismiss && _tryDismiss()) return;
    _snapBack(velocityDown);
  }

  @override
  void nestedDragBy(double dy) {
    _nestedDrag = true;
    _dragBy(dy);
  }

  @override
  void nestedRelease(double velocityDown) {
    if (!_nestedDrag) return;
    _nestedDrag = false;
    _release(velocityDown);
  }

  void _onDragStart(DragStartDetails details) {
    _gestureDrag = true;
    _closed.stop();
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_gestureDrag) return;
    _gestureDrag = false;
    _release(details.primaryVelocity ?? 0);
  }

  void _onDragCancel() {
    if (!_gestureDrag) return;
    _gestureDrag = false;
    _release(0);
  }

  // -- build --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final navInset = MediaQuery.viewPaddingOf(context).bottom;
    final lift = math.max(0.0, insets - navInset);
    final route = _route;

    final sheet = GestureDetector(
      onVerticalDragStart: route.isDismissible ? _onDragStart : null,
      onVerticalDragUpdate: route.isDismissible
          ? (details) => _dragBy(details.delta.dy)
          : null,
      onVerticalDragEnd: route.isDismissible ? _onDragEnd : null,
      onVerticalDragCancel: route.isDismissible ? _onDragCancel : null,
      child: Padding(
        key: _extentKey,
        padding: EdgeInsets.only(bottom: lift),
        child: _SheetScope(
          host: this,
          child: SynkBottomSheetFrame(
            solid: route.solid,
            showHandle: route.showHandle,
            maxHeightFraction: route.maxHeightFraction,
            scrollable: route.scrollable,
            child: Builder(builder: route.builder),
          ),
        ),
      ),
    );

    const scrimColor = SynkPalette.backdrop;
    final scrim = GestureDetector(
      // The Semantics around it names the scrim ("Dismiss"); the detector's own node would
      // be a second, unlabelled one.
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      onTap: _requestDismiss,
      child: AnimatedBuilder(
        animation: _closed,
        builder: (context, _) {
          final progress = (1 - _closed.value).clamp(0.0, 1.0);
          return ColoredBox(
            key: const ValueKey<String>('synk_sheet_scrim'),
            color: scrimColor.withValues(alpha: scrimColor.a * progress),
          );
        },
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestDismiss();
      },
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: route.semanticLabel ?? 'Bottom sheet',
        child: Material(
          type: MaterialType.transparency,
          child: IgnorePointer(
            ignoring: _closing,
            child: Stack(
              fit: StackFit.expand,
              children: [
                route.isDismissible
                    ? Semantics(
                        label: 'Dismiss',
                        button: true,
                        onTap: _requestDismiss,
                        child: scrim,
                      )
                    : ExcludeSemantics(child: scrim),
                // Align (not Positioned) so the frame sees a bounded height.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      onDismiss: route.isDismissible ? _requestDismiss : null,
                      child: AnimatedBuilder(
                        animation: _closed,
                        child: sheet,
                        builder: (context, child) => FractionalTranslation(
                          translation: Offset(0, math.max(0.0, _closed.value)),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
