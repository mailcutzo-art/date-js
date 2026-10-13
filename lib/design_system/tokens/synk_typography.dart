import 'package:flutter/material.dart';

/// Text variants (ported from `SynklyTypography`) plus the larger display/stat styles
/// of the refreshed UI. Colours are resolved by `SynkText`, never baked in.
enum SynkTextVariant {
  h1,
  h2,
  h3,
  p,
  large,
  small,
  lead,
  muted,
  buttonDefault,
  buttonSmall,
  buttonLarge,
  cardTitle,
  cardDescription,
  drawerTitle,
  dialogTitle,
  popoverTitle,
  description,
  badge,
  badgeSmall,
  listTitle,
  listDescription,
  toastTitle,
  toastDescription,
  input,
  sectionLabel,
  sectionLabelSmall,
  // Refreshed UI
  display,
  statXl,
  statLg,
  statUnit,
  caption,
  tab,
  // Brand
  /// Hand-lettered poster headline (welcome slides, paywall, match).
  poster,

  /// Smaller hand-lettered line (poster sub-lines, card names).
  posterSmall,

  /// Serif used for bios and quotes on profiles.
  bio,
  bioSmall,
}

abstract final class SynkTypography {
  /// Bundled variable-weight family; falls back to the platform font for other scripts.
  static const String fontFamily = 'Manrope';

  /// Hand-lettered marker face of the brand's headings (Apache 2.0, bundled).
  static const String posterFamily = 'PermanentMarker';

  /// Serif of bios and profile quotes (SIL OFL, bundled).
  static const String serifFamily = 'YoungSerif';

  static const FontWeight _regular = FontWeight.w400;
  static const FontWeight _medium = FontWeight.w500;
  static const FontWeight _semi = FontWeight.w600;
  static const FontWeight _bold = FontWeight.w700;

  static TextStyle _s(
    double size,
    FontWeight weight, {
    double? lineHeight,
    double letterSpacing = 0,
    String family = fontFamily,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: lineHeight == null ? null : lineHeight / size,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static final Map<SynkTextVariant, TextStyle> _styles = {
    // Screen titles use the hand-lettered brand face.
    SynkTextVariant.h1: _s(
      30,
      _regular,
      lineHeight: 40,
      letterSpacing: 0.2,
      family: posterFamily,
    ),
    SynkTextVariant.h2: _s(
      24,
      _regular,
      lineHeight: 32,
      letterSpacing: 0.2,
      family: posterFamily,
    ),
    SynkTextVariant.h3: _s(20, _semi, lineHeight: 28, letterSpacing: -0.2),
    SynkTextVariant.p: _s(16, _regular, lineHeight: 24, letterSpacing: 0.15),
    SynkTextVariant.large: _s(18, _medium, lineHeight: 28, letterSpacing: 0.15),
    SynkTextVariant.small: _s(14, _medium, lineHeight: 20, letterSpacing: 0.4),
    SynkTextVariant.lead: _s(20, _regular, lineHeight: 30, letterSpacing: 0.15),
    SynkTextVariant.muted: _s(14, _regular, lineHeight: 20, letterSpacing: 0.4),
    SynkTextVariant.buttonDefault: _s(15, _semi),
    SynkTextVariant.buttonSmall: _s(14, _semi),
    SynkTextVariant.buttonLarge: _s(17, _semi),
    SynkTextVariant.cardTitle: _s(18, _semi, letterSpacing: -0.3),
    SynkTextVariant.cardDescription: _s(14, _regular, lineHeight: 20),
    SynkTextVariant.drawerTitle: _s(18, _semi, letterSpacing: -0.2),
    SynkTextVariant.dialogTitle: _s(19, _semi, letterSpacing: -0.3),
    SynkTextVariant.popoverTitle: _s(16, _semi, letterSpacing: -0.2),
    SynkTextVariant.description: _s(14, _regular, lineHeight: 20),
    SynkTextVariant.badge: _s(12, _semi, lineHeight: 16, letterSpacing: 0.2),
    SynkTextVariant.badgeSmall: _s(
      10,
      _semi,
      lineHeight: 14,
      letterSpacing: 0.4,
    ),
    SynkTextVariant.listTitle: _s(14, _semi),
    SynkTextVariant.listDescription: _s(11, _regular),
    SynkTextVariant.toastTitle: _s(14, _semi),
    SynkTextVariant.toastDescription: _s(13, _regular),
    SynkTextVariant.input: _s(16, _regular, lineHeight: 22),
    SynkTextVariant.sectionLabel: _s(
      12,
      _semi,
      lineHeight: 20,
      letterSpacing: 1.0,
    ),
    SynkTextVariant.sectionLabelSmall: _s(11, _bold, letterSpacing: 0.6),
    // Refreshed UI.
    SynkTextVariant.display: _s(
      30,
      FontWeight.w300,
      lineHeight: 36,
      letterSpacing: -0.8,
    ),
    SynkTextVariant.statXl: _s(44, _bold, lineHeight: 48, letterSpacing: -1.2),
    SynkTextVariant.statLg: _s(28, _bold, lineHeight: 32, letterSpacing: -0.6),
    SynkTextVariant.statUnit: _s(14, _medium, lineHeight: 20),
    SynkTextVariant.caption: _s(
      12,
      _regular,
      lineHeight: 16,
      letterSpacing: 0.2,
    ),
    SynkTextVariant.tab: _s(14, _semi, lineHeight: 20),
    // Brand.
    SynkTextVariant.poster: _s(
      44,
      _regular,
      lineHeight: 46,
      letterSpacing: 0.5,
      family: posterFamily,
    ),
    SynkTextVariant.posterSmall: _s(
      24,
      _regular,
      lineHeight: 28,
      letterSpacing: 0.4,
      family: posterFamily,
    ),
    SynkTextVariant.bio: _s(18, _regular, lineHeight: 26, family: serifFamily),
    SynkTextVariant.bioSmall: _s(
      14,
      _regular,
      lineHeight: 20,
      family: serifFamily,
    ),
  };

  static TextStyle of(SynkTextVariant variant) => _styles[variant]!;

  /// Style for the emphasised words of a mixed-weight headline ("Your **Groups**").
  static TextStyle displayEmphasis() =>
      of(SynkTextVariant.display).copyWith(fontWeight: FontWeight.w800);
}
