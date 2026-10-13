import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Profile-trend axis label for a value in seconds (port of `Formatters.watchAxis`):
/// `Mm`, `Xh` or `XhY`. Fractions of a second are dropped.
String watchAxisLabel(double seconds) {
  final whole = seconds.isFinite ? seconds.truncate() : 0;
  final minutes = (whole / 60).round();
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h <= 0) return '${minutes}m';
  if (m == 0) return '${h}h';
  return '${h}h$m';
}

/// Geometry of the smooth area chart: a 700 x 200 view box stretched to the canvas (like an SVG
/// with `preserveAspectRatio="none"`) with 4 / 4 / 8 / 8 padding (left, right, top, bottom).
abstract final class WatchTrendGeometry {
  static const double viewWidth = 700;
  static const double viewHeight = 200;
  static const double padLeft = 4;
  static const double padRight = 4;
  static const double padTop = 8;
  static const double padBottom = 8;

  /// Gridlines at these fractions of the inner height (measured from the top).
  static const List<double> gridFractions = <double>[0.25, 0.5, 0.75];

  static const double innerWidth = viewWidth - padLeft - padRight;
  static const double innerHeight = viewHeight - padTop - padBottom;

  /// Negative and non-finite values count as 0.
  static List<double> sanitize(List<double> values) => <double>[
    for (final v in values) (v.isFinite && v > 0) ? v : 0.0,
  ];

  /// Largest value (0 for an empty list).
  static double maxOf(List<double> values) =>
      sanitize(values).fold<double>(0, math.max);

  /// Data points on a canvas of [size]; `y = padTop + innerH - (v / max) * innerH`, evenly spaced
  /// on x. Values are clamped to `[0, max]`.
  static List<Offset> points(List<double> values, Size size) {
    final clean = sanitize(values);
    if (clean.isEmpty) return const <Offset>[];
    final peak = clean.fold<double>(0, math.max);
    final denom = peak > 0 ? peak : 1.0;
    final sx = size.width / viewWidth;
    final sy = size.height / viewHeight;
    final step = clean.length <= 1 ? 0.0 : innerWidth / (clean.length - 1);
    return <Offset>[
      for (var i = 0; i < clean.length; i++)
        Offset(
          (padLeft + i * step) * sx,
          (padTop + innerHeight - (clean[i] / denom) * innerHeight) * sy,
        ),
    ];
  }

  /// Cubic through [points] with control points at the horizontal midpoint of each pair
  /// (flat tangents at every point, so the curve never overshoots the data).
  static Path linePath(List<Offset> points) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        final prev = points[i - 1];
        final cx = prev.dx + (p.dx - prev.dx) / 2;
        path.cubicTo(cx, prev.dy, cx, p.dy, p.dx, p.dy);
      }
    }
    return path;
  }

  /// Canvas y of the zero baseline.
  static double baselineY(Size size) =>
      (padTop + innerHeight) * size.height / viewHeight;

  /// Canvas y of the gridline at [fraction] of the inner height from the top.
  static double gridY(Size size, double fraction) =>
      (padTop + innerHeight * fraction) * size.height / viewHeight;
}

/// Last-N-days watch trend: a smooth gradient area chart with a y-axis gutter and a label row
/// (the profile "Last 7 days" chart without its card).
///
/// * [values] `null` shows 7 skeleton bars (loading).
/// * Values that sum to zero show a dashed box with [emptyText].
/// * [failed] shows a destructive "Could not load" line (and, without values, the dashed box).
class WatchTrendChart extends StatelessWidget {
  const WatchTrendChart({
    this.values,
    this.labels,
    this.accent,
    this.failed = false,
    this.axisLabel,
    this.emptyText = 'No watch time in the last 7 days',
    super.key,
  });

  /// One value per day, oldest first (seconds with the default [axisLabel]).
  final List<double>? values;

  /// One label per value under the chart (weekday names).
  final List<String>? labels;

  /// Line and fill colour; defaults to `primary`.
  final Color? accent;
  final bool failed;

  /// Formats y-axis values; defaults to [watchAxisLabel].
  final String Function(double)? axisLabel;
  final String emptyText;

  /// Height of the plot area.
  static const double chartHeight = 160;

  /// Width of the y-axis label column.
  static const double axisWidth = 32;

  /// Gap between the label column and the plot.
  static const double axisGap = 8;

  /// Left gutter taken by the axis labels (also the inset of the weekday row).
  static const double gutter = axisWidth + axisGap;

  /// Heights of the loading skeleton bars as fractions of the plot height.
  static const List<double> skeletonFractions = <double>[
    0.38,
    0.62,
    0.44,
    0.78,
    0.52,
    0.34,
    0.58,
  ];

  String _semanticSummary(String Function(double) format) {
    final data = values;
    if (data == null) return failed ? 'Could not load' : 'Loading';
    if (WatchTrendGeometry.maxOf(data) <= 0) return emptyText;
    final names = labels ?? const <String>[];
    final parts = <String>[
      for (var i = 0; i < data.length; i++)
        '${i < names.length ? '${names[i]} ' : ''}'
            '${format(WatchTrendGeometry.sanitize(data)[i])}',
    ];
    final summary = 'Watch time: ${parts.join(', ')}';
    return failed ? '$summary. Could not load the latest data' : summary;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final format = axisLabel ?? watchAxisLabel;
    final data = values;
    final hasData = data != null && WatchTrendGeometry.maxOf(data) > 0;

    final Widget plot;
    if (data == null && !failed) {
      plot = const _SkeletonPlot();
    } else if (!hasData) {
      plot = _DashedBox(
        text: data == null ? 'Could not load' : emptyText,
        textColor: data == null ? colors.destructive : colors.mutedForeground,
      );
    } else {
      plot = _AreaPlot(
        values: data,
        accent: accent ?? colors.primary,
        axisLabel: format,
      );
    }

    final showLabels = data != null && labels != null && labels!.isNotEmpty;
    return Semantics(
      container: true,
      label: _semanticSummary(format),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failed && data != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SynkText(
                'Could not load',
                variant: SynkTextVariant.caption,
                color: colors.destructive,
              ),
            ),
          SizedBox(height: chartHeight, child: plot),
          if (showLabels)
            Padding(
              padding: const EdgeInsets.only(left: gutter, right: 4, top: 6),
              child: Row(
                children: [
                  for (final label in labels!)
                    Expanded(
                      child: SynkText(
                        label,
                        variant: SynkTextVariant.caption,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AreaPlot extends StatelessWidget {
  const _AreaPlot({
    required this.values,
    required this.accent,
    required this.axisLabel,
  });

  final List<double> values;
  final Color accent;
  final String Function(double) axisLabel;

  @override
  Widget build(BuildContext context) {
    final peak = WatchTrendGeometry.maxOf(values);
    final labels = <String>[axisLabel(peak), axisLabel(peak / 2), axisLabel(0)];
    return Row(
      children: [
        SizedBox(
          width: WatchTrendChart.axisWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final label in labels)
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: SynkText(
                        label,
                        variant: SynkTextVariant.caption,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: WatchTrendChart.axisGap),
        Expanded(
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: WatchTrendPainter(
                values: values,
                accent: accent,
                gridColor: context.colors.border,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints gridlines, the gradient area and the 2 dp line.
class WatchTrendPainter extends CustomPainter {
  WatchTrendPainter({
    required this.values,
    required this.accent,
    required this.gridColor,
  });

  final List<double> values;
  final Color accent;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || values.isEmpty) return;
    final sx = size.width / WatchTrendGeometry.viewWidth;

    // Dashed gridlines at 25 / 50 / 75 %.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final x0 = WatchTrendGeometry.padLeft * sx;
    final x1 =
        (WatchTrendGeometry.viewWidth - WatchTrendGeometry.padRight) * sx;
    for (final f in WatchTrendGeometry.gridFractions) {
      final y = WatchTrendGeometry.gridY(size, f);
      for (var x = x0; x < x1; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, x1), y), grid);
      }
    }

    final points = WatchTrendGeometry.points(values, size);
    if (points.length == 1) {
      canvas.drawCircle(points.first, 3, Paint()..color = accent);
      return;
    }
    final line = WatchTrendGeometry.linePath(points);
    final baseY = WatchTrendGeometry.baselineY(size);
    final area = Path.from(line)
      ..lineTo(points.last.dx, baseY)
      ..lineTo(points.first.dx, baseY)
      ..close();
    final top = points.fold<double>(baseY, (m, p) => math.min(m, p.dy));
    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, top), Offset(0, baseY), [
          accent.withValues(alpha: 0.55),
          accent.withValues(alpha: 0.05),
        ]),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(WatchTrendPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.gridColor != gridColor ||
      !_sameValues(oldDelegate.values, values);

  static bool _sameValues(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _SkeletonPlot extends StatelessWidget {
  const _SkeletonPlot();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        const SizedBox(width: WatchTrendChart.gutter),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.border,
                  width: 1 / MediaQuery.devicePixelRatioOf(context),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final fraction in WatchTrendChart.skeletonFractions)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: FractionallySizedBox(
                          heightFactor: fraction,
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.muted,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBox extends StatelessWidget {
  const _DashedBox({required this.text, required this.textColor});

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: context.colors.border),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SynkText(
            text,
            variant: SynkTextVariant.caption,
            color: textColor,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.3, letterSpacing: 0),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 1.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        stroke / 2,
        stroke / 2,
        size.width - stroke,
        size.height - stroke,
      ),
      const Radius.circular(8),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final dashed = Path();
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        dashed.addPath(metric.extractPath(d, d + 3), Offset.zero);
        d += 6;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
