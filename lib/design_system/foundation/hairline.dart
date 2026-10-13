import 'package:flutter/widgets.dart';

/// Exactly one physical pixel (avatar rings, borders, separators).
double hairline(BuildContext context) =>
    1 / MediaQuery.devicePixelRatioOf(context);

/// Exactly two physical pixels (glass borders).
double hairline2(BuildContext context) =>
    2 / MediaQuery.devicePixelRatioOf(context);
