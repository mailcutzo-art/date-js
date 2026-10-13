import 'dart:math' as math;
import 'dart:ui' show Color;

/// WCAG 2.x contrast ratio (1 to 21) between [a] and [b], both treated as opaque.
double contrastBetween(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The one of [light] and [dark] that reads better on [background]: [light] unless [dark] has
/// the higher contrast. Used where the background is a colour the user picked (an avatar
/// circle), so a fixed white label cannot be guaranteed to be readable.
Color readableOn(
  Color background, {
  required Color light,
  required Color dark,
}) => contrastBetween(light, background) >= contrastBetween(dark, background)
    ? light
    : dark;

/// [color] moved towards black or white (whichever the [background] is further from), just far
/// enough to reach [ratio] against it; [color] itself when it already does. Keeps the hue, so a
/// label in a colour the user picked (a member's colour) stays recognisably theirs and readable.
Color atLeastContrast(Color color, Color background, {double ratio = 4.5}) {
  if (contrastBetween(color, background) >= ratio) return color;
  final towards = background.computeLuminance() > 0.5
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);
  for (var step = 1; step < 20; step++) {
    final candidate = Color.lerp(color, towards, step * 0.05)!;
    if (contrastBetween(candidate, background) >= ratio) return candidate;
  }
  return towards;
}
