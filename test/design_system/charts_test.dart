import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/bar_chart_card.dart';
import 'package:date_js/design_system/components/synk_text.dart';
import 'package:date_js/design_system/components/watch_trend_chart.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_theme.dart';
import 'package:date_js/design_system/tokens/synk_typography.dart';

import '../support/synk_test_harness.dart';

/// Re-enables animations inside [synkApp] (the harness disables them for deterministic goldens).
Widget _animated(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: false),
    child: child,
  ),
);

/// Mounts the widget built from [state] once, so tests can change it without rebuilding the app.
Widget _driven<T>(
  ValueNotifier<T> state,
  Widget Function(T value) builder, {
  bool animations = false,
}) {
  final tree = ValueListenableBuilder<T>(
    valueListenable: state,
    builder: (context, value, _) => builder(value),
  );
  return synkApp(animations ? _animated(tree) : tree);
}

/// The profile "Last 7 days" setting: the chart on a card.
Widget _card(Widget child) => Builder(
  builder: (context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  },
);

const _week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// Seconds of watch time per weekday.
const _typical = <double>[1800, 3600, 900, 5400, 2700, 7200, 4500];

/// The reference data: 4 bars, 27-30 Jun.
const _reference = <BarChartDatum>[
  BarChartDatum(xLabel: '27 Jun', bottom: 0.38, top: 0.30),
  BarChartDatum(xLabel: '28 Jun', bottom: 0.30, top: 0.42),
  BarChartDatum(xLabel: '29 Jun', bottom: 0.52, top: 0.35),
  BarChartDatum(xLabel: '30 Jun', bottom: 0.22, top: 0.28),
];

List<BarChartSeries> _series(SynkColors c) => [
  BarChartSeries(label: 'Watching', color: c.blueGrey),
  BarChartSeries(label: 'Chatting', color: c.chartPink),
];

Widget _yearChip() => Builder(
  builder: (context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SynkText('2024', variant: SynkTextVariant.small),
            const SizedBox(width: 4),
            SynkIcon(SynkIcons.down, size: 14, color: colors.mutedForeground),
          ],
        ),
      ),
    );
  },
);

/// A bar chart card reading its series colours from the active theme.
Widget _barCard({
  List<BarChartDatum> data = _reference,
  int selected = -1,
  ValueChanged<int>? onSelected,
  String title = 'Statistics',
  Widget? trailing,
  bool loading = false,
  bool failed = false,
  String Function(BarChartDatum)? tooltipText,
  double max = 1.0,
}) => Builder(
  builder: (context) => BarChartCard(
    title: title,
    data: data,
    series: _series(context.colors),
    selectedIndex: selected,
    onSelected: onSelected,
    trailing: trailing,
    loading: loading,
    failed: failed,
    tooltipText: tooltipText,
    max: max,
  ),
);

void main() {
  group('watchAxisLabel', () {
    test('formats minutes, whole hours and hours with minutes', () {
      expect(watchAxisLabel(0), '0m');
      expect(watchAxisLabel(59), '1m');
      expect(watchAxisLabel(1800), '30m');
      expect(watchAxisLabel(3540), '59m');
      expect(watchAxisLabel(3600), '1h');
      expect(watchAxisLabel(5400), '1h30');
      expect(watchAxisLabel(7200), '2h');
      expect(watchAxisLabel(4500), '1h15');
    });

    test('drops fractions of a second and survives garbage', () {
      expect(watchAxisLabel(4500.9), '1h15');
      expect(watchAxisLabel(double.nan), '0m');
      expect(watchAxisLabel(double.infinity), '0m');
    });
  });

  group('WatchTrendGeometry', () {
    test(
      'points follow y = padTop + innerH - (v / max) * innerH, evenly spaced',
      () {
        // 700 x 200 view box: inner width 692, inner height 184.
        final points = WatchTrendGeometry.points(const [
          0,
          5,
          10,
        ], const Size(700, 200));
        expect(points, hasLength(3));
        expect(points[0].dx, 4);
        expect(points[0].dy, 192); // 8 + 184 - 0
        expect(points[1].dx, 350); // 4 + 692 / 2
        expect(points[1].dy, 100); // 8 + 184 - 92
        expect(points[2].dx, 696); // 4 + 692
        expect(points[2].dy, 8); // 8 + 184 - 184
      },
    );

    test('the view box stretches to the canvas on both axes', () {
      final points = WatchTrendGeometry.points(const [
        0,
        5,
        10,
      ], const Size(350, 100));
      expect(points[0], const Offset(2, 96));
      expect(points[1], const Offset(175, 50));
      expect(points[2], const Offset(348, 4));
    });

    test('flat data sits on the top line; zero values on the baseline', () {
      final flat = WatchTrendGeometry.points(const [
        3,
        3,
        3,
      ], const Size(700, 200));
      expect(flat.map((p) => p.dy), [8, 8, 8]);
      final zero = WatchTrendGeometry.points(const [
        0,
        4,
      ], const Size(700, 200));
      expect(zero[0].dy, WatchTrendGeometry.baselineY(const Size(700, 200)));
    });

    test(
      'negative and non-finite values count as 0, and never leave the plot',
      () {
        expect(
          WatchTrendGeometry.sanitize(const [
            -1,
            double.nan,
            3,
            double.infinity,
          ]),
          [0, 0, 3, 0],
        );
        final points = WatchTrendGeometry.points(const [
          -5,
          10,
          double.nan,
        ], const Size(700, 200));
        for (final p in points) {
          expect(p.dy, inInclusiveRange(8, 192));
        }
        expect(WatchTrendGeometry.maxOf(const [-5, 10, 2]), 10);
        expect(WatchTrendGeometry.maxOf(const []), 0);
      },
    );

    test('baseline and gridlines at 25 / 50 / 75 % of the inner height', () {
      const size = Size(700, 200);
      expect(WatchTrendGeometry.baselineY(size), 192);
      expect(WatchTrendGeometry.gridY(size, 0.25), 54);
      expect(WatchTrendGeometry.gridY(size, 0.5), 100);
      expect(WatchTrendGeometry.gridY(size, 0.75), 146);
      expect(WatchTrendGeometry.gridFractions, [0.25, 0.5, 0.75]);
    });

    test(
      'the smoothed line never overshoots the data (flat control tangents)',
      () {
        final points = WatchTrendGeometry.points(const [
          0,
          10,
          0,
          10,
        ], const Size(700, 200));
        final bounds = WatchTrendGeometry.linePath(points).getBounds();
        expect(bounds.top, closeTo(8, 1e-6));
        expect(bounds.bottom, closeTo(192, 1e-6));
        expect(bounds.left, closeTo(4, 1e-6));
        expect(bounds.right, closeTo(696, 1e-6));
      },
    );

    test('control points sit at the horizontal midpoint of each pair', () {
      final path = WatchTrendGeometry.linePath(const [
        Offset(0, 100),
        Offset(100, 20),
      ]);
      // Halfway along x the cubic is halfway in y (symmetric S-curve).
      final metric = path.computeMetrics().single;
      final mid = metric.getTangentForOffset(metric.length / 2)!.position;
      expect(mid.dx, closeTo(50, 0.5));
      expect(mid.dy, closeTo(60, 0.5));
    });

    test('a single point yields a single point', () {
      expect(
        WatchTrendGeometry.points(const [5], const Size(700, 200)),
        hasLength(1),
      );
      expect(
        WatchTrendGeometry.points(const [], const Size(700, 200)),
        isEmpty,
      );
    });
  });

  group('WatchTrendChart', () {
    testWidgets('loading shows seven skeleton bars at the spec heights', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          const WatchTrendChart(labels: _week),
          brightness: Brightness.dark,
        ),
      );
      final heights = tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .map((b) => b.heightFactor)
          .toList();
      expect(heights, [0.38, 0.62, 0.44, 0.78, 0.52, 0.34, 0.58]);
      expect(WatchTrendChart.skeletonFractions, heights);
      final bars = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((b) => b.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color == SynkColors.dark.muted);
      expect(bars, hasLength(7));
      for (final bar in bars) {
        // Top radius 4, flat bottom.
        expect(
          bar.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(4)),
        );
      }
      // No labels while loading, even when supplied.
      expect(find.text('Mon'), findsNothing);
      expect(
        tester.getSize(find.byType(WatchTrendChart)).height,
        WatchTrendChart.chartHeight,
      );
    });

    testWidgets('empty (sum <= 0) shows the dashed box with the empty text', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          const WatchTrendChart(values: [0, 0, 0, 0, 0, 0, 0], labels: _week),
        ),
      );
      expect(find.text('No watch time in the last 7 days'), findsOneWidget);
      // Weekday labels still show below the empty box (RN parity).
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      // No y-axis in the empty state.
      expect(find.text('0m'), findsNothing);
    });

    testWidgets('negative-only data counts as empty; custom empty text', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          const WatchTrendChart(
            values: [-3, double.nan],
            emptyText: 'Nothing yet',
          ),
        ),
      );
      expect(find.text('Nothing yet'), findsOneWidget);
    });

    testWidgets('failed without data shows a destructive "Could not load"', (
      tester,
    ) async {
      await tester.pumpWidget(synkApp(const WatchTrendChart(failed: true)));
      final text = tester.widget<Text>(find.text('Could not load'));
      expect(text.style!.color, SynkColors.light.destructive);
      expect(
        find.byType(FractionallySizedBox),
        findsNothing,
        reason: 'no skeleton',
      );
    });

    testWidgets('failed with stale data keeps the chart and flags it', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          const WatchTrendChart(values: _typical, labels: _week, failed: true),
        ),
      );
      expect(find.text('Could not load'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget, reason: 'axis max (7200 s)');
    });

    testWidgets(
      'data shows axis labels max, max/2 and 0m plus the weekday row',
      (tester) async {
        useGoldenViewport(tester, size: const Size(400, 800));
        await tester.pumpWidget(
          synkApp(
            const Align(
              alignment: Alignment.topLeft,
              child: WatchTrendChart(values: _typical, labels: _week),
            ),
          ),
        );
        expect(find.text('2h'), findsOneWidget); // 7200 s
        expect(find.text('1h'), findsOneWidget); // 3600 s
        expect(find.text('0m'), findsOneWidget);
        for (final day in _week) {
          expect(find.text(day), findsOneWidget);
        }
        // Weekday cells are inset by the 40 dp gutter on the left and 4 dp on the right.
        final first = tester.getCenter(find.text('Mon')).dx;
        final last = tester.getCenter(find.text('Sun')).dx;
        const cell = (400 - WatchTrendChart.gutter - 4) / 7;
        expect(first, closeTo(WatchTrendChart.gutter + cell / 2, 0.5));
        expect(last, closeTo(WatchTrendChart.gutter + cell * 6.5, 0.5));
        // Plot 160 + 6 gap + label row.
        expect(
          tester.getSize(find.byType(WatchTrendChart)).height,
          greaterThan(WatchTrendChart.chartHeight + 6),
        );
      },
    );

    testWidgets('a custom axis formatter is used for all three labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          WatchTrendChart(
            values: const [2, 4, 10],
            axisLabel: (v) => '${v.toStringAsFixed(0)} pts',
          ),
        ),
      );
      expect(find.text('10 pts'), findsOneWidget);
      expect(find.text('5 pts'), findsOneWidget);
      expect(find.text('0 pts'), findsOneWidget);
    });

    testWidgets('paints with the accent colour and the primary by default', (
      tester,
    ) async {
      const accent = Color(0xFF6366F1);
      await tester.pumpWidget(
        synkApp(const WatchTrendChart(values: _typical, accent: accent)),
      );
      WatchTrendPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(WatchTrendChart),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as WatchTrendPainter;
      expect(painter().accent, accent);
      expect(painter().gridColor, SynkColors.light.border);
      await tester.pumpWidget(synkApp(const WatchTrendChart(values: _typical)));
      expect(painter().accent, SynkColors.light.primary);
    });

    testWidgets('renders flat, single-point and spiky data without errors', (
      tester,
    ) async {
      for (final values in <List<double>>[
        const [5, 5, 5, 5, 5, 5, 5],
        const [3],
        const [0, 0, 9000, 0, 0, 0, 0],
        const [0, 1, 0, 1, 0, 1, 0],
      ]) {
        await tester.pumpWidget(synkApp(WatchTrendChart(values: values)));
        expect(tester.takeException(), isNull, reason: '$values');
      }
    });

    testWidgets('exposes one semantics node summarising the data', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(const WatchTrendChart(values: _typical, labels: _week)),
      );
      expect(
        find.bySemanticsLabel(
          'Watch time: Mon 30m, Tue 1h, Wed 15m, Thu 1h30, Fri 45m, Sat 2h, Sun 1h15',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(synkApp(const WatchTrendChart()));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      await tester.pumpWidget(synkApp(const WatchTrendChart(values: [0, 0])));
      expect(
        find.bySemanticsLabel('No watch time in the last 7 days'),
        findsOneWidget,
      );
      handle.dispose();
    });

    test('painter repaints when the data or colours change', () {
      final base = WatchTrendPainter(
        values: const [1, 2, 3],
        accent: Colors.pink,
        gridColor: Colors.grey,
      );
      expect(
        base.shouldRepaint(
          WatchTrendPainter(
            values: const [1, 2, 3],
            accent: Colors.pink,
            gridColor: Colors.grey,
          ),
        ),
        isFalse,
      );
      expect(
        base.shouldRepaint(
          WatchTrendPainter(
            values: const [1, 2, 4],
            accent: Colors.pink,
            gridColor: Colors.grey,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          WatchTrendPainter(
            values: const [1, 2, 3],
            accent: Colors.blue,
            gridColor: Colors.grey,
          ),
        ),
        isTrue,
      );
    });

    testWidgets('the line and area really are drawn in the accent colour', (
      tester,
    ) async {
      useGoldenViewport(tester, size: const Size(240, 200));
      final key = GlobalKey();
      await tester.pumpWidget(
        synkApp(
          Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: const SizedBox(
                width: 240,
                height: 160,
                child: WatchTrendChart(
                  values: [10, 10, 10],
                  accent: Color(0xFF00FF00),
                ),
              ),
            ),
          ),
        ),
      );
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData();
        image.dispose();
        return data!;
      });
      // Flat data: the line is at the top of the plot (y = 8/200 * 160 = 6.4) and the area fills
      // below it. Sample the middle of the plot (x = 40 + 100) well below the line.
      int green(int x, int y) => bytes!.getUint8((y * 240 + x) * 4 + 1);
      int red(int x, int y) => bytes!.getUint8((y * 240 + x) * 4);
      // The area fill is a green tint over the card/background (red channel dropped).
      expect(green(140, 100), greaterThan(red(140, 100)));
      // Above the line (y = 1) there is only the background.
      expect(green(140, 1), red(140, 1));
    });
  });

  group('BarChartSegments / BarChartMetrics', () {
    test('stacked segments and the remaining ghost', () {
      final s = BarChartSegments.of(
        const BarChartDatum(xLabel: 'a', bottom: 0.4, top: 0.3),
        1,
      );
      expect(s.bottom, 0.4);
      expect(s.top, 0.3);
      expect(s.rest, closeTo(0.3, 1e-12));
      expect(s.filled, closeTo(0.7, 1e-12));
      expect(s.percent, 70);
    });

    test('the default tooltip is the filled share of max, rounded', () {
      expect(
        BarChartSegments.of(
          const BarChartDatum(xLabel: 'a', bottom: 0.5, top: 0.37),
          1,
        ).percent,
        87,
      );
      expect(
        BarChartSegments.of(
          const BarChartDatum(xLabel: 'a', bottom: 1, top: 0.5),
          2,
        ).percent,
        75,
        reason: 'scales with max',
      );
      expect(
        BarChartSegments.of(
          const BarChartDatum(xLabel: 'a', bottom: 0, top: 0),
          1,
        ).percent,
        0,
      );
    });

    test('values are clamped into [0, max] and stacked within it', () {
      final over = BarChartSegments.of(
        const BarChartDatum(xLabel: 'a', bottom: 0.8, top: 0.5),
        1,
      );
      expect(over.bottom, 0.8);
      expect(
        over.top,
        closeTo(0.2, 1e-12),
        reason: 'top is capped by what is left',
      );
      expect(over.rest, closeTo(0, 1e-12));

      final huge = BarChartSegments.of(
        const BarChartDatum(xLabel: 'a', bottom: 1.5, top: 0.2),
        1,
      );
      expect(huge.bottom, 1);
      expect(huge.top, 0);
      expect(huge.percent, 100);

      final junk = BarChartSegments.of(
        const BarChartDatum(xLabel: 'a', bottom: -2, top: double.nan),
        1,
      );
      expect(junk.bottom, 0);
      expect(junk.top, 0);
      expect(junk.rest, 1);
    });

    test('a non-positive max counts as 1', () {
      final s = BarChartSegments.of(
        const BarChartDatum(xLabel: 'a', bottom: 0.2, top: 0.2),
        0,
      );
      expect(s.max, 1);
      expect(s.percent, 40);
    });

    test('bar slots: equal slots, 62% wide up to 44, centred', () {
      const m = BarChartMetrics(width: 280, count: 4);
      expect(m.slot, 70);
      expect(m.barWidth, closeTo(43.4, 1e-9));
      expect(m.centerX(0), 35);
      expect(m.centerX(3), 245);
      expect(m.left(0), closeTo(35 - 21.7, 1e-9));
      const wide = BarChartMetrics(width: 300, count: 1);
      expect(wide.barWidth, BarChartMetrics.maxBarWidth);
      const dense = BarChartMetrics(width: 280, count: 14);
      expect(dense.barWidth, closeTo(20 * 0.62, 1e-9));
    });

    test('indexAt maps a touch x to a bar slot', () {
      const m = BarChartMetrics(width: 280, count: 4);
      expect(m.indexAt(0), 0);
      expect(m.indexAt(69.9), 0);
      expect(m.indexAt(70), 1);
      expect(m.indexAt(280), 3);
      expect(m.indexAt(-1), -1);
      expect(m.indexAt(281), -1);
      expect(const BarChartMetrics(width: 100, count: 0).indexAt(10), -1);
    });

    test('segment rects: bottom from the baseline, top after a 2 px gap', () {
      const segments = BarChartSegments(
        bottom: 0.4,
        top: 0.3,
        rest: 0.3,
        max: 1,
      );
      // topInset 30, plot 160 -> baseline y = 190.
      final bottom = BarChartPainter.bottomRect(
        segments: segments,
        left: 10,
        width: 40,
        topInset: 30,
        plotHeight: 160,
        t: 1,
      );
      expect(bottom.height, 64);
      expect(bottom.bottom, 190);
      final top = BarChartPainter.topRect(
        segments: segments,
        left: 10,
        width: 40,
        topInset: 30,
        plotHeight: 160,
        t: 1,
      );
      // The stack tops out at 0.7 * 160 = 112 above the baseline, gap included.
      expect(top.top, closeTo(190 - 112, 1e-9));
      expect(top.bottom, closeTo(190 - 64 - BarChartPainter.segmentGap, 1e-9));
      // Half grown.
      final half = BarChartPainter.bottomRect(
        segments: segments,
        left: 10,
        width: 40,
        topInset: 30,
        plotHeight: 160,
        t: 0.5,
      );
      expect(half.height, 32);
      final zero = BarChartPainter.topRect(
        segments: segments,
        left: 10,
        width: 40,
        topInset: 30,
        plotHeight: 160,
        t: 0,
      );
      expect(zero.height, 0);
    });

    test('a bar with only one segment has no gap', () {
      const segments = BarChartSegments(bottom: 0, top: 0.5, rest: 0.5, max: 1);
      final top = BarChartPainter.topRect(
        segments: segments,
        left: 0,
        width: 40,
        topInset: 0,
        plotHeight: 100,
        t: 1,
      );
      expect(top.height, 50);
      expect(top.bottom, 100);
    });
  });

  group('BarChartCard', () {
    testWidgets(
      'shows title, trailing, y ticks 0.1..1.0, x labels and legend',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            SingleChildScrollView(
              child: _barCard(trailing: _yearChip(), selected: 2),
            ),
          ),
        );
        expect(find.text('Statistics'), findsOneWidget);
        expect(find.text('2024'), findsOneWidget);
        for (var i = 1; i <= 10; i++) {
          expect(
            find.text((i / 10).toStringAsFixed(1)),
            findsOneWidget,
            reason: '$i',
          );
        }
        for (final label in ['27 Jun', '28 Jun', '29 Jun', '30 Jun']) {
          expect(find.text(label), findsOneWidget);
        }
        expect(find.text('Watching'), findsOneWidget);
        expect(find.text('Chatting'), findsOneWidget);
        // One coloured dot per series.
        final dots = tester
            .widgetList<Container>(find.byType(Container))
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.shape == BoxShape.circle)
            .map((d) => d.color)
            .toList();
        expect(
          dots,
          containsAll([SynkColors.light.blueGrey, SynkColors.light.chartPink]),
        );
      },
    );

    testWidgets('y ticks follow max, ticks and a custom formatter', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          SingleChildScrollView(
            child: BarChartCard(
              title: 'Hours',
              data: const [BarChartDatum(xLabel: 'Mon', bottom: 20, top: 30)],
              series: _series(SynkColors.light),
              max: 100,
              yTicks: 5,
            ),
          ),
        ),
      );
      for (final label in ['20', '40', '60', '80', '100']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.pumpWidget(
        synkApp(
          SingleChildScrollView(
            child: BarChartCard(
              title: 'Hours',
              data: const [BarChartDatum(xLabel: 'Mon', bottom: 20, top: 30)],
              series: _series(SynkColors.light),
              max: 100,
              yTicks: 2,
              yLabel: (v) => '${v.toInt()}%',
            ),
          ),
        ),
      );
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('no tooltip without a selection; the selected bar gets "87%"', (
      tester,
    ) async {
      final selected = ValueNotifier<int>(-1);
      addTearDown(selected.dispose);
      await tester.pumpWidget(
        _driven<int>(
          selected,
          (value) => SingleChildScrollView(child: _barCard(selected: value)),
        ),
      );
      expect(find.byKey(const ValueKey('bar-chart-tooltip')), findsNothing);
      selected.value = 2;
      await tester.pump();
      expect(find.byKey(const ValueKey('bar-chart-tooltip')), findsOneWidget);
      expect(find.text('87%'), findsOneWidget);
      selected.value = 0;
      await tester.pump();
      expect(find.text('68%'), findsOneWidget);
      expect(find.text('87%'), findsNothing);
      selected.value = 99;
      await tester.pump();
      expect(find.byKey(const ValueKey('bar-chart-tooltip')), findsNothing);
    });

    testWidgets('tooltip is a dark rounded badge centred over its bar', (
      tester,
    ) async {
      useGoldenViewport(tester, size: const Size(400, 800));
      await tester.pumpWidget(
        synkApp(SingleChildScrollView(child: _barCard(selected: 1))),
      );
      final badge = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('bar-chart-tooltip')),
      );
      final decoration = badge.decoration as BoxDecoration;
      expect(decoration.color, SynkColors.light.tooltip);
      expect(decoration.borderRadius, isNotNull);
      final text = tester.widget<Text>(find.text('72%'));
      expect(text.style!.color, SynkColors.light.tooltipForeground);

      // Centred over the second of four equal slots.
      final tap = tester.getCenter(
        find.byKey(const ValueKey('bar-chart-bar-1')),
      );
      expect(
        tester.getCenter(find.byKey(const ValueKey('bar-chart-tooltip'))).dx,
        closeTo(tap.dx, 0.5),
      );
      // Above the bar top of 72 %, i.e. in the upper part of the plot.
      final plot = tester.getRect(find.byKey(const ValueKey('bar-chart-plot')));
      expect(
        tester.getRect(find.byKey(const ValueKey('bar-chart-tooltip'))).bottom,
        lessThan(plot.bottom - plot.height * 0.5),
      );
    });

    testWidgets('the tooltip of the first and last bar stays inside the plot', (
      tester,
    ) async {
      useGoldenViewport(tester, size: const Size(320, 800));
      final data = [
        for (var i = 0; i < 12; i++)
          BarChartDatum(xLabel: 'D$i', bottom: 0.5, top: 0.5),
      ];
      final selected = ValueNotifier<int>(0);
      addTearDown(selected.dispose);
      await tester.pumpWidget(
        _driven<int>(
          selected,
          (value) => SingleChildScrollView(
            child: _barCard(
              data: data,
              selected: value,
              tooltipText: (d) => 'Long tip ${d.xLabel}',
            ),
          ),
        ),
      );
      final plot = tester.getRect(find.byKey(const ValueKey('bar-chart-plot')));
      for (final index in [0, 11]) {
        selected.value = index;
        await tester.pump();
        final rect = tester.getRect(
          find.byKey(const ValueKey('bar-chart-tooltip')),
        );
        expect(
          rect.left,
          greaterThanOrEqualTo(plot.left - 0.01),
          reason: 'bar $index',
        );
        expect(
          rect.right,
          lessThanOrEqualTo(plot.right + 0.01),
          reason: 'bar $index',
        );
        expect(
          rect.top,
          greaterThanOrEqualTo(plot.top - 0.01),
          reason: 'bar $index',
        );
      }
    });

    testWidgets('a custom tooltipText replaces the percentage', (tester) async {
      await tester.pumpWidget(
        synkApp(
          SingleChildScrollView(
            child: _barCard(
              selected: 2,
              tooltipText: (d) =>
                  '${d.xLabel}: ${(d.bottom * 100).round()} min',
            ),
          ),
        ),
      );
      expect(find.text('29 Jun: 52 min'), findsOneWidget);
    });

    testWidgets('tapping a bar selects it, reports it and moves the tooltip', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(
        synkApp(SingleChildScrollView(child: _barCard(onSelected: taps.add))),
      );
      expect(find.byKey(const ValueKey('bar-chart-tooltip')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('bar-chart-bar-3')));
      await tester.pump();
      expect(taps, [3]);
      expect(find.text('50%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bar-chart-bar-0')));
      await tester.pump();
      expect(taps, [3, 0]);
      expect(find.text('68%'), findsOneWidget);
      expect(find.text('50%'), findsNothing);
    });

    testWidgets(
      'a parent changing selectedIndex overrides the internal selection',
      (tester) async {
        final selected = ValueNotifier<int>(-1);
        addTearDown(selected.dispose);
        await tester.pumpWidget(
          _driven<int>(
            selected,
            (value) => SingleChildScrollView(child: _barCard(selected: value)),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('bar-chart-bar-1')));
        await tester.pump();
        expect(find.text('72%'), findsOneWidget);
        selected.value = 3;
        await tester.pump();
        expect(find.text('50%'), findsOneWidget);
        expect(find.text('72%'), findsNothing);
      },
    );

    testWidgets('each bar is a selectable button for accessibility', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(SingleChildScrollView(child: _barCard(selected: 2))),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('29 Jun, 87%'));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
      final other = tester.getSemantics(find.bySemanticsLabel('27 Jun, 68%'));
      expect(other.flagsCollection.isSelected, ui.Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('empty data shows the empty text, no tooltip and no axis', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(SingleChildScrollView(child: _barCard(data: const []))),
      );
      expect(find.text('No data yet'), findsOneWidget);
      expect(find.text('0.1'), findsNothing);
      expect(find.byKey(const ValueKey('bar-chart-plot')), findsNothing);
      // Title and legend remain.
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);
    });

    testWidgets('loading shows a skeleton, failed shows the failure text', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(SingleChildScrollView(child: _barCard(loading: true))),
      );
      expect(find.bySemanticsLabel('Loading chart'), findsOneWidget);
      expect(find.byKey(const ValueKey('bar-chart-plot')), findsNothing);
      await tester.pumpWidget(
        synkApp(SingleChildScrollView(child: _barCard(failed: true))),
      );
      final text = tester.widget<Text>(find.text('Could not load'));
      expect(text.style!.color, SynkColors.light.destructive);
      handle.dispose();
    });

    testWidgets('the card is a white rounded panel with a hairline border', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          SingleChildScrollView(child: _barCard()),
          brightness: Brightness.dark,
        ),
      );
      final panel =
          tester
                  .widgetList<DecoratedBox>(
                    find.descendant(
                      of: find.byType(BarChartCard),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .first
                  .decoration
              as BoxDecoration;
      expect(panel.color, SynkColors.dark.card);
      expect(panel.borderRadius, isNotNull);
      expect(panel.border, isNotNull);
    });

    testWidgets('bars grow from zero on first build', (tester) async {
      await tester.pumpWidget(
        synkApp(_animated(SingleChildScrollView(child: _barCard(selected: 2)))),
      );
      BarChartPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('bar-chart-plot')),
                  )
                  .painter!
              as BarChartPainter;
      expect(painter().progress.value, 0);
      await tester.pump(const Duration(milliseconds: 350));
      expect(painter().progress.value, inExclusiveRange(0.1, 0.99));
      await tester.pump(const Duration(milliseconds: 500));
      expect(painter().progress.value, 1);
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'ticker stopped',
      );
    });

    testWidgets(
      'bars grow again when the data changes, not when only selection does',
      (tester) async {
        final state = ValueNotifier<({List<BarChartDatum> data, int selected})>(
          (data: _reference, selected: -1),
        );
        addTearDown(state.dispose);
        await tester.pumpWidget(
          _driven(
            state,
            (value) => SingleChildScrollView(
              child: _barCard(data: value.data, selected: value.selected),
            ),
            animations: true,
          ),
        );
        BarChartPainter painter() =>
            tester
                    .widget<CustomPaint>(
                      find.byKey(const ValueKey('bar-chart-plot')),
                    )
                    .painter!
                as BarChartPainter;
        await tester.pump(const Duration(milliseconds: 900));
        expect(painter().progress.value, 1);

        state.value = (data: _reference, selected: 1);
        await tester.pump();
        expect(
          painter().progress.value,
          1,
          reason: 'selection does not replay',
        );

        state.value = (
          data: const [
            BarChartDatum(xLabel: '27 Jun', bottom: 0.1, top: 0.1),
            BarChartDatum(xLabel: '28 Jun', bottom: 0.2, top: 0.3),
          ],
          selected: 1,
        );
        await tester.pump();
        expect(
          painter().progress.value,
          lessThan(0.05),
          reason: 'data change replays',
        );
        await tester.pump(const Duration(milliseconds: 900));
        expect(painter().progress.value, 1);
      },
    );

    testWidgets('reduced motion shows the final bars at once', (tester) async {
      await tester.pumpWidget(
        synkApp(SingleChildScrollView(child: _barCard(selected: 2))),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('bar-chart-plot')),
                  )
                  .painter!
              as BarChartPainter;
      expect(painter.progress.value, 1);
    });

    testWidgets('removing the card stops its ticker', (tester) async {
      final shown = ValueNotifier<bool>(true);
      addTearDown(shown.dispose);
      await tester.pumpWidget(
        _driven<bool>(
          shown,
          (show) => show
              ? SingleChildScrollView(child: _barCard(selected: 2))
              : const SizedBox(),
          animations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      shown.value = false;
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets(
      'survives 1.3x text scale with long labels and a long tooltip',
      (tester) async {
        useGoldenViewport(tester, size: const Size(360, 900));
        await tester.pumpWidget(
          synkApp(
            SingleChildScrollView(
              child: _barCard(
                title: 'Weekly statistics for everyone in the group',
                trailing: _yearChip(),
                selected: 1,
                data: const [
                  BarChartDatum(
                    xLabel: 'Wednesday 27 June',
                    bottom: 0.38,
                    top: 0.3,
                  ),
                  BarChartDatum(
                    xLabel: 'Thursday 28 June',
                    bottom: 0.3,
                    top: 0.42,
                  ),
                  BarChartDatum(
                    xLabel: 'Friday 29 June',
                    bottom: 0.52,
                    top: 0.35,
                  ),
                  BarChartDatum(
                    xLabel: 'Saturday 30 June',
                    bottom: 0.22,
                    top: 0.28,
                  ),
                ],
              ),
            ),
            textScale: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('golden sheets', () {
    testWidgets('watch trend chart states', (tester) async {
      await expectStateSheetGolden(
        tester,
        'watch_trend_chart',
        _trendCells().take(5).toList(),
        size: const Size(420, 1200),
        cellWidth: 388,
      );
    });

    testWidgets('watch trend chart data shapes', (tester) async {
      await expectStateSheetGolden(
        tester,
        'watch_trend_chart_shapes',
        _trendCells().skip(5).toList(),
        size: const Size(420, 1160),
        cellWidth: 388,
      );
    });

    testWidgets('watch trend chart at 1.3x text scale', (tester) async {
      await expectStateSheetGolden(
        tester,
        'watch_trend_chart_scaled',
        _trendCells().take(5).toList(),
        size: const Size(420, 1300),
        cellWidth: 388,
        textScale: 1.3,
      );
    });

    testWidgets('bar chart card states', (tester) async {
      await expectStateSheetGolden(
        tester,
        'bar_chart_card',
        _barCells().take(5).toList(),
        size: const Size(420, 2000),
        cellWidth: 388,
      );
    });

    testWidgets('bar chart card edge states', (tester) async {
      await expectStateSheetGolden(
        tester,
        'bar_chart_card_states',
        _barCells().skip(5).toList(),
        size: const Size(420, 1500),
        cellWidth: 388,
      );
    });

    testWidgets('bar chart card at 1.3x text scale', (tester) async {
      await expectStateSheetGolden(
        tester,
        'bar_chart_card_scaled',
        [_barCells()[0], _barCells()[5]],
        size: const Size(420, 880),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });
}

List<GoldenCell> _trendCells() => [
  GoldenCell(
    'data, typical week',
    _card(const WatchTrendChart(values: _typical, labels: _week)),
  ),
  GoldenCell(
    'data, accent colour',
    _card(
      const WatchTrendChart(
        values: _typical,
        labels: _week,
        accent: Color(0xFF6366F1),
      ),
    ),
  ),
  GoldenCell('loading', _card(const WatchTrendChart(labels: _week))),
  GoldenCell(
    'empty',
    _card(const WatchTrendChart(values: [0, 0, 0, 0, 0, 0, 0], labels: _week)),
  ),
  GoldenCell(
    'failed',
    _card(const WatchTrendChart(failed: true, labels: _week)),
  ),
  GoldenCell(
    'failed with stale data',
    _card(const WatchTrendChart(values: _typical, labels: _week, failed: true)),
  ),
  GoldenCell(
    'flat',
    _card(
      const WatchTrendChart(
        values: [3600, 3600, 3600, 3600, 3600, 3600, 3600],
        labels: _week,
      ),
    ),
  ),
  GoldenCell(
    'spiky',
    _card(
      const WatchTrendChart(
        values: [0, 0, 9000, 0, 600, 0, 7800],
        labels: _week,
      ),
    ),
  ),
  GoldenCell(
    'single day',
    _card(
      const WatchTrendChart(values: [0, 0, 0, 0, 0, 0, 4200], labels: _week),
    ),
  ),
];

List<GoldenCell> _barCells() => [
  GoldenCell(
    'reference: 4 bars, 29 Jun selected',
    _barCard(trailing: _yearChip(), selected: 2),
  ),
  GoldenCell('no selection', _barCard(trailing: _yearChip())),
  GoldenCell('first bar selected', _barCard(selected: 0)),
  GoldenCell('last bar selected', _barCard(selected: 3)),
  GoldenCell(
    'seven bars, empty and full',
    _barCard(
      selected: 4,
      data: const [
        BarChartDatum(xLabel: 'Mon', bottom: 0, top: 0),
        BarChartDatum(xLabel: 'Tue', bottom: 0.05, top: 0.04),
        BarChartDatum(xLabel: 'Wed', bottom: 0.3, top: 0.2),
        BarChartDatum(xLabel: 'Thu', bottom: 0.6, top: 0.4),
        BarChartDatum(xLabel: 'Fri', bottom: 0.45, top: 0.5),
        BarChartDatum(xLabel: 'Sat', bottom: 0, top: 0.35),
        BarChartDatum(xLabel: 'Sun', bottom: 0.7, top: 0),
      ],
    ),
  ),
  GoldenCell(
    'long labels and title',
    _barCard(
      title: 'Weekly statistics for everyone in the group',
      trailing: _yearChip(),
      selected: 1,
      data: const [
        BarChartDatum(xLabel: 'Wednesday 27 June', bottom: 0.38, top: 0.3),
        BarChartDatum(xLabel: 'Thursday 28 June', bottom: 0.3, top: 0.42),
        BarChartDatum(xLabel: 'Friday 29 June', bottom: 0.52, top: 0.35),
        BarChartDatum(xLabel: 'Saturday 30 June', bottom: 0.22, top: 0.28),
      ],
    ),
  ),
  GoldenCell('empty data', _barCard(data: const [])),
  GoldenCell('loading', _barCard(loading: true)),
  GoldenCell('failed', _barCard(failed: true)),
];
