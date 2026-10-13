import 'package:flutter/material.dart';

import '../tokens/synk_palette.dart';
import 'synk_glyph.dart';

/// The four-colour Google "G" (48x48 viewbox), used by the sign-in button.
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({this.size = 20, super.key});

  final double size;

  static const List<(Color, String)> _parts = [
    (
      SynkPalette.googleYellow,
      'M43.6 20.5H42V20H24v8h11.3c-1.7 4.7-6.2 8-11.3 8-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.9 1.2 8 3l5.7-5.7C34 6 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20c11 0 19.9-8 19.9-20 0-1.3-.1-2.3-.3-3.5z',
    ),
    (
      SynkPalette.googleRed,
      'M6.3 14.7l6.6 4.8C14.7 16 19 13 24 13c3.1 0 5.9 1.2 8 3l5.7-5.7C34 6 29.3 4 24 4 16.3 4 9.6 8.3 6.3 14.7z',
    ),
    (
      SynkPalette.googleGreen,
      'M24 44c5.2 0 9.8-2 13.3-5.2l-6.2-5.2C29.1 35 26.7 36 24 36c-5.1 0-9.4-3.2-11.1-7.9l-6.5 5C9.6 39.7 16.3 44 24 44z',
    ),
    (
      SynkPalette.googleBlue,
      'M43.6 20.5H42V20H24v8h11.3c-.8 2.2-2.3 4.1-4.2 5.4l6.2 5.2c-.4.4 6.7-4.9 6.7-14.6 0-1.3-.1-2.3-.4-3.5z',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _GooglePainter()),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 48, size.height / 48);
    for (final (color, d) in GoogleGlyph._parts) {
      canvas.drawPath(parseSvgPath(d), Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}
