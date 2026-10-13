import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/skeleton.dart';
import 'package:date_js/design_system/components/stat_tile.dart';
import 'package:date_js/design_system/components/synk_badge.dart';
import 'package:date_js/design_system/components/synk_progress_bar.dart';
import 'package:date_js/design_system/components/synk_spinner.dart';
import 'package:date_js/design_system/components/usage_meter.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_palette.dart';

import '../support/synk_test_harness.dart';

Widget _top(Widget child) => Align(alignment: Alignment.topLeft, child: child);

/// Re-enables animations inside the harness (which disables them for stable goldens).
Widget _animated(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: false),
    child: child,
  ),
);

UsageMeterPainter _painterOf(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(UsageMeter),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as UsageMeterPainter;
}

List<Invocation> _record(UsageMeterPainter painter, Size size) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, size);
  return [for (final call in canvas.invocations) call.invocation];
}

Iterable<Invocation> _calls(List<Invocation> all, Symbol name) =>
    all.where((call) => call.memberName == name);

UsageMeterPainter _painter({
  double filled = 3,
  int segments = 8,
  double gap = 6,
}) => UsageMeterPainter(
  filled: filled,
  segments: segments,
  gap: gap,
  fillColor: const Color(0xFFA9B6FD),
  dashColor: const Color(0xFF999999),
  strokeWidth: 1,
);

Widget _card({
  double fraction = 0.72,
  SynkTone tone = SynkTone.lavender,
  bool loading = false,
  String title = 'Operations',
  SynkIcons icon = SynkIcons.settings,
  String? valueText,
  String? unitText = '/ 1 000',
  VoidCallback? onTap,
}) => UsageMeterCard(
  title: title,
  icon: icon,
  badgeText: '${(fraction * 100).round()}% Used',
  valueText: valueText ?? '${(fraction * 1000).round()}',
  unitText: unitText,
  fraction: fraction,
  tone: tone,
  loading: loading,
  onTap: onTap,
);

void main() {
  group('Skeleton', () {
    testWidgets('is a flat block in the skeleton colour with radius 4', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          synkApp(
            _top(const Skeleton(width: 120, height: 16)),
            brightness: brightness,
          ),
        );
        final box =
            tester
                    .widget<Container>(
                      find.descendant(
                        of: find.byType(Skeleton),
                        matching: find.byType(Container),
                      ),
                    )
                    .decoration!
                as BoxDecoration;
        expect(box.color, SynkPalette.skeleton);
        expect(box.borderRadius, BorderRadius.circular(4));
        expect(tester.getSize(find.byType(Skeleton)), const Size(120, 16));
      }
    });

    testWidgets('radius is configurable', (tester) async {
      await tester.pumpWidget(
        synkApp(_top(const Skeleton(width: 40, height: 40, radius: 20))),
      );
      final box =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byType(Skeleton),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(box.borderRadius, BorderRadius.circular(20));
    });

    testWidgets('expands to the space its parent offers', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(const SizedBox(width: 200, height: 30, child: Skeleton())),
        ),
      );
      expect(tester.getSize(find.byType(Skeleton)), const Size(200, 30));
    });

    testWidgets('never animates (no shimmer) and is hidden from semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(_top(const Skeleton(width: 120, height: 16))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, 0);
      expect(
        find.descendant(
          of: find.byType(Skeleton),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('SynkSpinner', () {
    CircularProgressIndicator indicator(WidgetTester tester) =>
        tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );

    testWidgets(
      'is 20dp with a 2dp round-capped stroke and transparent track',
      (tester) async {
        await tester.pumpWidget(
          synkApp(_top(const SynkSpinner()), animations: true),
        );
        expect(tester.getSize(find.byType(SynkSpinner)), const Size(20, 20));
        final spinner = indicator(tester);
        expect(spinner.strokeWidth, 2);
        expect(spinner.strokeCap, StrokeCap.round);
        expect(spinner.backgroundColor, Colors.transparent);
        expect(spinner.color, SynkColors.light.primary);
      },
    );

    testWidgets('takes size and colour', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(const SynkSpinner(size: 32, color: Color(0xFF10B981))),
          brightness: Brightness.dark,
          animations: true,
        ),
      );
      expect(tester.getSize(find.byType(SynkSpinner)), const Size(32, 32));
      expect(indicator(tester).color, const Color(0xFF10B981));

      await tester.pumpWidget(
        synkApp(
          _top(const SynkSpinner()),
          brightness: Brightness.dark,
          animations: true,
        ),
      );
      expect(indicator(tester).color, SynkColors.dark.primary);
    });

    testWidgets('spins and can be labelled for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          _top(const SynkSpinner(semanticLabel: 'Loading')),
          animations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(
        tester.getSemantics(find.byType(CircularProgressIndicator)),
        isSemantics(label: 'Loading'),
      );
      handle.dispose();
    });
  });

  group('SynkProgressBar', () {
    Size fillSize(WidgetTester tester) => tester.getSize(
      find.descendant(
        of: find.byType(SynkProgressBar),
        matching: find.byType(FractionallySizedBox),
      ),
    );

    testWidgets('clampProgress limits to 0..1 and treats NaN as 0', (
      tester,
    ) async {
      expect(SynkProgressBar.clampProgress(-1), 0);
      expect(SynkProgressBar.clampProgress(0), 0);
      expect(SynkProgressBar.clampProgress(0.4), 0.4);
      expect(SynkProgressBar.clampProgress(1), 1);
      expect(SynkProgressBar.clampProgress(7), 1);
      expect(SynkProgressBar.clampProgress(double.nan), 0);
      expect(SynkProgressBar.clampProgress(double.infinity), 1);
      expect(SynkProgressBar.clampProgress(double.negativeInfinity), 0);
    });

    testWidgets(
      'fills the matching share of the track and clamps out-of-range',
      (tester) async {
        Future<void> pumpAt(double progress) => tester.pumpWidget(
          synkApp(
            _top(
              SizedBox(width: 200, child: SynkProgressBar(progress: progress)),
            ),
          ),
        );
        await pumpAt(0.25);
        expect(fillSize(tester).width, closeTo(50, 0.01));
        await pumpAt(1);
        expect(fillSize(tester).width, closeTo(200, 0.01));
        await pumpAt(1.5);
        expect(fillSize(tester).width, closeTo(200, 0.01));
        await pumpAt(-0.5);
        expect(fillSize(tester).width, 0);
        await pumpAt(double.nan);
        expect(fillSize(tester).width, 0);
      },
    );

    testWidgets(
      'is 4dp tall by default, fully rounded, muted track, primary fill',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            _top(
              const SizedBox(width: 200, child: SynkProgressBar(progress: 0.5)),
            ),
          ),
        );
        expect(tester.getSize(find.byType(SynkProgressBar)).height, 4);
        final decorations = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(SynkProgressBar),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((box) => box.decoration as BoxDecoration)
            .toList();
        expect(decorations.first.color, SynkColors.light.muted);
        expect(decorations.first.borderRadius, BorderRadius.circular(2));
        expect(decorations.last.color, SynkColors.light.primary);
        expect(decorations.last.borderRadius, BorderRadius.circular(2));
      },
    );

    testWidgets('takes colour and height', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 200,
              child: SynkProgressBar(
                progress: 0.5,
                color: Color(0xFF10B981),
                height: 10,
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(SynkProgressBar)).height, 10);
      final fill =
          tester
                  .widgetList<DecoratedBox>(
                    find.descendant(
                      of: find.byType(SynkProgressBar),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .last
                  .decoration
              as BoxDecoration;
      expect(fill.color, const Color(0xFF10B981));
      expect(fill.borderRadius, BorderRadius.circular(5));
    });

    testWidgets(
      'animates changes over 200 ms and lands exactly on the target',
      (tester) async {
        Future<void> pumpAt(double progress) => tester.pumpWidget(
          synkApp(
            _animated(
              _top(
                SizedBox(
                  width: 200,
                  child: SynkProgressBar(progress: progress),
                ),
              ),
            ),
          ),
        );
        await pumpAt(0);
        await pumpAt(1);
        expect(fillSize(tester).width, 0, reason: 'starts from the old value');
        await tester.pump(const Duration(milliseconds: 100));
        final mid = fillSize(tester).width;
        expect(mid, greaterThan(0));
        expect(mid, lessThan(200));
        await tester.pump(const Duration(milliseconds: 100));
        expect(fillSize(tester).width, closeTo(200, 0.01));
        await tester.pumpAndSettle();
        expect(fillSize(tester).width, 200);

        // And back down again.
        await pumpAt(0.5);
        await tester.pump(const Duration(milliseconds: 100));
        expect(fillSize(tester).width, inExclusiveRange(100, 200));
        await tester.pumpAndSettle();
        expect(fillSize(tester).width, 100);
      },
    );

    testWidgets('jumps instantly when animations are disabled', (tester) async {
      Future<void> pumpAt(double progress) => tester.pumpWidget(
        synkApp(
          _top(
            SizedBox(width: 200, child: SynkProgressBar(progress: progress)),
          ),
        ),
      );
      await pumpAt(0);
      await pumpAt(1);
      expect(fillSize(tester).width, closeTo(200, 0.01));
    });

    testWidgets('exposes the percentage and optional label to screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 200,
              child: SynkProgressBar(progress: 0.724, semanticLabel: 'Upload'),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(SynkProgressBar)),
        isSemantics(label: 'Upload', value: '72%'),
      );
      handle.dispose();
    });

    testWidgets('golden: skeleton, spinner and progress states', (
      tester,
    ) async {
      await expectStateSheetGolden(
        tester,
        'meters_feedback',
        [
          const GoldenCell(
            'Skeleton blocks (flat, no shimmer)',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    Skeleton(width: 44, height: 44, radius: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Skeleton(width: 160, height: 14),
                          Skeleton(width: 100, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
                Skeleton(height: 64, radius: 14),
              ],
            ),
          ),
          for (final value in const [0.0, 0.25, 0.5, 0.72, 1.0])
            GoldenCell(
              'SynkProgressBar ${(value * 100).round()}%',
              SizedBox(width: 388, child: SynkProgressBar(progress: value)),
            ),
          const GoldenCell(
            'custom colour + taller',
            SizedBox(
              width: 388,
              child: SynkProgressBar(
                progress: 0.6,
                color: SynkPalette.success,
                height: 8,
              ),
            ),
          ),
        ],
        size: const Size(420, 480),
        cellWidth: 388,
      );
    });

    testWidgets('golden: spinner mid-rotation', (tester) async {
      // The indeterminate arc is only visible once it is under way; fake time keeps this exact.
      for (final brightness in Brightness.values) {
        useGoldenViewport(tester, size: const Size(420, 130));
        await tester.pumpWidget(
          synkApp(
            const StateSheet(
              cells: [
                GoldenCell('14', SynkSpinner(size: 14)),
                GoldenCell('20 (default)', SynkSpinner()),
                GoldenCell('28', SynkSpinner(size: 28)),
                GoldenCell(
                  'custom colour',
                  SynkSpinner(size: 28, color: SynkPalette.success),
                ),
              ],
              cellWidth: 80,
            ),
            brightness: brightness,
            animations: true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/meters_spinner_${brightness == Brightness.dark ? 'dark' : 'light'}.png',
          ),
        );
      }
    });
  });

  group('UsageMeter', () {
    test('filledSegments rounds and clamps', () {
      expect(UsageMeter.filledSegments(0, 8), 0);
      expect(UsageMeter.filledSegments(0.37, 8), 3);
      expect(UsageMeter.filledSegments(0.72, 8), 6);
      expect(UsageMeter.filledSegments(1, 8), 8);
      expect(UsageMeter.filledSegments(0.5, 8), 4);
      expect(UsageMeter.filledSegments(0.0625, 8), 1, reason: '0.5 rounds up');
      expect(UsageMeter.filledSegments(-3, 8), 0);
      expect(UsageMeter.filledSegments(2.5, 8), 8);
      expect(UsageMeter.filledSegments(double.nan, 8), 0);
      expect(UsageMeter.filledSegments(double.infinity, 8), 8);
      expect(UsageMeter.filledSegments(0.45, 5), 2);
      expect(UsageMeter.filledSegments(0.9, 12), 11);
    });

    testWidgets('takes the full width and the requested height', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _top(const SizedBox(width: 300, child: UsageMeter(fraction: 0.5))),
        ),
      );
      expect(tester.getSize(find.byType(UsageMeter)), const Size(300, 40));
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 300,
              child: UsageMeter(fraction: 0.5, height: 24),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(UsageMeter)).height, 24);
    });

    testWidgets(
      'hands the painter the filled count, segments, gap and tone colour',
      (tester) async {
        for (final brightness in Brightness.values) {
          final colors = brightness == Brightness.dark
              ? SynkColors.dark
              : SynkColors.light;
          for (final tone in SynkTone.values) {
            await tester.pumpWidget(
              synkApp(
                _top(
                  SizedBox(
                    width: 300,
                    child: UsageMeter(
                      fraction: 0.37,
                      tone: tone,
                      segments: 10,
                      gap: 4,
                    ),
                  ),
                ),
                brightness: brightness,
              ),
            );
            final painter = _painterOf(tester);
            expect(painter.filled, 4, reason: 'round(0.37 * 10)');
            expect(painter.segments, 10);
            expect(painter.gap, 4);
            expect(painter.fillColor, colors.toneAccent(tone), reason: '$tone');
          }
        }
        expect(
          SynkColors.light.toneAccent(SynkTone.lavender),
          const Color(0xFFA9B6FD),
        );
        expect(
          SynkColors.light.toneAccent(SynkTone.ice),
          const Color(0xFFC4D5DD),
        );
      },
    );

    testWidgets('clamps out-of-range fractions at the widget level', (
      tester,
    ) async {
      Future<void> pumpAt(double fraction) => tester.pumpWidget(
        synkApp(
          _top(SizedBox(width: 300, child: UsageMeter(fraction: fraction))),
        ),
      );
      await pumpAt(3);
      expect(_painterOf(tester).filled, 8);
      await pumpAt(-1);
      expect(_painterOf(tester).filled, 0);
      await pumpAt(double.nan);
      expect(_painterOf(tester).filled, 0);
    });

    testWidgets('exposes the percentage and label to screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 300,
              child: UsageMeter(fraction: 0.724, semanticLabel: 'Storage used'),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(UsageMeter)),
        isSemantics(label: 'Storage used', value: '72%'),
      );
      await tester.pumpWidget(
        synkApp(
          _top(const SizedBox(width: 300, child: UsageMeter(fraction: 2))),
        ),
      );
      expect(
        tester.getSemantics(find.byType(UsageMeter)),
        isSemantics(value: '100%'),
      );
      handle.dispose();
    });

    testWidgets('is filled at once when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _top(const SizedBox(width: 300, child: UsageMeter(fraction: 0.75))),
        ),
      );
      expect(_painterOf(tester).filled, 6);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('sweeps left to right on first show and lands on the target', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _animated(
            _top(const SizedBox(width: 300, child: UsageMeter(fraction: 0.75))),
          ),
        ),
      );
      expect(_painterOf(tester).filled, 0, reason: 'starts empty');
      await tester.pump(UsageMeter.fillDuration ~/ 2);
      final mid = _painterOf(tester).filled;
      expect(mid, inExclusiveRange(0, 6));
      await tester.pump(UsageMeter.fillDuration ~/ 4);
      expect(_painterOf(tester).filled, greaterThan(mid), reason: 'monotonic');
      await tester.pump(UsageMeter.fillDuration);
      expect(_painterOf(tester).filled, 6);
      await tester.pumpAndSettle();
      expect(_painterOf(tester).filled, 6);
    });

    testWidgets('retargets from the current value when the fraction changes', (
      tester,
    ) async {
      Future<void> pumpAt(double fraction) => tester.pumpWidget(
        synkApp(
          _animated(
            _top(SizedBox(width: 300, child: UsageMeter(fraction: fraction))),
          ),
        ),
      );
      await pumpAt(0.75);
      await tester.pumpAndSettle();
      expect(_painterOf(tester).filled, 6);

      await pumpAt(0.25);
      expect(
        _painterOf(tester).filled,
        6,
        reason: 'continues from the old value',
      );
      await tester.pump(UsageMeter.fillDuration ~/ 3);
      expect(_painterOf(tester).filled, inExclusiveRange(2, 6));
      await tester.pumpAndSettle();
      expect(_painterOf(tester).filled, 2);
    });

    group('painter', () {
      const size = Size(400, 40);

      test('segment width splits the space left by the gaps evenly', () {
        expect(UsageMeterPainter.segmentWidth(400, 8, 6), closeTo(44.75, 1e-9));
        expect(UsageMeterPainter.segmentWidth(100, 1, 6), 100);
      });

      test('draws one filled pill per filled segment and one dashed outline per empty one', () {
        final calls = _record(_painter(filled: 3), size);
        expect(_calls(calls, #drawRRect).length, 3);
        expect(_calls(calls, #drawPath).length, 5);
        expect(_calls(calls, #clipRRect), isEmpty);
      });

      test('a fully filled meter has no dashes, an empty one no fills', () {
        final full = _record(_painter(filled: 8), size);
        expect(_calls(full, #drawRRect).length, 8);
        expect(_calls(full, #drawPath), isEmpty);
        final empty = _record(_painter(filled: 0), size);
        expect(_calls(empty, #drawRRect), isEmpty);
        expect(_calls(empty, #drawPath).length, 8);
      });

      test('pills are equal width, spaced by the gap, and fully rounded', () {
        final calls = _record(_painter(filled: 8), size);
        final pills = _calls(
          calls,
          #drawRRect,
        ).map((call) => call.positionalArguments.first as RRect).toList();
        final width = UsageMeterPainter.segmentWidth(400, 8, 6);
        for (final pill in pills) {
          expect(pill.width, closeTo(width, 1e-9));
          expect(pill.height, 40);
          expect(pill.tlRadius.x, closeTo(20, 1e-9), reason: 'min(w, h) / 2');
        }
        final offsets = _calls(
          calls,
          #translate,
        ).map((call) => call.positionalArguments.first as double).toList();
        for (var i = 0; i < 8; i++) {
          expect(offsets[i], closeTo(i * (width + 6), 1e-9));
        }
        expect(
          offsets.last + width,
          closeTo(400, 1e-9),
          reason: 'spans the width',
        );
      });

      test(
        'the animating pill is clipped to a partial fill from its left edge',
        () {
          final calls = _record(_painter(filled: 2.5), size);
          expect(_calls(calls, #drawRRect).length, 2);
          expect(_calls(calls, #clipRRect).length, 1);
          final partial =
              _calls(calls, #drawRect).single.positionalArguments.first as Rect;
          final width = UsageMeterPainter.segmentWidth(400, 8, 6);
          expect(partial.left, 0);
          expect(partial.width, closeTo(width / 2, 1e-9));
          // Pills at and after the partial one keep their dashed outline.
          expect(_calls(calls, #drawPath).length, 6);
        },
      );

      test('draws nothing when there is no room', () {
        expect(_record(_painter(), const Size(20, 40)), isEmpty);
        expect(_record(_painter(), const Size(400, 0)), isEmpty);
      });

      test('dashes follow an even 3 on / 3 off pattern with no short dash at the seam', () {
        final pill = RRect.fromRectAndRadius(
          const Rect.fromLTWH(0.5, 0.5, 39, 39),
          const Radius.circular(19.5),
        );
        final dashes = [
          for (final metric in UsageMeterPainter.dashedPath(
            pill,
            3,
            3,
          ).computeMetrics())
            metric.length,
        ];
        // A 39dp circle has a ~122dp perimeter: 20 periods of ~6.09 (3.05 on, 3.05 off).
        expect(dashes.length, 20);
        for (final length in dashes) {
          expect(length, closeTo(3.05, 0.15));
        }
      });

      test('the outline is drawn inside the pill so it never peeks out of the fill', () {
        final canvas = TestRecordingCanvas();
        _painter(
          filled: 0,
          segments: 1,
          gap: 0,
        ).paint(canvas, const Size(40, 40));
        final dashed =
            canvas.invocations
                    .map((call) => call.invocation)
                    .firstWhere((call) => call.memberName == #drawPath)
                    .positionalArguments
                    .first
                as Path;
        final bounds = dashed.getBounds();
        expect(bounds.left, greaterThanOrEqualTo(0.5 - 1e-6));
        expect(bounds.right, lessThanOrEqualTo(39.5 + 1e-6));
        expect(bounds.top, greaterThanOrEqualTo(0.5 - 1e-6));
        expect(bounds.bottom, lessThanOrEqualTo(39.5 + 1e-6));
      });

      test('shouldRepaint reacts to every input', () {
        final base = _painter();
        expect(base.shouldRepaint(_painter()), isFalse);
        expect(base.shouldRepaint(_painter(filled: 4)), isTrue);
        expect(base.shouldRepaint(_painter(segments: 9)), isTrue);
        expect(base.shouldRepaint(_painter(gap: 8)), isTrue);
      });
    });

    testWidgets('golden: fractions, tones, shapes and the mid-sweep frame', (
      tester,
    ) async {
      const sweeping = SizedBox(
        height: 40,
        child: CustomPaint(
          size: Size.infinite,
          painter: UsageMeterPainter(
            filled: 3.5,
            segments: 8,
            gap: 6,
            fillColor: Color(0xFFA9B6FD),
            dashColor: Color(0x8C737373),
            strokeWidth: 1,
          ),
        ),
      );
      await expectStateSheetGolden(
        tester,
        'meters_usage_meter',
        [
          for (final fraction in const [0.0, 0.12, 0.37, 0.5, 0.72, 0.9, 1.0])
            GoldenCell(
              'lavender ${(fraction * 100).round()}%',
              UsageMeter(fraction: fraction),
            ),
          for (final tone in SynkTone.values)
            GoldenCell(
              '${tone.name} 72%',
              UsageMeter(fraction: 0.72, tone: tone),
            ),
          const GoldenCell(
            '5 segments, height 24, gap 4',
            UsageMeter(fraction: 0.6, segments: 5, height: 24, gap: 4),
          ),
          const GoldenCell(
            '12 segments, height 16',
            UsageMeter(fraction: 0.5, segments: 12, height: 16, gap: 4),
          ),
          const GoldenCell('mid-sweep frame (3.5 of 8)', sweeping),
        ],
        size: const Size(420, 1050),
        cellWidth: 388,
      );
    });
  });

  group('UsageMeterCard', () {
    testWidgets('shows title, badge, big value with unit and the meter', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(_top(SizedBox(width: 380, child: _card()))),
      );
      expect(find.text('Operations'), findsOneWidget);
      expect(find.text('72% Used'), findsOneWidget);
      expect(find.text('720'), findsOneWidget);
      expect(find.text('/ 1 000'), findsOneWidget);
      expect(find.byType(UsageMeter), findsOneWidget);
      expect(find.byType(SynkIcon), findsOneWidget);
      final badge = tester.widget<SynkBadge>(find.byType(SynkBadge));
      expect(badge.variant, SynkBadgeVariant.ink);
      final value = tester.widget<Text>(find.text('720'));
      expect(value.style!.fontSize, 44, reason: 'statXl');
      expect(value.style!.fontWeight, FontWeight.w700);
      final unit = tester.widget<Text>(find.text('/ 1 000'));
      expect(unit.style!.fontSize, 14, reason: 'statUnit');
      expect(unit.style!.color, SynkColors.light.mutedForeground);
    });

    testWidgets('value and unit share a baseline and the unit is optional', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(_top(SizedBox(width: 380, child: _card()))),
      );
      final value = tester.getRect(find.text('720'));
      final unit = tester.getRect(find.text('/ 1 000'));
      expect(unit.left, greaterThan(value.right));
      expect(unit.bottom, lessThanOrEqualTo(value.bottom));

      await tester.pumpWidget(
        synkApp(_top(SizedBox(width: 380, child: _card(unitText: null)))),
      );
      expect(find.text('/ 1 000'), findsNothing);
      expect(find.text('720'), findsOneWidget);
    });

    testWidgets('passes fraction, segments and tone to the meter', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 380,
              child: UsageMeterCard(
                title: 'Storage',
                icon: SynkIcons.hardDrive,
                badgeText: '37% Used',
                valueText: '3.7 GB',
                fraction: 0.37,
                tone: SynkTone.ice,
                segments: 10,
              ),
            ),
          ),
        ),
      );
      final meter = tester.widget<UsageMeter>(find.byType(UsageMeter));
      expect(meter.fraction, 0.37);
      expect(meter.segments, 10);
      expect(meter.tone, SynkTone.ice);
      expect(_painterOf(tester).filled, 4);
    });

    testWidgets('sits on the pastel surface of its tone', (tester) async {
      await tester.pumpWidget(
        synkApp(_top(SizedBox(width: 380, child: _card(tone: SynkTone.blush)))),
      );
      final surface = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(UsageMeterCard),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .first;
      expect(surface.color, SynkColors.light.blush);
      expect(surface.borderRadius, BorderRadius.circular(28));
    });

    testWidgets('reads as one node and is a button only with onTap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(_top(SizedBox(width: 380, child: _card()))),
      );
      var node = tester.getSemantics(find.byType(UsageMeterCard));
      expect(node, isSemantics(label: 'Operations, 72% Used, 720 / 1 000'));
      expect(node, isNot(isSemantics(isButton: true)));

      var taps = 0;
      await tester.pumpWidget(
        synkApp(_top(SizedBox(width: 380, child: _card(onTap: () => taps++)))),
      );
      node = tester.getSemantics(find.byType(UsageMeterCard));
      expect(
        node,
        isSemantics(
          isButton: true,
          hasTapAction: true,
          label: 'Operations, 72% Used, 720 / 1 000',
        ),
      );
      await tester.tap(find.byType(UsageMeterCard));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets(
      'loading shows a skeleton of the same height and ignores taps',
      (tester) async {
        final handle = tester.ensureSemantics();
        for (final scale in [1.0, 1.3]) {
          await tester.pumpWidget(
            synkApp(
              _top(SizedBox(width: 380, child: _card())),
              textScale: scale,
            ),
          );
          final loaded = tester.getSize(find.byType(UsageMeterCard));
          var taps = 0;
          await tester.pumpWidget(
            synkApp(
              _top(
                SizedBox(
                  width: 380,
                  child: _card(loading: true, onTap: () => taps++),
                ),
              ),
              textScale: scale,
            ),
          );
          final loading = tester.getSize(find.byType(UsageMeterCard));
          expect(
            loading.height,
            closeTo(loaded.height, 1.0),
            reason: 'scale $scale',
          );
          expect(loading.width, loaded.width);
          expect(find.text('720'), findsNothing);
          expect(find.text('72% Used'), findsNothing);
          expect(find.text('Operations'), findsNothing);
          expect(find.byType(UsageMeter), findsNothing);
          expect(find.byType(Skeleton), findsWidgets);
          await tester.tap(find.byType(UsageMeterCard), warnIfMissed: false);
          expect(taps, 0);
          expect(
            tester.getSemantics(find.byType(UsageMeterCard)),
            isSemantics(label: 'Operations, loading'),
          );
          expect(
            tester.getSemantics(find.byType(UsageMeterCard)),
            isNot(isSemantics(isButton: true)),
          );
        }
        handle.dispose();
      },
    );

    testWidgets('loading keeps the 8-pill row of the meter', (tester) async {
      await tester.pumpWidget(
        synkApp(_top(SizedBox(width: 380, child: _card(loading: true)))),
      );
      final pills = tester
          .widgetList<Skeleton>(find.byType(Skeleton))
          .where((s) => s.radius > 1000)
          .length;
      // 8 meter pills + the pill-shaped badge placeholder.
      expect(pills, 9);
    });

    testWidgets('survives text scale 1.3 with long text in a narrow card', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            SizedBox(
              width: 220,
              child: _card(
                title: 'Operations and monthly team activity',
                valueText: '1 234 567 890',
                unitText: '/ 2 000 000 000',
              ),
            ),
          ),
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('1 234 567 890'), findsOneWidget);
      expect(tester.getSize(find.byType(UsageMeterCard)).width, 220);
    });

    for (final tone in [
      SynkTone.lavender,
      SynkTone.ice,
      SynkTone.blush,
      SynkTone.neutral,
    ]) {
      testWidgets('golden: ${tone.name} at 0 / 37 / 72 / 100 % and loading', (
        tester,
      ) async {
        await expectStateSheetGolden(
          tester,
          'meters_card_${tone.name}',
          [
            GoldenCell(
              '0%',
              _card(
                fraction: 0,
                tone: tone,
                title: 'Watch time',
                icon: SynkIcons.clock,
              ),
            ),
            GoldenCell(
              '37%',
              _card(
                fraction: 0.37,
                tone: tone,
                title: 'Storage',
                icon: SynkIcons.hardDrive,
                valueText: '3.7 GB',
                unitText: '/ 10 GB',
              ),
            ),
            GoldenCell('72%', _card(tone: tone, onTap: () {})),
            GoldenCell(
              '100%',
              _card(
                fraction: 1,
                tone: tone,
                title: 'Members',
                icon: SynkIcons.users,
                valueText: '10',
                unitText: '/ 10',
              ),
            ),
            GoldenCell('loading', _card(tone: tone, loading: true)),
          ],
          size: const Size(420, 1290),
          cellWidth: 388,
        );
      });
    }

    testWidgets('golden: card at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'meters_card_scale13',
        [
          GoldenCell('72%', _card()),
          GoldenCell('loading', _card(loading: true)),
          GoldenCell(
            'long text, ice',
            _card(
              tone: SynkTone.ice,
              title: 'Operations and monthly team activity',
              valueText: '1 234 567',
              unitText: '/ 2 000 000',
            ),
          ),
        ],
        size: const Size(420, 850),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });

  group('StatTile', () {
    testWidgets(
      'shows upper-cased label, 15/700 value and 11sp muted caption',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            _top(
              const SizedBox(
                width: 170,
                child: StatTile(
                  label: 'Lifetime Watched',
                  value: '12h 30m',
                  caption: 'Shared watch time',
                ),
              ),
            ),
          ),
        );
        expect(find.text('LIFETIME WATCHED'), findsOneWidget);
        final label = tester.widget<Text>(find.text('LIFETIME WATCHED')).style!;
        expect(label.fontSize, 9);
        expect(label.fontWeight, FontWeight.w700);
        expect(label.letterSpacing, 0.4);
        expect(label.color, SynkColors.light.mutedForeground);
        final value = tester.widget<Text>(find.text('12h 30m')).style!;
        expect(value.fontSize, 15);
        expect(value.fontWeight, FontWeight.w700);
        expect(value.color, SynkColors.light.foreground);
        final caption = tester
            .widget<Text>(find.text('Shared watch time'))
            .style!;
        expect(caption.fontSize, 11);
        expect(caption.color, SynkColors.light.mutedForeground);
      },
    );

    testWidgets(
      'neutral tile: radius 10, muted@.5 fill, border@.4 outline, padding 10',
      (tester) async {
        for (final brightness in Brightness.values) {
          final colors = brightness == Brightness.dark
              ? SynkColors.dark
              : SynkColors.light;
          await tester.pumpWidget(
            synkApp(
              _top(
                const SizedBox(
                  width: 170,
                  child: StatTile(label: 'Streak', value: '3 day'),
                ),
              ),
              brightness: brightness,
            ),
          );
          final decoration =
              tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byType(StatTile),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration;
          expect(decoration.color, colors.muted.withValues(alpha: 0.5));
          expect(decoration.borderRadius, BorderRadius.circular(10));
          final border = decoration.border! as Border;
          expect(
            border.top.color,
            brightness == Brightness.dark
                ? colors.border
                : colors.border.withValues(alpha: 0.4),
          );
          expect(border.top.width, 1);
          final padding = tester
              .widget<Padding>(
                find
                    .descendant(
                      of: find.byType(StatTile),
                      matching: find.byType(Padding),
                    )
                    .first,
              )
              .padding;
          expect(padding, const EdgeInsets.all(10));
        }
      },
    );

    testWidgets('pastel tone: tone surface, radius 18, no outline', (
      tester,
    ) async {
      for (final tone in [SynkTone.lavender, SynkTone.ice, SynkTone.blush]) {
        await tester.pumpWidget(
          synkApp(
            _top(
              SizedBox(
                width: 170,
                child: StatTile(label: 'Streak', value: '3 day', tone: tone),
              ),
            ),
          ),
        );
        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(StatTile),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(decoration.color, SynkColors.light.toneSurface(tone));
        expect(decoration.borderRadius, BorderRadius.circular(18));
        expect(decoration.border, isNull);
      }
    });

    testWidgets('fills the width it is given', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 170,
              child: StatTile(label: 'Streak', value: '3 day'),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(StatTile)).width, 170);
    });

    testWidgets('valueTrailing sits right of the value', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 170,
              child: StatTile(
                label: 'Streak',
                value: '3 day',
                valueTrailing: Text('🔥'),
                caption: 'Active streak',
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getRect(find.text('🔥')).left,
        greaterThanOrEqualTo(tester.getRect(find.text('3 day')).right),
      );
      expect(
        (tester.getRect(find.text('🔥')).center.dy -
                tester.getRect(find.text('3 day')).center.dy)
            .abs(),
        lessThan(6),
        reason: 'vertically aligned',
      );
    });

    testWidgets('accepts a badge as trailing content', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 170,
              child: StatTile(
                label: 'Weekly points',
                value: '120 pts',
                valueTrailing: SynkBadge(text: '#3', small: true),
              ),
            ),
          ),
        ),
      );
      expect(find.text('#3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'loading shows two skeleton bars and hides value, caption and retry',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            _top(
              SizedBox(
                width: 170,
                child: StatTile(
                  label: 'This Week',
                  value: '2h',
                  caption: 'Mon – Sun',
                  loading: true,
                  errorText: 'Unavailable',
                  onRetry: () {},
                ),
              ),
            ),
          ),
        );
        final bars = tester
            .widgetList<Skeleton>(find.byType(Skeleton))
            .toList();
        expect(bars.map((b) => b.height), [16, 10]);
        expect(find.text('2h'), findsNothing);
        expect(find.text('Mon – Sun'), findsNothing);
        expect(find.text('Unavailable'), findsNothing);
        expect(find.text('Retry'), findsNothing);
        expect(find.text('THIS WEEK'), findsOneWidget, reason: 'label stays');
        // 70 % and 50 % of the 150dp inner width (170 - 2 x 10 padding).
        final sizes = [
          for (final element in find.byType(Skeleton).evaluate())
            tester.getSize(find.byWidget(element.widget)),
        ];
        expect(sizes[0].width, closeTo(0.7 * 150, 0.01));
        expect(sizes[1].width, closeTo(0.5 * 150, 0.01));
      },
    );

    testWidgets(
      'error without a value shows "Unavailable" and a working Retry',
      (tester) async {
        final handle = tester.ensureSemantics();
        var retries = 0;
        await tester.pumpWidget(
          synkApp(
            _top(
              SizedBox(
                width: 170,
                child: StatTile(
                  label: 'This Week',
                  errorText: '',
                  onRetry: () => retries++,
                ),
              ),
            ),
          ),
        );
        expect(find.text('Unavailable'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text('Unavailable')).style!.color,
          SynkColors.light.destructive,
        );
        expect(
          tester.widget<Text>(find.text('Unavailable')).style!.fontSize,
          11,
        );
        expect(find.byType(Skeleton), findsNothing);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Retry')),
          isSemantics(isButton: true, label: 'Retry', hasTapAction: true),
        );
        await tester.tap(find.text('Retry'));
        expect(retries, 1);
        handle.dispose();
      },
    );

    testWidgets('error shows custom text and no Retry without a callback', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 170,
              child: StatTile(label: 'Streak', errorText: 'Offline'),
            ),
          ),
        ),
      );
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Unavailable'), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('the Retry hit target is at least 36dp tall', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            SizedBox(
              width: 170,
              child: StatTile(label: 'Streak', errorText: '', onRetry: () {}),
            ),
          ),
        ),
      );
      final target = find.ancestor(
        of: find.text('Retry'),
        matching: find.byType(GestureDetector),
      );
      expect(tester.getSize(target.first).height, greaterThanOrEqualTo(36));
    });

    testWidgets('a stale value wins over the error flag', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 170,
              child: StatTile(
                label: 'Streak',
                value: '3 day',
                errorText: 'Unavailable',
              ),
            ),
          ),
        ),
      );
      expect(find.text('3 day'), findsOneWidget);
      expect(find.text('Unavailable'), findsNothing);
    });

    testWidgets('reads as one node when showing content', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 170,
              child: StatTile(
                label: 'Lifetime Watched',
                value: '12h 30m',
                caption: 'Shared watch time',
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('12h 30m')),
        isSemantics(label: 'Lifetime Watched\n12h 30m\nShared watch time'),
      );
      handle.dispose();
    });

    testWidgets('survives text scale 1.3 in a narrow tile', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SizedBox(
              width: 130,
              child: StatTile(
                label: 'Weekly points and rank',
                value: '1 234 pts',
                caption: 'Watch points and chat points',
                valueTrailing: SynkBadge(text: '#12', small: true),
              ),
            ),
          ),
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        synkApp(
          _top(
            SizedBox(
              width: 130,
              child: StatTile(
                label: 'Weekly points and rank',
                errorText: '',
                onRetry: () {},
              ),
            ),
          ),
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('golden: stat tiles at text scale $scale', (tester) async {
        Widget tile({
          String label = 'Lifetime Watched',
          String? value = '12h 30m',
          String? caption = 'Shared watch time',
          Widget? trailing,
          bool loading = false,
          String? error,
          VoidCallback? onRetry,
          SynkTone tone = SynkTone.neutral,
        }) => StatTile(
          label: label,
          value: value,
          caption: caption,
          valueTrailing: trailing,
          loading: loading,
          errorText: error,
          onRetry: onRetry,
          tone: tone,
        );
        Widget pair(Widget a, Widget b) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Expanded(child: a),
            Expanded(child: b),
          ],
        );
        await expectStateSheetGolden(
          tester,
          'meters_stat_tile${scale == 1.0 ? '' : '_scale13'}',
          [
            GoldenCell(
              'neutral: content / with flame trailing',
              pair(
                tile(),
                tile(
                  label: 'Daily Streak',
                  value: '3 day',
                  caption: 'Active streak',
                  trailing: const SynkIcon(
                    SynkIcons.flame,
                    size: 14,
                    color: SynkPalette.amber,
                  ),
                ),
              ),
            ),
            GoldenCell(
              'neutral: badge trailing / loading',
              pair(
                tile(
                  label: 'Weekly points and rank',
                  value: '120 pts',
                  caption: '90 watch · 30 chat',
                  trailing: const SynkBadge(text: '#3', small: true),
                ),
                tile(loading: true),
              ),
            ),
            GoldenCell(
              'neutral: error with retry / error without retry',
              pair(
                tile(
                  label: 'This Week',
                  value: null,
                  caption: null,
                  error: '',
                  onRetry: () {},
                ),
                tile(
                  label: 'This Week',
                  value: null,
                  caption: null,
                  error: 'Offline',
                ),
              ),
            ),
            GoldenCell(
              'lavender / ice',
              pair(
                tile(tone: SynkTone.lavender),
                tile(
                  tone: SynkTone.ice,
                  label: 'Daily Streak',
                  value: '3 day',
                  caption: 'Active streak',
                  trailing: const SynkIcon(
                    SynkIcons.flame,
                    size: 14,
                    color: SynkPalette.amber,
                  ),
                ),
              ),
            ),
            GoldenCell(
              'blush / pastel loading',
              pair(
                tile(
                  tone: SynkTone.blush,
                  label: 'This Week',
                  value: '2h 5m',
                  caption: 'Mon – Sun IST',
                ),
                tile(tone: SynkTone.lavender, loading: true),
              ),
            ),
            GoldenCell(
              'pastel error',
              pair(
                tile(
                  tone: SynkTone.ice,
                  value: null,
                  caption: null,
                  error: '',
                  onRetry: () {},
                ),
                tile(
                  tone: SynkTone.blush,
                  value: null,
                  caption: null,
                  error: '',
                ),
              ),
            ),
          ],
          size: Size(420, scale == 1.0 ? 720 : 800),
          cellWidth: 388,
          textScale: scale,
        );
      });
    }
  });
}
