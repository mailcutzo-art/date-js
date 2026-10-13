import 'package:flutter/animation.dart';

/// Motion specs ported from the Compose app (durations, easings, springs).
abstract final class SynkMotion {
  /// Compose `tween` default easing: FastOutSlowIn.
  static const Curve fastOutSlowIn = Cubic(0.4, 0, 0.2, 1);
  static const Curve smooth = Cubic(0.32, 0.72, 0, 1);
  static const Curve easeOutQuad = Cubic(0.25, 0.46, 0.45, 0.94);
  static const Curve easeOutCubic = Cubic(0.215, 0.61, 0.355, 1);
  static const Curve sheetClose = Cubic(0.25, 0.1, 0.25, 1);
  static const Curve popover = Cubic(0.33, 1, 0.68, 1);

  static const Duration page = Duration(milliseconds: 260);
  static const Duration pageExitFade = Duration(milliseconds: 130);
  static const Duration stageIn = Duration(milliseconds: 220);
  static const Duration stageOut = Duration(milliseconds: 150);
  static const Duration sheetOut = Duration(milliseconds: 220);
  static const Duration dialogIn = Duration(milliseconds: 130);
  static const Duration dialogOut = Duration(milliseconds: 160);
  static const Duration popoverIn = Duration(milliseconds: 70);
  static const Duration popoverOut = Duration(milliseconds: 50);
  static const Duration toastIn = Duration(milliseconds: 220);
  static const Duration toastOut = Duration(milliseconds: 180);
  static const Duration toastLife = Duration(milliseconds: 3000);
  static const Duration switchToggle = Duration(milliseconds: 220);
  static const Duration progress = Duration(milliseconds: 200);
  static const Duration avatarFade = Duration(milliseconds: 120);

  /// Bottom-sheet open spring (damping ratio 0.864, stiffness 200).
  static SpringDescription get sheetOpen =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 200, ratio: 0.864);

  /// Sheet snap-back when a drag is refused (0.949 / 250).
  static SpringDescription get sheetSnapBack =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 250, ratio: 0.949);

  /// Dialog scale-in (0.86 / 900).
  static SpringDescription get dialogScale =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 900, ratio: 0.86);

  /// Chat bubble pop-in (0.62 / 1100).
  static SpringDescription get chatPop =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 1100, ratio: 0.62);

  /// Success-toast icon pop (0.4 / 220).
  static SpringDescription get iconPop =>
      SpringDescription.withDampingRatio(mass: 1, stiffness: 220, ratio: 0.4);
}
