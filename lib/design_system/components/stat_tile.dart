import 'package:flutter/material.dart';

import '../foundation/pressable.dart';
import '../tokens/synk_colors.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'skeleton.dart';
import 'synk_text.dart';

/// Small statistic tile of the groups overview ("LIFETIME WATCHED  12h 30m  Shared watch time").
///
/// States, in order of precedence:
///  * [loading]: two skeleton bars under the label;
///  * error: [errorText] set and no [value], shows the error (default "Unavailable") with a
///    ghost "Retry" button when [onRetry] is given;
///  * content: [value] (15/700) with optional [valueTrailing] (an emoji, a [SynkBadge]) and an
///    optional [caption].
///
/// The neutral tone is the muted/border tile of the Android app (radius 10); any pastel [tone]
/// switches to the soft pastel surface with the larger radius of the refreshed UI.
/// Outside the error state the tile reads as one semantic node.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    this.value,
    this.caption,
    this.valueTrailing,
    this.loading = false,
    this.errorText,
    this.onRetry,
    this.tone = SynkTone.neutral,
  });

  final String label;
  final String? value;
  final String? caption;
  final Widget? valueTrailing;
  final bool loading;

  /// Marks the error state when [value] is null. An empty string shows "Unavailable".
  final String? errorText;
  final VoidCallback? onRetry;
  final SynkTone tone;

  static const String unavailable = 'Unavailable';

  bool get _isError => !loading && value == null && errorText != null;

  /// Border at 40 % in light mode. The dark border is already translucent (8 % white); forcing it
  /// to 40 % would turn it into a bright outline, so it is used as is.
  static Color _outline(SynkColors colors) =>
      colors.isDark ? colors.border : colors.border.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pastel = tone != SynkTone.neutral;
    final radius = BorderRadius.circular(pastel ? SynkRadius.lg : 10);
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: pastel
            ? colors.toneSurface(tone)
            : colors.muted.withValues(alpha: 0.5),
        borderRadius: radius,
        border: pastel ? null : Border.all(color: _outline(colors)),
      ),
      child: Padding(
        padding: EdgeInsets.all(pastel ? 14 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            SynkText(
              label.toUpperCase(),
              variant: SynkTextVariant.caption,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                height: 1.3,
              ),
              semanticsLabel: label,
            ),
            ..._body(context),
          ],
        ),
      ),
    );
    final sized = SizedBox(width: double.infinity, child: tile);
    return _isError ? sized : MergeSemantics(child: sized);
  }

  List<Widget> _body(BuildContext context) {
    final colors = context.colors;
    if (loading) {
      return const [
        _SkeletonBar(widthFactor: 0.7, height: 16),
        _SkeletonBar(widthFactor: 0.5, height: 10),
      ];
    }
    if (_isError) {
      final message = errorText!.isEmpty ? unavailable : errorText!;
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            Flexible(
              child: SynkText(
                message,
                variant: SynkTextVariant.listDescription,
                color: colors.destructive,
              ),
            ),
            if (onRetry != null) _GhostRetry(onTap: onRetry!),
          ],
        ),
      ];
    }
    return [
      if (value != null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 4,
          children: [
            Flexible(
              child: SynkText(
                value!,
                variant: SynkTextVariant.buttonDefault,
                style: const TextStyle(fontWeight: FontWeight.w700),
                maxLines: 3,
              ),
            ),
            ?valueTrailing,
          ],
        ),
      if (caption != null)
        SynkText(
          caption!,
          variant: SynkTextVariant.listDescription,
          maxLines: 3,
        ),
    ];
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    alignment: AlignmentDirectional.centerStart,
    child: Skeleton(height: height),
  );
}

/// Compact ghost "Retry" button (36dp, no fill) used inside the error state.
class _GhostRetry extends StatelessWidget {
  const _GhostRetry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SynkPressable(
    onTap: onTap,
    semanticLabel: 'Retry',
    pressedOpacity: 0.6,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
      child: const Center(
        widthFactor: 1,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: ExcludeSemantics(
            child: SynkText('Retry', variant: SynkTextVariant.buttonSmall),
          ),
        ),
      ),
    ),
  );
}
