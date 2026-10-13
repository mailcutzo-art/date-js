import 'package:flutter/painting.dart';

/// Fixed colours that are identical in light and dark (ported from `SynklyPalette`).
abstract final class SynkPalette {
  /// The brand's hot magenta (wavy backgrounds, selected chips, unread dots). 6.1:1 against
  /// [nightInk], so text drawn on it is always black.
  static const Color brandPink = hotMagenta;

  /// Magenta for text and icons on the dark theme (6.6:1 or more on every dark surface). Only
  /// drawn as text and icons: fills keep [hotMagenta].
  static const Color brandPinkText = Color(0xFFFF5BDC);

  // Brand art palette (posters, wavy backgrounds, doodles).
  static const Color hotMagenta = Color(0xFFFF2BD1);
  static const Color flameOrange = Color(0xFFFF4D1A);
  static const Color electricViolet = Color(0xFFA63CF2);

  /// Chat bubbles, photo frames and interest chips. 14.7:1 against [nightInk].
  static const Color cream = Color(0xFFEFDDB6);

  /// Darker cream for strokes and pressed states on [cream].
  static const Color creamDeep = Color(0xFFDCC28C);
  static const Color nightInk = Color(0xFF0C0B0D);

  /// Deep magenta that holds 5.5:1 on white (brand text on the light theme).
  static const Color magentaText = Color(0xFFC2009B);

  /// Profile "about" panel (12.5:1 with white text, 9.4:1 with cream).
  static const Color royalPurple = Color(0xFF34296B);

  /// Dark plum card behind photos on the dark poster screens.
  static const Color plum = Color(0xFF3A1230);

  /// Wavy background bands, in drawing order.
  static const List<Color> waves = <Color>[
    hotMagenta,
    flameOrange,
    electricViolet,
  ];
  static const Color notificationAccent = Color(0xFFFF1F6B);
  static const Color signInHero = Color(0xFFFF00FF);

  static const Color success = Color(0xFF10B981);

  /// Success text on the light theme: 4.6:1 or more on white and on the green tints (was
  /// 0xFF059669, 3.3:1 on a tint).
  static const Color successText = Color(0xFF047857);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);

  /// Amber text on the light theme: 4.5:1 or more on white and on the amber tints (was
  /// 0xFFD97706, 3.2:1 on white).
  static const Color amberDark = Color(0xFFA8500A);
  static const Color indigo = Color(0xFF6366F1);

  static const Color skeleton = Color(0x59A79EA9);
  static const Color storageTrack = Color(0x40A79EA9);

  static const Color youtubeRed = Color(0xFFEF4444);
  static const Color videoTab = Color(0xFFE11D48);
  static const Color nowPlaying = Color(0xFFF43F5E);
  static const Color boostHud = Color(0xFFDB045C);
  static const Color liveRed = Color(0xFFEF4444);

  static const Color backdrop = Color(0x73000000);
  static const Color dialogBackdrop = Color(0x80000000);
  static const Color popoverBackdrop = Color(0x33000000);

  static const Color errorBackground = Color(0xFF0B0B0F);
  static const Color errorCard = Color(0xFF171727);
  static const Color errorBody = Color(0xFFCBD5E1);

  static const Color medalGold = Color(0xFFF59E0B);
  static const Color medalSilver = Color(0xFF94A3B8);
  static const Color medalBronze = Color(0xFFB45309);

  /// The four colours of the Google "G".
  static const Color googleYellow = Color(0xFFFFC107);
  static const Color googleRed = Color(0xFFFF3D00);
  static const Color googleGreen = Color(0xFF4CAF50);
  static const Color googleBlue = Color(0xFF1976D2);

  /// Profile colour swatches offered to the user (order matters).
  static const List<Color> profileSwatches = <Color>[
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFFEAB308),
    Color(0xFF84CC16),
    Color(0xFF22C55E),
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
    Color(0xFFD946EF),
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
    Color(0xFF9CA3AF),
    Color(0xFFFFFFFF),
  ];

  /// "Bauhaus" group-avatar palette.
  static const List<Color> groupAvatarPalette = <Color>[
    Color(0xFF785D56),
    Color(0xFFBE4C54),
    Color(0xFFC6B299),
    Color(0xFFE6D5C1),
    Color(0xFFFFF4E3),
  ];

  /// Onboarding hero backgrounds per step.
  static const List<Color> onboardingHero = <Color>[
    Color(0xFF96C9F4),
    Color(0xFFFFCBA4),
    Color(0xFFEFD2B0),
  ];

  /// Confetti colours.
  static const List<Color> confetti = <Color>[
    hotMagenta,
    flameOrange,
    electricViolet,
    cream,
    Color(0xFF0C0B0D),
    Color(0xFFFFFFFF),
  ];

  /// Avatar fallback colours for chat senders (picked by sum of char codes % 7).
  static const List<Color> chatAvatarColors = <Color>[
    Color(0xFFE67E22),
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFF8E44AD),
    Color(0xFFE74C3C),
    Color(0xFF1ABC9C),
    Color(0xFF2C3E50),
  ];
}

/// Parses `#rgb`, `#rrggbb` or `#aarrggbb`; returns null for anything else.
Color? parseHexColor(String? input) {
  if (input == null) return null;
  var hex = input.trim();
  if (!hex.startsWith('#')) return null;
  hex = hex.substring(1);
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}
