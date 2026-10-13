import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import '../../design_system/design_system.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/swipe.dart';
import 'profile_card.dart';

/// Lets a button bar drive the deck: [swipe] flies the top card off in the given direction.
class SwipeDeckController {
  _SwipeDeckState? _state;

  void swipe(SwipeAction action) => _state?._flyOut(action);
}

/// A stack of [ProfileCard]s the user drags: right likes, left passes, up super-likes.
///
/// Motion (all tunable through the statics below):
/// - the card follows the finger and tilts by up to [maxTilt] radians at the screen edge;
/// - past [commitFraction] of the width (or [flingVelocity] px/s) it flies off in 260 ms;
/// - otherwise it springs back (stiffness 300, damping 22) and the stamps fade out;
/// - the two cards behind scale up and rise as the top card leaves.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    required this.profiles,
    required this.onSwiped,
    this.onInfoTap,
    this.controller,
    super.key,
  });

  /// Top of the deck first.
  final List<Profile> profiles;
  final void Function(Profile profile, SwipeAction action) onSwiped;
  final void Function(Profile profile)? onInfoTap;
  final SwipeDeckController? controller;

  static const double commitFraction = 0.30;
  static const double superCommitFraction = 0.20;
  static const double flingVelocity = 800;
  static const double maxTilt = 0.35;
  static const Duration flyDuration = Duration(milliseconds: 260);
  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 22,
  );

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController.unbounded(
    vsync: this,
  );
  Offset _drag = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  SwipeAction? _flying;
  Size _size = Size.zero;
  bool _thresholdHapticPlayed = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _anim.addListener(_tick);
  }

  @override
  void didUpdateWidget(SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _anim.dispose();
    super.dispose();
  }

  void _tick() {
    setState(() => _drag = Offset.lerp(_from, _to, _anim.value)!);
  }

  SwipeAction? _actionFor(Offset offset, Offset velocity) {
    final w = _size.width;
    final h = _size.height;
    final upward = -offset.dy > offset.dx.abs();
    if (upward &&
        (-offset.dy > h * SwipeDeck.superCommitFraction ||
            velocity.dy < -SwipeDeck.flingVelocity * 1.2)) {
      return SwipeAction.superLike;
    }
    if (offset.dx > w * SwipeDeck.commitFraction ||
        velocity.dx > SwipeDeck.flingVelocity) {
      return SwipeAction.like;
    }
    if (offset.dx < -w * SwipeDeck.commitFraction ||
        velocity.dx < -SwipeDeck.flingVelocity) {
      return SwipeAction.pass;
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    if (_flying != null) return;
    _anim.stop();
    _thresholdHapticPlayed = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_flying != null) return;
    setState(() => _drag += details.delta);
    final past = _actionFor(_drag, Offset.zero) != null;
    if (past && !_thresholdHapticPlayed) {
      _thresholdHapticPlayed = true;
      SynkHapticsScope.of(context).play(SynkHaptic.gestureThreshold);
    } else if (!past) {
      _thresholdHapticPlayed = false;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_flying != null) return;
    final action = _actionFor(_drag, details.velocity.pixelsPerSecond);
    if (action == null) {
      _springBack(details.velocity.pixelsPerSecond);
    } else {
      _flyOut(action);
    }
  }

  void _springBack(Offset velocity) {
    _from = _drag;
    _to = Offset.zero;
    _anim.value = 0;
    _anim.animateWith(SpringSimulation(SwipeDeck.spring, 0, 1, 0));
  }

  void _flyOut(SwipeAction action) {
    if (_flying != null || widget.profiles.isEmpty) return;
    _flying = action;
    final w = _size.width == 0 ? 400.0 : _size.width;
    final h = _size.height == 0 ? 700.0 : _size.height;
    _from = _drag;
    _to = switch (action) {
      SwipeAction.like => Offset(w * 1.5, _drag.dy - 40),
      SwipeAction.pass => Offset(-w * 1.5, _drag.dy - 40),
      SwipeAction.superLike => Offset(_drag.dx, -h * 1.2),
    };
    _anim.value = 0;
    _anim
        .animateTo(
          1,
          duration: SwipeDeck.flyDuration,
          curve: SynkMotion.easeOutCubic,
        )
        .whenComplete(() => _finishFly(action));
  }

  void _finishFly(SwipeAction action) {
    if (!mounted || widget.profiles.isEmpty) return;
    final profile = widget.profiles.first;
    setState(() {
      _flying = null;
      _drag = Offset.zero;
    });
    SynkHapticsScope.of(context).play(
      action == SwipeAction.pass ? SynkHaptic.impactLight : SynkHaptic.success,
    );
    widget.onSwiped(profile, action);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final visible = widget.profiles.take(3).toList();
        final progress = math.min(1.0, _drag.distance / (_size.width * 0.5));
        final dx = _drag.dx;
        final dy = _drag.dy;
        final upward = -dy > dx.abs();
        final likeOpacity = !upward && dx > 0
            ? (dx / (_size.width * 0.25)).clamp(0.0, 1.0)
            : 0.0;
        final nopeOpacity = !upward && dx < 0
            ? (-dx / (_size.width * 0.25)).clamp(0.0, 1.0)
            : 0.0;
        final superOpacity = upward
            ? (-dy / (_size.height * 0.18)).clamp(0.0, 1.0)
            : 0.0;
        final tilt = (dx / _size.width * SwipeDeck.maxTilt * 2).clamp(
          -0.6,
          0.6,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = visible.length - 1; i >= 0; i--)
              Positioned.fill(
                key: ValueKey(visible[i].id),
                child: i == 0
                    ? _topCard(
                        visible[i],
                        tilt,
                        likeOpacity,
                        nopeOpacity,
                        superOpacity,
                      )
                    : _backCard(visible[i], i, progress),
              ),
          ],
        );
      },
    );
  }

  Widget _topCard(
    Profile profile,
    double tilt,
    double likeOpacity,
    double nopeOpacity,
    double superOpacity,
  ) {
    return Semantics(
      label: '${profile.name}, ${profile.age}',
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Like'): () =>
            _flyOut(SwipeAction.like),
        const CustomSemanticsAction(label: 'Pass'): () =>
            _flyOut(SwipeAction.pass),
        const CustomSemanticsAction(label: 'Super like'): () =>
            _flyOut(SwipeAction.superLike),
      },
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform.translate(
          offset: _drag,
          child: Transform.rotate(
            angle: tilt,
            alignment: Alignment.bottomCenter,
            child: _shadowed(
              ProfileCard(
                profile: profile,
                likeOpacity: likeOpacity,
                nopeOpacity: nopeOpacity,
                superOpacity: superOpacity,
                onInfoTap: widget.onInfoTap == null
                    ? null
                    : () => widget.onInfoTap!(profile),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backCard(Profile profile, int depth, double progress) {
    // Depth 1 grows into the top slot as the top card leaves; depth 2 into depth 1.
    final t = depth - progress;
    final scale = 1 - 0.05 * t;
    final lift = 14.0 * t;
    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, lift),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: _shadowed(ProfileCard(profile: profile)),
        ),
      ),
    );
  }

  Widget _shadowed(Widget child) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: SynkRadius.xxlAll,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
