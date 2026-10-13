import 'package:flutter/material.dart';

import 'synk_colors.dart';
import 'synk_typography.dart';

/// Theme extension carrying Synkly's semantic colours.
@immutable
class SynkTheme extends ThemeExtension<SynkTheme> {
  const SynkTheme(this.colors);

  final SynkColors colors;

  @override
  SynkTheme copyWith({SynkColors? colors}) => SynkTheme(colors ?? this.colors);

  /// Colours do not interpolate: the light/dark switch is instantaneous.
  @override
  SynkTheme lerp(ThemeExtension<SynkTheme>? other, double t) {
    if (other is! SynkTheme) return this;
    return t < 0.5 ? this : other;
  }
}

extension SynkThemeContext on BuildContext {
  /// Semantic colour tokens of the active theme.
  SynkColors get colors =>
      Theme.of(this).extension<SynkTheme>()?.colors ?? SynkColors.light;

  bool get isDarkTheme => colors.isDark;
}

/// Builds the Material `ThemeData` used by stock widgets (pickers, selection, progress)
/// from the Synkly tokens; everything else is drawn by design-system components.
abstract final class SynkThemeData {
  static ThemeData get light => _build(SynkColors.light);
  static ThemeData get dark => _build(SynkColors.dark);

  static ThemeData _build(SynkColors c) {
    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.primaryForeground,
      primaryContainer: c.secondary,
      onPrimaryContainer: c.secondaryForeground,
      secondary: c.accent,
      onSecondary: c.accentForeground,
      secondaryContainer: c.muted,
      onSecondaryContainer: c.mutedForeground,
      tertiary: c.accent,
      onTertiary: c.accentForeground,
      error: c.destructive,
      onError: c.primaryForeground,
      surface: c.card,
      onSurface: c.cardForeground,
      surfaceContainerHighest: c.muted,
      onSurfaceVariant: c.mutedForeground,
      outline: c.border,
      outlineVariant: c.border,
      inverseSurface: c.foreground,
      onInverseSurface: c.background,
      scrim: const Color(0x80000000),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      fontFamily: SynkTypography.fontFamily,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      extensions: <ThemeExtension<dynamic>>[SynkTheme(c)],
      splashFactory: InkRipple.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.3),
        selectionHandleColor: c.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        circularTrackColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    );
  }
}
