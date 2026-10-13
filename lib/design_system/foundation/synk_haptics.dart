import 'package:flutter/widgets.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// Semantic haptics (ported from the Android `Haptics` object).
enum SynkHaptic {
  selection,
  impactLight,
  impactMedium,
  success,
  warning,
  gestureThreshold,
  longPress,
  keyboardTap,
}

abstract interface class SynkHapticsPlayer {
  void play(SynkHaptic haptic);
}

/// Plays nothing (tests, unsupported devices).
class NoopHaptics implements SynkHapticsPlayer {
  const NoopHaptics();

  @override
  void play(SynkHaptic haptic) {}
}

/// Platform haptics. On Android the system `HapticFeedbackConstants` are used so the feel
/// matches the native app (CONFIRM, REJECT, ...); it honours the user's haptic setting.
class PlatformHaptics implements SynkHapticsPlayer {
  const PlatformHaptics();

  @override
  void play(SynkHaptic haptic) {
    final type = switch (haptic) {
      SynkHaptic.selection => HapticsType.selection,
      SynkHaptic.impactLight => HapticsType.light,
      SynkHaptic.impactMedium => HapticsType.medium,
      SynkHaptic.success => HapticsType.success,
      SynkHaptic.warning => HapticsType.warning,
      SynkHaptic.gestureThreshold => HapticsType.rigid,
      SynkHaptic.longPress => HapticsType.heavy,
      SynkHaptic.keyboardTap => HapticsType.soft,
    };
    Haptics.vibrate(type, useAndroidHapticConstants: true).ignore();
  }
}

/// Provides the haptics player to the tree (defaults to [PlatformHaptics]).
class SynkHapticsScope extends InheritedWidget {
  const SynkHapticsScope({
    required this.player,
    required super.child,
    super.key,
  });

  final SynkHapticsPlayer player;

  static SynkHapticsPlayer of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SynkHapticsScope>()?.player ??
      const PlatformHaptics();

  @override
  bool updateShouldNotify(SynkHapticsScope oldWidget) =>
      player != oldWidget.player;
}

extension SynkHapticsContext on BuildContext {
  void haptic(SynkHaptic haptic) => SynkHapticsScope.of(this).play(haptic);
}
