import 'package:flutter/painting.dart';

import '../design_system/design_system.dart';

/// Brand colour that is safe to use as text, an icon or a border on the page background.
///
/// The hot magenta fill is too light for text on white, so light mode uses a deeper magenta and
/// dark mode a lighter one (see [SynkColors.primaryText]).
extension BrandColors on SynkColors {
  Color get brandText => primaryText;

  /// Fill of incoming chat bubbles, photo frames and interest chips.
  Color get creamSurface => isDark ? muted : SynkPalette.cream;
}
