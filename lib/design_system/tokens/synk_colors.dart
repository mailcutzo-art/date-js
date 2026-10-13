import 'package:flutter/material.dart';

import 'synk_palette.dart';

/// Pastel tone of a surface (the reference image's lavender / ice / blush cards).
enum SynkTone { neutral, lavender, ice, blush }

/// Semantic colour tokens (ported from `SynklyColors`) plus the pastel layer of the refreshed UI.
@immutable
class SynkColors {
  const SynkColors({
    required this.brightness,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.drawer,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.border,
    required this.input,
    required this.ring,
    required this.glassOverlay,
    required this.glassBorder,
    required this.headerOverlay,
    required this.solidInputBackground,
    required this.solidInputFocusedBorder,
    required this.switchTrackOff,
    required this.outgoingBubble,
    required this.outgoingOverlay,
    required this.signInSheet,
    required this.onboardingSheet,
    required this.ink,
    required this.inkForeground,
    required this.lavender,
    required this.ice,
    required this.blush,
    required this.periwinkle,
    required this.blueGrey,
    required this.chartPink,
    required this.tooltip,
    required this.tooltipForeground,
  });

  final Brightness brightness;
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color drawer;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color border;
  final Color input;
  final Color ring;
  final Color glassOverlay;
  final Color glassBorder;
  final Color headerOverlay;
  final Color solidInputBackground;
  final Color solidInputFocusedBorder;
  final Color switchTrackOff;
  final Color outgoingBubble;
  final Color outgoingOverlay;
  final Color signInSheet;
  final Color onboardingSheet;

  // Refreshed-UI layer (reference image).
  /// Near-black used for circular icon buttons, selected pills and dark badges.
  final Color ink;
  final Color inkForeground;
  final Color lavender;
  final Color ice;
  final Color blush;
  final Color periwinkle;
  final Color blueGrey;
  final Color chartPink;
  final Color tooltip;
  final Color tooltipForeground;

  bool get isDark => brightness == Brightness.dark;

  /// The brand magenta for text and icons on this theme's surfaces: a deep magenta on light (5.5:1
  /// on white) and a light one on dark (6.6:1 or more on every dark surface).
  Color get primaryText =>
      isDark ? SynkPalette.brandPinkText : SynkPalette.magentaText;

  /// Ripple/press tint of list rows (card foreground at 12 %).
  Color get listRipple => cardForeground.withValues(alpha: 0.12);

  /// Background colour of a pastel surface for [tone].
  Color toneSurface(SynkTone tone) => switch (tone) {
    SynkTone.neutral => card,
    SynkTone.lavender => lavender,
    SynkTone.ice => ice,
    SynkTone.blush => blush,
  };

  /// Solid accent that pairs with [toneSurface] (meter fills, rings).
  Color toneAccent(SynkTone tone) => switch (tone) {
    SynkTone.neutral => primary,
    SynkTone.lavender => periwinkle,
    SynkTone.ice => blueGrey,
    SynkTone.blush => chartPink,
  };

  // Brand: black ink, cream and hot magenta on white (light) or near-black (dark). Buttons and
  // your own chat bubbles are the ink colour; chips, frames and incoming bubbles are cream.
  static const SynkColors light = SynkColors(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF0C0B0D),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF0C0B0D),
    drawer: Color(0xFFFFFFFF),
    primary: Color(0xFF0C0B0D),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFEFDDB6),
    secondaryForeground: Color(0xFF0C0B0D),
    muted: Color(0xFFF6EEDC),
    // 5.8:1 on white, 5.0:1 on the soft cream fill.
    mutedForeground: Color(0xFF6E6459),
    accent: Color(0xFFF6EEDC),
    accentForeground: Color(0xFF0C0B0D),
    destructive: Color(0xFFCF000B),
    border: Color(0xFFE9DFC9),
    input: Color(0xFFE9DFC9),
    ring: Color(0xFFA89C88),
    glassOverlay: Color(0x8CFFFFFF),
    glassBorder: Color(0xA6E9DFC9),
    headerOverlay: Color(0xD9FFFFFF),
    solidInputBackground: Color(0xFFF6EEDC),
    solidInputFocusedBorder: Color(0x400C0B0D),
    switchTrackOff: Color(0x29787880),
    outgoingBubble: Color(0xFF0C0B0D),
    outgoingOverlay: Color(0x0F0C0B0D),
    signInSheet: Color(0xFFFFFFFF),
    onboardingSheet: Color(0xFFFFFFFF),
    ink: Color(0xFF0C0B0D),
    inkForeground: Color(0xFFFFFFFF),
    lavender: Color(0xFFF3E8FF),
    ice: Color(0xFFFFF1DE),
    blush: Color(0xFFFFE6F8),
    periwinkle: Color(0xFFA63CF2),
    blueGrey: Color(0xFFDCC28C),
    chartPink: Color(0xFFFF2BD1),
    tooltip: Color(0xFF0C0B0D),
    tooltipForeground: Color(0xFFFFFFFF),
  );

  static const SynkColors dark = SynkColors(
    brightness: Brightness.dark,
    background: Color(0xFF0C0B0D),
    foreground: Color(0xFFFFFFFF),
    card: Color(0xFF1A1719),
    cardForeground: Color(0xFFFFFFFF),
    drawer: Color(0xFF1F1B1E),
    primary: Color(0xFFEFDDB6),
    primaryForeground: Color(0xFF0C0B0D),
    secondary: Color(0xFF221E21),
    secondaryForeground: Color(0xFFFFFFFF),
    muted: Color(0xFF262125),
    // 8.9:1 on the background, 8.0:1 on a card.
    mutedForeground: Color(0xFFB5ADA7),
    accent: Color(0xFF221E21),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFFF6467),
    border: Color(0x1FFFFFFF),
    input: Color(0x24FFFFFF),
    ring: Color(0xFF6E6459),
    glassOverlay: Color(0x8C0C0B0D),
    glassBorder: Color(0x1FFFFFFF),
    headerOverlay: Color(0xA6000000),
    solidInputBackground: Color(0xFF151214),
    solidInputFocusedBorder: Color(0x59EFDDB6),
    switchTrackOff: Color(0x52787880),
    outgoingBubble: Color(0xFFEFDDB6),
    outgoingOverlay: Color(0x1AFFFFFF),
    signInSheet: Color(0xFF1F1B1E),
    onboardingSheet: Color(0xFF262125),
    ink: Color(0xFFEFDDB6),
    inkForeground: Color(0xFF0C0B0D),
    lavender: Color(0xFF241A33),
    ice: Color(0xFF2A2117),
    blush: Color(0xFF2E1428),
    periwinkle: Color(0xFFB765F5),
    blueGrey: Color(0xFF8C7A5A),
    chartPink: Color(0xFFFF5BDC),
    tooltip: Color(0xFFEFDDB6),
    tooltipForeground: Color(0xFF0C0B0D),
  );
}
