import 'package:flutter/painting.dart';

/// Corner radii (ported `Radius` object) plus the larger pastel-card radius.
abstract final class SynkRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;

  /// Pastel hero cards of the refreshed UI.
  static const double xxl = 28;
  static const double full = 9999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));

  /// Top corners only (bottom sheets).
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
