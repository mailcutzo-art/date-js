import 'package:flutter/painting.dart';

import '../design_system/design_system.dart';

/// Brand colour that is safe to use as text, an icon or a border on the page background.
///
/// The theme's dark `primary` (a deep burgundy) is meant for filled surfaces; as text on the dark
/// background it falls well below 4.5:1, so dark mode uses the lighter brand pink instead.
extension BrandColors on SynkColors {
  Color get brandText => isDark ? SynkPalette.brandPinkText : primary;
}
