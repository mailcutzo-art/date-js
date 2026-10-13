import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/design_system.dart';

/// Pushed screens slide in from the right (260 ms) over a slightly dimmed, shifted previous page.
CustomTransitionPage<void> stackPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: SynkMotion.page,
    reverseTransitionDuration: SynkMotion.page,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: SynkMotion.smooth,
        reverseCurve: SynkMotion.smooth.flipped,
      );
      return SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

/// Top-level stages (splash, welcome, setup) cross-fade.
CustomTransitionPage<void> stagePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: SynkMotion.stageIn,
    reverseTransitionDuration: SynkMotion.stageOut,
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Sheet-like full-screen routes (premium) rise from the bottom.
CustomTransitionPage<void> risePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    fullscreenDialog: true,
    transitionDuration: SynkMotion.page,
    reverseTransitionDuration: SynkMotion.sheetOut,
    transitionsBuilder: (context, animation, secondary, child) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: SynkMotion.smooth)),
        child: child,
      );
    },
  );
}
