import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../tokens/synk_motion.dart';
import '../tokens/synk_palette.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_spacing.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Opens a Synkly dialog (a custom overlay, not a Material dialog) on the navigator.
///
/// The builder's widget is wrapped in a [SynkDialogFrame]. The scrim tap and Back dismiss only
/// when [dismissible]. Enter: 130 ms fade plus a scale 0.96 to 1 spring; exit: 160 ms fade plus
/// a scale to 0.97. Close from inside with `Navigator.of(context).pop(result)`.
///
/// The frame already accounts for the status bar, the keyboard and the bottom safe area, so
/// the content must not pad for them (they are removed from its `MediaQuery`).
Future<T?> showSynkDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
  bool useRootNavigator = true,
  String? semanticLabel,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    _SynkDialogRoute<T>(
      builder: builder,
      dismissible: dismissible,
      semanticLabel: semanticLabel,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
    ),
  );
}

/// The dialog card: max width 420 (fills the width up to that), radius 18, 1dp border and
/// padding (20, 20, 20, max(16, bottom inset + 4)). Content taller than the available height
/// scrolls. Golden tests pump it directly.
class SynkDialogFrame extends StatelessWidget {
  const SynkDialogFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final navInset = MediaQuery.viewPaddingOf(context).bottom;
    final padding = EdgeInsets.fromLTRB(20, 20, 20, math.max(16, navInset + 4));
    // The route already insets the card for the status bar, cutouts and keyboard.
    final mediaQuery = MediaQuery.of(context);
    final content = MediaQuery(
      data: mediaQuery.copyWith(
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: mediaQuery.viewInsets.copyWith(bottom: 0),
      ),
      child: child,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: SynkSpace.dialogMax),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: SynkRadius.lgAll,
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: SynkRadius.lgAll,
            child: SingleChildScrollView(
              padding: padding,
              physics: const ClampingScrollPhysics(),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Header block of a dialog: children stacked with a 6 dp gap and 8 dp below.
class DialogHeader extends StatelessWidget {
  const DialogHeader({required this.children, super.key});

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

/// Dialog title (19 / 600).
class DialogTitle extends StatelessWidget {
  const DialogTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: SynkText(text, variant: SynkTextVariant.dialogTitle),
    );
  }
}

/// Muted dialog description.
class DialogDescription extends StatelessWidget {
  const DialogDescription(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SynkText(text, variant: SynkTextVariant.description);
  }
}

/// End-aligned button row: 10 dp gap, 8 dp above. The row wraps onto a second line when the
/// buttons no longer fit (large text scales) instead of overflowing.
class DialogFooter extends StatelessWidget {
  const DialogFooter({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: children,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Route
// ---------------------------------------------------------------------------------------

class _SynkDialogRoute<T> extends PopupRoute<T> {
  _SynkDialogRoute({
    required this.builder,
    required this.dismissible,
    required this.semanticLabel,
    required this.capturedThemes,
  });

  final WidgetBuilder builder;
  final bool dismissible;
  final String? semanticLabel;
  final CapturedThemes capturedThemes;

  @override
  Color? get barrierColor => SynkPalette.dialogBackdrop;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => dismissible ? 'Dismiss' : null;

  @override
  Curve get barrierCurve => SynkMotion.fastOutSlowIn;

  @override
  Duration get transitionDuration => SynkMotion.dialogIn;

  @override
  Duration get reverseTransitionDuration => SynkMotion.dialogOut;

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
    return capturedThemes.wrap(_DialogPage<T>(route: this));
  }
}

class _DialogPage<T> extends StatefulWidget {
  const _DialogPage({required this.route});

  final _SynkDialogRoute<T> route;

  @override
  State<_DialogPage<T>> createState() => _DialogPageState<T>();
}

class _DialogPageState<T> extends State<_DialogPage<T>>
    with SingleTickerProviderStateMixin {
  static const double _enterScale = 0.96;
  static const double _exitScale = 0.97;

  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: _enterScale,
  );
  late final Animation<double> _routeAnimation;
  bool _closing = false;
  double _closeFromScale = 1;
  double _closeFromAlpha = 1;
  double _closeFromValue = 1;

  @override
  void initState() {
    super.initState();
    _routeAnimation = widget.route.animation!;
    _routeAnimation.addStatusListener(_onRouteStatus);
    final status = _routeAnimation.status;
    if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) {
      _closing = true;
    } else {
      unawaited(
        _scale.animateWith(
          SpringSimulation(SynkMotion.dialogScale, _enterScale, 1, 0),
        ),
      );
    }
  }

  @override
  void dispose() {
    _routeAnimation.removeStatusListener(_onRouteStatus);
    _scale.dispose();
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    if (_closing) return;
    if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) {
      _closeFromValue = math.max(_routeAnimation.value, 0.001);
      _closeFromAlpha = SynkMotion.fastOutSlowIn.transform(
        _routeAnimation.value.clamp(0.0, 1.0),
      );
      _closeFromScale = _scale.value;
      _closing = true;
      _scale.stop();
    }
  }

  /// Exit progress 0 to 1 with the tween easing (the route animation runs from where it was
  /// when the pop began down to 0).
  double get _exitProgress => SynkMotion.fastOutSlowIn.transform(
    (1 - _routeAnimation.value / _closeFromValue).clamp(0.0, 1.0),
  );

  double _currentScale() {
    if (!_closing) return _scale.value;
    return _closeFromScale + (_exitScale - _closeFromScale) * _exitProgress;
  }

  double _currentAlpha() {
    if (_closing) return _closeFromAlpha * (1 - _exitProgress);
    return SynkMotion.fastOutSlowIn.transform(
      _routeAnimation.value.clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final outer = EdgeInsets.fromLTRB(
      16 + viewPadding.left,
      12 + viewPadding.top,
      16 + viewPadding.right,
      12 + insets.bottom,
    );

    final card = AnimatedBuilder(
      animation: Listenable.merge([_routeAnimation, _scale]),
      child: SynkDialogFrame(child: Builder(builder: route.builder)),
      builder: (context, child) {
        return Opacity(
          opacity: _currentAlpha(),
          child: Transform.scale(scale: _currentScale(), child: child),
        );
      },
    );

    return PopScope(
      canPop: route.dismissible,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: route.semanticLabel ?? 'Dialog',
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: outer,
            child: Center(child: card),
          ),
        ),
      ),
    );
  }
}
