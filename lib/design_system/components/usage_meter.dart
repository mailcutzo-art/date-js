import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/hairline.dart';
import '../icons/synk_icon.dart';
import '../tokens/synk_colors.dart';
import '../tokens/synk_motion.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'pastel_card.dart';
import 'skeleton.dart';
import 'synk_badge.dart';
import 'synk_text.dart';

/// Segmented usage meter of the refreshed UI: a row of equal-width, fully rounded pills.
/// `round(fraction * segments)` pills (clamped) are filled with the tone accent; the remaining
/// ones are dashed hairline outlines.
///
/// The meter takes the full width its parent offers (it needs a bounded width).
/// The fill sweeps left to right whenever the filled count changes (and on first show);
/// it is instant when the platform asks to reduce motion.
class UsageMeter extends StatelessWidget {
  const UsageMeter({
    super.key,
    required this.fraction,
    this.segments = 8,
    this.tone = SynkTone.lavender,
    this.height = 40,
    this.gap = 6,
    this.semanticLabel,
  }) : assert(segments > 0, 'segments must be positive');

  /// Share of the quota used. Clamped to 0..1 (NaN counts as 0).
  final double fraction;

  /// Number of pills.
  final int segments;

  /// Picks the fill colour ([SynkColors.toneAccent]).
  final SynkTone tone;

  /// Pill height in dp. Pill width follows from the available width.
  final double height;

  /// Space between pills in dp.
  final double gap;

  /// Names what is measured ("Storage"); the percentage is added as the semantic value.
  final String? semanticLabel;

  /// Time the fill takes to sweep to a new value.
  static const Duration fillDuration = Duration(milliseconds: 650);

  /// Number of filled pills for [fraction] over [segments]: `round(fraction * segments)`
  /// clamped to `0..segments`.
  static int filledSegments(double fraction, int segments) {
    if (fraction.isNaN) return 0;
    // Clamp before multiplying so infinite fractions cannot reach `round()`.
    return (fraction.clamp(0.0, 1.0) * segments).round();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final target = filledSegments(fraction, segments).toDouble();
    final animate = !MediaQuery.disableAnimationsOf(context);
    final strokeWidth = hairline2(context);
    final percent = ((fraction.isNaN ? 0.0 : fraction).clamp(0.0, 1.0) * 100)
        .round();
    return Semantics(
      label: semanticLabel,
      value: '$percent%',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: target),
            duration: animate ? fillDuration : Duration.zero,
            curve: SynkMotion.easeOutCubic,
            builder: (context, filled, _) => CustomPaint(
              size: Size.infinite,
              painter: UsageMeterPainter(
                filled: filled,
                segments: segments,
                gap: gap,
                fillColor: colors.toneAccent(tone),
                dashColor: colors.mutedForeground.withValues(alpha: 0.55),
                strokeWidth: strokeWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the pills of a [UsageMeter]. [filled] is the (possibly fractional, while animating)
/// number of filled pills: pill `i` is filled by `clamp(filled - i, 0, 1)` from its left edge.
@visibleForTesting
class UsageMeterPainter extends CustomPainter {
  const UsageMeterPainter({
    required this.filled,
    required this.segments,
    required this.gap,
    required this.fillColor,
    required this.dashColor,
    required this.strokeWidth,
  });

  final double filled;
  final int segments;
  final double gap;
  final Color fillColor;
  final Color dashColor;
  final double strokeWidth;

  static const double dashLength = 3;
  static const double dashGap = 3;

  /// Width of one pill for a meter [totalWidth] wide.
  static double segmentWidth(double totalWidth, int segments, double gap) =>
      (totalWidth - gap * (segments - 1)) / segments;

  @override
  void paint(Canvas canvas, Size size) {
    final width = segmentWidth(size.width, segments, gap);
    if (width <= 0 || size.height <= 0) return;
    final radius = Radius.circular(math.min(width, size.height) / 2);
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, size.height),
      radius,
    );
    final fillPaint = Paint()
      ..color = fillColor
      ..isAntiAlias = true;
    // The outline sits fully inside the pill so it never peeks out from under the fill.
    final dashed = dashedPath(
      pill.deflate(strokeWidth / 2),
      dashLength,
      dashGap,
    );
    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    for (var i = 0; i < segments; i++) {
      final share = (filled - i).clamp(0.0, 1.0);
      canvas
        ..save()
        ..translate(i * (width + gap), 0);
      if (share < 1) canvas.drawPath(dashed, dashPaint);
      if (share >= 1) {
        canvas.drawRRect(pill, fillPaint);
      } else if (share > 0) {
        canvas
          ..clipRRect(pill)
          ..drawRect(
            Rect.fromLTWH(0, 0, width * share, size.height),
            fillPaint,
          );
      }
      canvas.restore();
    }
  }

  /// Dashes [rrect] with a [dash] on / [gap] off pattern. The pattern is stretched by a few
  /// percent so a whole number of periods fits the perimeter: no short dash at the seam.
  @visibleForTesting
  static Path dashedPath(RRect rrect, double dash, double gap) {
    final out = Path();
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      final periods = math.max(1, (metric.length / (dash + gap)).round());
      final period = metric.length / periods;
      final on = period * dash / (dash + gap);
      for (var i = 0; i < periods; i++) {
        out.addPath(
          metric.extractPath(i * period, i * period + on),
          Offset.zero,
        );
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(UsageMeterPainter old) =>
      old.filled != filled ||
      old.segments != segments ||
      old.gap != gap ||
      old.fillColor != fillColor ||
      old.dashColor != dashColor ||
      old.strokeWidth != strokeWidth;
}

/// The reference's "Operations  72% Used  780 / 1 000" card: a white circular icon bubble and
/// [title] on one row with a black pill [badgeText], the big stat [valueText] with a small
/// [unitText] ("/ 1 000"), and a [UsageMeter] below, all on a pastel surface.
///
/// [loading] swaps the content for a skeleton layout of the same height.
/// The whole card is one semantic node ("title, badge, value unit") and a button with [onTap].
class UsageMeterCard extends StatelessWidget {
  const UsageMeterCard({
    super.key,
    required this.title,
    required this.icon,
    required this.badgeText,
    required this.valueText,
    this.unitText,
    required this.fraction,
    this.tone = SynkTone.lavender,
    this.segments = 8,
    this.onTap,
    this.loading = false,
  });

  final String title;
  final SynkIcons icon;
  final String badgeText;
  final String valueText;
  final String? unitText;
  final double fraction;
  final SynkTone tone;
  final int segments;
  final VoidCallback? onTap;
  final bool loading;

  static const double _bubble = 40;

  /// Capsule height of the card's meter (taller than wide, like the reference).
  static const double _meterHeight = 48;

  String get _semanticLabel {
    final unit = unitText == null ? '' : ' $unitText';
    return '$title, $badgeText, $valueText$unit';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    final body = loading
        ? _skeleton(scale)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 12,
                children: [
                  _IconBubble(icon: icon, tone: tone),
                  Expanded(
                    child: SynkText(
                      title,
                      variant: SynkTextVariant.popoverTitle,
                      maxLines: 2,
                    ),
                  ),
                  SynkBadge(text: badgeText, variant: SynkBadgeVariant.ink),
                ],
              ),
              const SizedBox(height: 20),
              _ValueRow(valueText: valueText, unitText: unitText),
              const SizedBox(height: 16),
              UsageMeter(
                fraction: fraction,
                segments: segments,
                tone: tone,
                height: _meterHeight,
              ),
            ],
          );
    return PastelCard(
      tone: tone,
      onTap: loading ? null : onTap,
      semanticLabel: loading ? '$title, loading' : _semanticLabel,
      // One merged semantic node for the whole card.
      child: ExcludeSemantics(child: body),
    );
  }

  Widget _skeleton(TextScaler scale) {
    final valueHeight = scale.scale(48);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          spacing: 12,
          children: [
            Skeleton(width: _bubble, height: _bubble, radius: _bubble / 2),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Skeleton(width: 96, height: 14, radius: 7),
              ),
            ),
            Skeleton(width: 76, height: 26, radius: SynkRadius.full),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            height: valueHeight,
            child: const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Skeleton(width: 132, height: 36, radius: 10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: _meterHeight,
          child: Row(
            spacing: 6,
            children: [
              for (var i = 0; i < segments; i++)
                const Expanded(child: Skeleton(radius: SynkRadius.full)),
            ],
          ),
        ),
      ],
    );
  }
}

/// White circular bubble holding the card icon (tinted card colour in dark mode).
class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.tone});

  final SynkIcons icon;
  final SynkTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = tone == SynkTone.neutral
        ? colors.muted
        : colors.isDark
        ? colors.foreground.withValues(alpha: 0.10)
        : colors.card;
    return Container(
      width: UsageMeterCard._bubble,
      height: UsageMeterCard._bubble,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: SynkIcon(icon, size: SynkIconSize.lg, color: colors.foreground),
    );
  }
}

/// Big stat number with its small unit on a shared baseline; scales down rather than overflow.
class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.valueText, required this.unitText});

  final String valueText;
  final String? unitText;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: 6,
      children: [
        SynkText(valueText, variant: SynkTextVariant.statXl, maxLines: 1),
        if (unitText != null)
          SynkText(unitText!, variant: SynkTextVariant.statUnit, maxLines: 1),
      ],
    ),
  );
}
