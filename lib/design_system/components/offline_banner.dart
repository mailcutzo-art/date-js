import 'package:flutter/material.dart';

import '../foundation/hairline.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_spinner.dart';
import 'synk_text.dart';

/// Full-width connectivity banner above the chat list: muted fill, hairline bottom border and a
/// centred 14sp medium [message] ("Offline — messages will send when you reconnect"). While
/// [reconnecting] a small spinner precedes the text.
///
/// The banner is a live region, so screen readers announce it when it appears or its text
/// changes. Long messages wrap onto a second line instead of clipping (large text scales).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.message,
    this.reconnecting = false,
  });

  final String message;
  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.muted,
          border: Border(
            bottom: BorderSide(color: colors.border, width: hairline(context)),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                if (reconnecting)
                  ExcludeSemantics(
                    child: SynkSpinner(size: 14, color: colors.mutedForeground),
                  ),
                Flexible(
                  child: SynkText(
                    message,
                    variant: SynkTextVariant.small,
                    color: colors.mutedForeground,
                    style: const TextStyle(letterSpacing: 0),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
