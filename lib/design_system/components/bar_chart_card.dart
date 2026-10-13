import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../foundation/tap_target.dart';
import '../tokens/synk_motion.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// A legend entry and the colour of one stacked segment.
@immutable
class BarChartSeries {
  const BarChartSeries({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is BarChartSeries && other.label == label && other.color == color;

  @override
  int get hashCode => Object.hash(label, color);
}

/// One stacked bar: [bottom] and [top] are stacked in that order and `bottom + top <= max`.
@immutable
class BarChartDatum {
  const BarChartDatum({
    required this.xLabel,
    required this.bottom,
    required this.top,
  });

  final String xLabel;
  final double bottom;
  final double top;

  @override
  bool operator ==(Object other) =>
      other is BarChartDatum &&
      other.xLabel == xLabel &&
      other.bottom == bottom &&
      other.top == top;

  @override
  int get hashCode => Object.hash(xLabel, bottom, top);
}

/// A datum clamped into `[0, max]` (in data units): the stacked [bottom] and [top] segments and
/// the unfilled [rest].
@immutable
class BarChartSegments {
  const BarChartSegments({
    required this.bottom,
    required this.top,
    required this.rest,
    required this.max,
  });

  /// Clamps [datum]: negative and non-finite parts count as 0, [bottom] is capped at [max] and
  /// [top] at what is left above it. A non-positive or non-finite [max] counts as 1.
  factory BarChartSegments.of(BarChartDatum datum, double max) {
    final cap = (max.isFinite && max > 0) ? max : 1.0;
    double clean(double v) => v.isFinite && v > 0 ? v : 0.0;
    final bottom = math.min(clean(datum.bottom), cap);
    final top = math.min(clean(datum.top), cap - bottom);
    return BarChartSegments(
      bottom: bottom,
      top: top,
      rest: cap - bottom - top,
      max: cap,
    );
  }

  final double bottom;
  final double top;
  final double rest;
  final double max;

  double get filled => bottom + top;

  /// Filled share of [max] (0..1).
  double get fraction => filled / max;

  /// Whole-number percentage of [max] that is filled (the default tooltip).
  int get percent => (fraction * 100).round();
}

/// Horizontal geometry of the bars inside a plot of [width].
class BarChartMetrics {
  const BarChartMetrics({required this.width, required this.count});

  final double width;
  final int count;

  /// Widest a bar gets (a single bar does not stretch across the card).
  static const double maxBarWidth = 44;

  /// Share of its slot a bar occupies.
  static const double barSlotShare = 0.62;

  double get slot => count == 0 ? width : width / count;
  double get barWidth => math.min(maxBarWidth, slot * barSlotShare);
  double centerX(int index) => slot * (index + 0.5);
  double left(int index) => centerX(index) - barWidth / 2;

  /// Index of the bar whose slot contains [dx], or -1.
  int indexAt(double dx) {
    if (count == 0 || dx < 0 || dx > width) return -1;
    return math.min(count - 1, (dx / slot).floor());
  }
}

/// The reference "Statistics" card: a rounded panel with a title row, y-axis ticks, rounded
/// stacked bars (the unfilled remainder drawn as a diagonal-hatched ghost), a dark tooltip badge
/// above the selected bar, x labels and legend chips. Bars grow from 0 on first build and
/// whenever [data] changes.
///
/// [series] is `[bottomSeries, topSeries]`. Selection works with or without a parent: tapping a
/// bar highlights it and calls [onSelected]; changing [selectedIndex] moves it.
class BarChartCard extends StatefulWidget {
  const BarChartCard({
    required this.title,
    required this.data,
    required this.series,
    this.max = 1.0,
    this.selectedIndex = -1,
    this.onSelected,
    this.trailing,
    this.tooltipText,
    this.loading = false,
    this.failed = false,
    this.emptyText = 'No data yet',
    this.failedText = 'Could not load',
    this.yTicks = 10,
    this.yLabel,
    this.plotHeight = 176,
    super.key,
  }) : assert(yTicks > 0, 'yTicks must be positive');

  final String title;
  final List<BarChartDatum> data;

  /// `[bottomSeries, topSeries]`.
  final List<BarChartSeries> series;

  /// Value at the top of the y-axis.
  final double max;

  /// Selected bar (-1 for none) whose tooltip is shown.
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  /// Right side of the title row (e.g. a year dropdown chip).
  final Widget? trailing;

  /// Tooltip text; defaults to the filled percentage of [max] ("87%").
  final String Function(BarChartDatum)? tooltipText;

  /// Shows a skeleton instead of the bars.
  final bool loading;

  /// Shows [failedText] instead of the bars.
  final bool failed;
  final String emptyText;
  final String failedText;

  /// Number of y-axis ticks (labels `max/ticks .. max`).
  final int yTicks;

  /// y-axis label formatter; defaults to 1 decimal ("0.1" .. "1.0").
  final String Function(double)? yLabel;

  /// Height of the bar area (without the tooltip band).
  final double plotHeight;

  /// Width of the y-axis label column.
  static const double axisWidth = 30;
  static const double axisGap = 8;
  static const double growDurationMs = 700;

  @override
  State<BarChartCard> createState() => _BarChartCardState();
}

class _BarChartCardState extends State<BarChartCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _controller,
    curve: SynkMotion.easeOutCubic,
  );
  late int _selected = widget.selectedIndex;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _grow();
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }
  }

  void _grow() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(BarChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selected = widget.selectedIndex;
    }
    final changed =
        widget.max != oldWidget.max ||
        widget.data.length != oldWidget.data.length ||
        !_sameData(widget.data, oldWidget.data);
    if (changed) _grow();
  }

  static bool _sameData(List<BarChartDatum> a, List<BarChartDatum> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _selected = index);
    widget.onSelected?.call(index);
  }

  String _tooltipFor(BarChartDatum datum) {
    final custom = widget.tooltipText;
    if (custom != null) return custom(datum);
    return '${BarChartSegments.of(datum, widget.max).percent}%';
  }

  String _defaultYLabel(double v) {
    final step = widget.max / widget.yTicks;
    final decimals = step >= 1 ? 0 : (step >= 0.1 ? 1 : 2);
    return v.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottom = widget.series.isNotEmpty
        ? widget.series[0]
        : BarChartSeries(label: '', color: colors.blueGrey);
    final top = widget.series.length > 1
        ? widget.series[1]
        : BarChartSeries(label: '', color: colors.chartPink);
    final hairline = 1 / MediaQuery.devicePixelRatioOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: SynkRadius.xlAll,
        border: Border.all(color: colors.border, width: hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: SynkText(
                    widget.title,
                    variant: SynkTextVariant.cardTitle,
                    maxLines: 1,
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 12),
                  widget.trailing!,
                ],
              ],
            ),
            const SizedBox(height: 14),
            _buildChart(context, bottom, top, scale),
            if (widget.series.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in widget.series) _LegendChip(series: s),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    BarChartSeries bottom,
    BarChartSeries top,
    double scale,
  ) {
    final colors = context.colors;
    // Room above the plot for the tooltip badge (one line of 12 sp text + padding + gap).
    final topInset = 12 * 1.2 * scale + 10 + 8;
    final height = topInset + widget.plotHeight;

    if (widget.failed) {
      return SizedBox(
        height: height,
        child: _DashedPanel(
          text: widget.failedText,
          textColor: colors.destructive,
        ),
      );
    }
    if (widget.loading) {
      return SizedBox(
        height: height,
        child: _BarSkeleton(topInset: topInset),
      );
    }
    if (widget.data.isEmpty) {
      return SizedBox(
        height: height,
        child: _DashedPanel(
          text: widget.emptyText,
          textColor: colors.mutedForeground,
        ),
      );
    }

    final count = widget.data.length;
    final selected = (_selected >= 0 && _selected < count) ? _selected : -1;
    final format = widget.yLabel ?? _defaultYLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: BarChartCard.axisWidth,
                child: ExcludeSemantics(
                  child: _YAxis(
                    topInset: topInset,
                    plotHeight: widget.plotHeight,
                    ticks: widget.yTicks,
                    max: widget.max,
                    format: format,
                  ),
                ),
              ),
              const SizedBox(width: BarChartCard.axisGap),
              Expanded(
                child: _Plot(
                  data: widget.data,
                  max: widget.max,
                  topInset: topInset,
                  plotHeight: widget.plotHeight,
                  ticks: widget.yTicks,
                  selected: selected,
                  progress: _progress,
                  bottomColor: bottom.color,
                  topColor: top.color,
                  tooltipFor: _tooltipFor,
                  onTap: _select,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(
            left: BarChartCard.axisWidth + BarChartCard.axisGap,
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: SynkText(
                      widget.data[i].xLabel,
                      variant: SynkTextVariant.caption,
                      color: i == selected
                          ? colors.foreground
                          : colors.mutedForeground,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        letterSpacing: 0,
                        fontWeight: i == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Plot extends StatelessWidget {
  const _Plot({
    required this.data,
    required this.max,
    required this.topInset,
    required this.plotHeight,
    required this.ticks,
    required this.selected,
    required this.progress,
    required this.bottomColor,
    required this.topColor,
    required this.tooltipFor,
    required this.onTap,
  });

  final List<BarChartDatum> data;
  final double max;
  final double topInset;
  final double plotHeight;
  final int ticks;
  final int selected;
  final Animation<double> progress;
  final Color bottomColor;
  final Color topColor;
  final String Function(BarChartDatum) tooltipFor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = data.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              key: const ValueKey<String>('bar-chart-plot'),
              painter: BarChartPainter(
                data: data,
                max: max,
                topInset: topInset,
                plotHeight: plotHeight,
                ticks: ticks,
                progress: progress,
                bottomColor: bottomColor,
                topColor: topColor,
                cardColor: colors.card,
                gridColor: colors.border,
                hatchColor: colors.foreground.withValues(alpha: 0.16),
                ghostOutline: colors.foreground.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
        // One tap target (and one semantics node) per bar.
        Positioned.fill(
          child: Row(
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  // Seven bars on a phone are 43 dp wide: the node spans 48 (the bars overlap
                  // by a couple of dp; the touch area is the whole column anyway).
                  child: TapTarget(
                    container: true,
                    excludeSemantics: true,
                    properties: SemanticsProperties(
                      button: true,
                      selected: i == selected,
                      label: '${data[i].xLabel}, ${tooltipFor(data[i])}',
                      onTap: () => onTap(i),
                    ),
                    child: GestureDetector(
                      key: ValueKey<String>('bar-chart-bar-$i'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (selected >= 0)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) {
                  final segments = BarChartSegments.of(data[selected], max);
                  return CustomSingleChildLayout(
                    delegate: _TooltipLayout(
                      centerFraction: (selected + 0.5) / count,
                      barTop:
                          topInset +
                          plotHeight * (1 - segments.fraction * progress.value),
                    ),
                    child: Opacity(
                      opacity: progress.value.clamp(0.0, 1.0),
                      child: _TooltipBadge(text: tooltipFor(data[selected])),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Places the badge centred over a bar, its bottom [gap] above the bar top, kept inside the plot.
class _TooltipLayout extends SingleChildLayoutDelegate {
  const _TooltipLayout({required this.centerFraction, required this.barTop});

  final double centerFraction;
  final double barTop;

  static const double gap = 6;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (size.width * centerFraction - childSize.width / 2).clamp(
      0.0,
      math.max(0.0, size.width - childSize.width),
    );
    final y = math.max(0.0, barTop - gap - childSize.height);
    return Offset(x.toDouble(), y);
  }

  @override
  bool shouldRelayout(_TooltipLayout oldDelegate) =>
      oldDelegate.centerFraction != centerFraction ||
      oldDelegate.barTop != barTop;
}

class _TooltipBadge extends StatelessWidget {
  const _TooltipBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      key: const ValueKey<String>('bar-chart-tooltip'),
      decoration: BoxDecoration(
        color: colors.tooltip,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: SynkText(
          text,
          variant: SynkTextVariant.badge,
          color: colors.tooltipForeground,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _YAxis extends StatelessWidget {
  const _YAxis({
    required this.topInset,
    required this.plotHeight,
    required this.ticks,
    required this.max,
    required this.format,
  });

  final double topInset;
  final double plotHeight;
  final int ticks;
  final double max;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    const labelHeight = 14.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 1; i <= ticks; i++)
          Positioned(
            left: 0,
            right: 0,
            top: topInset + plotHeight * (1 - i / ticks) - labelHeight / 2,
            height: labelHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: SynkText(
                format(max * i / ticks),
                variant: SynkTextVariant.caption,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.series});

  final BarChartSeries series;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: SynkRadius.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: series.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: SynkText(
                series.label,
                variant: SynkTextVariant.caption,
                color: colors.foreground,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedPanel extends StatelessWidget {
  const _DashedPanel({required this.text, required this.textColor});

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: CustomPaint(
        painter: _DashedPanelPainter(color: context.colors.border),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SynkText(
              text,
              variant: SynkTextVariant.caption,
              color: textColor,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPanelPainter extends CustomPainter {
  const _DashedPanelPainter({required this.color});

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
      const Radius.circular(16),
    );
    final dashed = Path();
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        dashed.addPath(metric.extractPath(d, d + 4), Offset.zero);
        d += 8;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_DashedPanelPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Loading placeholder: muted pills at the profile skeleton heights.
class _BarSkeleton extends StatelessWidget {
  const _BarSkeleton({required this.topInset});

  final double topInset;

  static const List<double> _fractions = <double>[
    0.38,
    0.62,
    0.44,
    0.78,
    0.52,
    0.34,
    0.58,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      label: 'Loading chart',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final f in _fractions)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: FractionallySizedBox(
                    heightFactor: f,
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: BarChartMetrics.maxBarWidth,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: SynkRadius.fullAll,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paints dotted gridlines, hatched ghost bars and the rounded stacked segments at the growth
/// [progress] (0 = nothing filled yet, 1 = final).
class BarChartPainter extends CustomPainter {
  BarChartPainter({
    required this.data,
    required this.max,
    required this.topInset,
    required this.plotHeight,
    required this.ticks,
    required this.progress,
    required this.bottomColor,
    required this.topColor,
    required this.cardColor,
    required this.gridColor,
    required this.hatchColor,
    required this.ghostOutline,
  }) : super(repaint: progress);

  final List<BarChartDatum> data;
  final double max;
  final double topInset;
  final double plotHeight;
  final int ticks;
  final Animation<double> progress;
  final Color bottomColor;
  final Color topColor;
  final Color cardColor;
  final Color gridColor;
  final Color hatchColor;
  final Color ghostOutline;

  /// Gap between the two stacked segments.
  static const double segmentGap = 2;

  /// Distance between hatch lines measured along the x-axis.
  static const double hatchSpacing = 6;

  Path? _hatch;
  double? _hatchWidth;

  /// Bottom segment rect for [datum] at growth [t] in a bar at [left] with [width].
  static Rect bottomRect({
    required BarChartSegments segments,
    required double left,
    required double width,
    required double topInset,
    required double plotHeight,
    required double t,
  }) {
    final baseY = topInset + plotHeight;
    final h = segments.bottom / segments.max * plotHeight * t;
    return Rect.fromLTWH(left, baseY - h, width, h);
  }

  /// Top segment rect (after the gap) for [datum] at growth [t].
  static Rect topRect({
    required BarChartSegments segments,
    required double left,
    required double width,
    required double topInset,
    required double plotHeight,
    required double t,
  }) {
    final baseY = topInset + plotHeight;
    final bottomH = segments.bottom / segments.max * plotHeight * t;
    final topH = segments.top / segments.max * plotHeight * t;
    final gap = (bottomH > 0 && topH > segmentGap) ? segmentGap : 0.0;
    final h = math.max(0.0, topH - gap);
    return Rect.fromLTWH(left, baseY - bottomH - gap - h, width, h);
  }

  Path _hatchFor(double width) {
    if (_hatch != null && _hatchWidth == width) return _hatch!;
    final path = Path();
    // 45 degree lines running up and to the right across a width x plotHeight cell.
    for (var k = -plotHeight; k < width; k += hatchSpacing) {
      path
        ..moveTo(k, topInset + plotHeight)
        ..lineTo(k + plotHeight, topInset);
    }
    _hatchWidth = width;
    return _hatch = path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.isEmpty) return;
    final t = progress.value.clamp(0.0, 1.0);
    final metrics = BarChartMetrics(width: size.width, count: data.length);
    final barW = metrics.barWidth;

    _paintGrid(canvas, size);

    final fill = Paint()..isAntiAlias = true;
    final hatchPaint = Paint()
      ..color = hatchColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;
    final outlinePaint = Paint()
      ..color = ghostOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;

    final plotTop = topInset;
    for (var i = 0; i < data.length; i++) {
      final segments = BarChartSegments.of(data[i], max);
      final left = metrics.left(i);

      final bottom = bottomRect(
        segments: segments,
        left: left,
        width: barW,
        topInset: topInset,
        plotHeight: plotHeight,
        t: t,
      );
      final top = topRect(
        segments: segments,
        left: left,
        width: barW,
        topInset: topInset,
        plotHeight: plotHeight,
        t: t,
      );

      // Ghost: everything above the filled stack, up to the plot top.
      final stackTop = top.height > 0
          ? top.top
          : (bottom.height > 0 ? bottom.top : topInset + plotHeight);
      final filledAny = bottom.height > 0 || top.height > 0;
      final ghostBottom = stackTop - (filledAny ? segmentGap : 0);
      final ghostH = ghostBottom - plotTop;
      if (ghostH > 2) {
        final ghost = RRect.fromRectAndRadius(
          Rect.fromLTRB(left, plotTop, left + barW, ghostBottom),
          Radius.circular(math.min(barW / 2, ghostH / 2)),
        );
        fill.color = cardColor;
        canvas
          ..drawRRect(ghost, fill)
          ..save()
          ..clipRRect(ghost)
          ..translate(left, 0)
          ..drawPath(_hatchFor(barW), hatchPaint)
          ..restore()
          ..drawRRect(ghost.deflate(0.5), outlinePaint);
      }

      if (bottom.height > 0) {
        fill.color = bottomColor;
        canvas.drawRRect(_pill(bottom), fill);
      }
      if (top.height > 0) {
        fill.color = topColor;
        canvas.drawRRect(_pill(top), fill);
      }
    }
  }

  static RRect _pill(Rect r) => RRect.fromRectAndRadius(
    r,
    Radius.circular(math.min(r.width / 2, r.height / 2)),
  );

  void _paintGrid(Canvas canvas, Size size) {
    final points = <double>[];
    for (var i = 1; i <= ticks; i++) {
      final y = topInset + plotHeight * (1 - i / ticks);
      for (var x = 1.0; x < size.width; x += 5) {
        points
          ..add(x)
          ..add(y);
      }
    }
    canvas.drawRawPoints(
      ui.PointMode.points,
      Float32List.fromList(points),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) =>
      oldDelegate.max != max ||
      oldDelegate.topInset != topInset ||
      oldDelegate.plotHeight != plotHeight ||
      oldDelegate.ticks != ticks ||
      oldDelegate.progress != progress ||
      oldDelegate.bottomColor != bottomColor ||
      oldDelegate.topColor != topColor ||
      oldDelegate.cardColor != cardColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.hatchColor != hatchColor ||
      oldDelegate.ghostOutline != ghostOutline ||
      !_sameData(oldDelegate.data, data);

  static bool _sameData(List<BarChartDatum> a, List<BarChartDatum> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
