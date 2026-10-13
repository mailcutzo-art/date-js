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

  /// The brand colour for text and icons on this theme's surfaces: [primary] on light (at least
  /// 5.2:1 on every pastel surface, unchanged) and the brand pink lightened by 36 % on dark, where
  /// [primary] (0xFFA3004C) is only 2.3:1 on a card (this one is at least 4.6:1 on every dark
  /// surface and chip fill).
  Color get primaryText => isDark ? SynkPalette.brandPinkText : primary;

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

  static const SynkColors light = SynkColors(
    brightness: Brightness.light,
    background: Color(0xFFFAFAFA),
    foreground: Color(0xFF0A0A0A),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF0A0A0A),
    drawer: Color(0xFFFFFFFF),
    primary: Color(0xFFC6005C),
    primaryForeground: Color(0xFFFAFAFA),
    secondary: Color(0xFFF5F5F5),
    secondaryForeground: Color(0xFF171717),
    muted: Color(0xFFF5F5F5),
    // Was 0xFF737373: 4.2:1 on a blush card. 0xFF6A6A6A is the lightest grey that holds 4.5:1 on
    // every light surface: 5.4:1 on white, 4.7:1 on blush, 4.6:1 on the soft chip fill.
    mutedForeground: Color(0xFF6A6A6A),
    accent: Color(0xFFF5F5F5),
    accentForeground: Color(0xFF171717),
    // Was 0xFFE7000B: 4.0:1 on its own 10 % tint (error text on an error notice). 0xFFCF000B is
    // the nearest red that holds 4.5:1 there: 4.8:1 on a card tint, 4.6:1 on a page tint.
    destructive: Color(0xFFCF000B),
    border: Color(0xFFE5E5E5),
    input: Color(0xFFE5E5E5),
    ring: Color(0xFFA3A3A3),
    glassOverlay: Color(0x8CFFFFFF),
    glassBorder: Color(0xA6E7E4E7),
    headerOverlay: Color(0xD9F6F2F6),
    solidInputBackground: Color(0xFFF5F5F5),
    solidInputFocusedBorder: Color(0x400A0A0A),
    switchTrackOff: Color(0x29787880),
    outgoingBubble: Color(0x1AC6005C),
    outgoingOverlay: Color(0x0F0A0A0A),
    signInSheet: Color(0xFFFFFFFF),
    onboardingSheet: Color(0xFFFFFFFF),
    ink: Color(0xFF17181C),
    inkForeground: Color(0xFFFFFFFF),
    lavender: Color(0xFFF2F5FF),
    ice: Color(0xFFE6F3FA),
    blush: Color(0xFFFBECF1),
    periwinkle: Color(0xFFA9B6FD),
    blueGrey: Color(0xFFC4D5DD),
    chartPink: Color(0xFFFEDAE9),
    tooltip: Color(0xFF282A2E),
    tooltipForeground: Color(0xFFFFFFFF),
  );

  static const SynkColors dark = SynkColors(
    brightness: Brightness.dark,
    background: Color(0xFF0A0A0A),
    foreground: Color(0xFFFAFAFA),
    card: Color(0xFF171717),
    cardForeground: Color(0xFFFAFAFA),
    drawer: Color(0xFF1F1F1F),
    primary: Color(0xFFA3004C),
    primaryForeground: Color(0xFFFAFAFA),
    secondary: Color(0xFF171717),
    secondaryForeground: Color(0xFFFAFAFA),
    muted: Color(0xFF262626),
    mutedForeground: Color(0xFFA3A3A3),
    accent: Color(0xFF171717),
    accentForeground: Color(0xFFFAFAFA),
    destructive: Color(0xFFFF6467),
    border: Color(0x14FFFFFF),
    input: Color(0x1FFFFFFF),
    ring: Color(0xFF525252),
    glassOverlay: Color(0x8C080309),
    glassBorder: Color(0x1FFFFFFF),
    headerOverlay: Color(0xA6000000),
    solidInputBackground: Color(0xFF0F0F0F),
    solidInputFocusedBorder: Color(0x59E5E5E5),
    switchTrackOff: Color(0x52787880),
    outgoingBubble: Color(0x1AA3004C),
    outgoingOverlay: Color(0x1AFFFFFF),
    signInSheet: Color(0xFF1F1F1F),
    onboardingSheet: Color(0xFF262626),
    ink: Color(0xFFFAFAFA),
    inkForeground: Color(0xFF0A0A0A),
    lavender: Color(0xFF1B1E30),
    ice: Color(0xFF14232C),
    blush: Color(0xFF2A1621),
    periwinkle: Color(0xFF8793E6),
    blueGrey: Color(0xFF6C8794),
    chartPink: Color(0xFFD97AA3),
    tooltip: Color(0xFFFAFAFA),
    tooltipForeground: Color(0xFF0A0A0A),
  );
}
