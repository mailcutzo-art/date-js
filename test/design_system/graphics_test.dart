import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/confetti.dart';
import 'package:date_js/design_system/components/dot_grid_background.dart';
import 'package:date_js/design_system/components/dot_logo.dart';
import 'package:date_js/design_system/components/ring_counter.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_palette.dart';
import 'package:date_js/design_system/tokens/synk_theme.dart';

import '../support/synk_test_harness.dart';

/// Re-enables animations inside [synkApp] (the harness disables them for deterministic goldens).
Widget _animated(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: false),
    child: child,
  ),
);

/// Mounts the widget built from [state] once and lets the test change [state] without rebuilding
/// the app (re-pumping `synkApp` restarts the theme cross-fade, which muddies ticker counts).
Widget _driven<T>(ValueNotifier<T> state, Widget Function(T value) builder) =>
    synkApp(
      _animated(
        ValueListenableBuilder<T>(
          valueListenable: state,
          builder: (context, value, _) => builder(value),
        ),
      ),
    );

void main() {
  group('DotLogoGeometry', () {
    // 'SYNKLY': cols = 6*4 + 5*3.4 = 41, so cols*2.2 + 2.2 = 92.4.
    test(
      'dot diameter follows clamp(0.7 * screenWidth / (cols*2.2+2.2), 2.5, 8)',
      () {
        double d(double screenWidth, {double? fraction}) =>
            DotLogoGeometry.dotDiameter(
              text: 'SYNKLY',
              screenWidth: screenWidth,
              widthFraction: fraction ?? 0.7,
            );
        expect(d(400), closeTo(280 / 92.4, 1e-9));
        expect(d(1080), 8, reason: 'clamped to the maximum');
        expect(d(200), 2.5, reason: 'clamped to the minimum');
        expect(d(400, fraction: 0.5), 2.5);
        expect(d(900, fraction: 0.5), closeTo(450 / 92.4, 1e-9));
      },
    );

    test('derived sizes at d = 8 match the formulas by hand', () {
      // spacing 17.6, letterSpacing 27.2, advance 4*17.6 + 27.2 = 97.6, large 17.6.
      final g = DotLogoGeometry(text: 'SYNKLY', dot: 8);
      expect(g.spacing, closeTo(17.6, 1e-9));
      expect(g.letterSpacing, closeTo(27.2, 1e-9));
      expect(g.advance, closeTo(97.6, 1e-9));
      expect(g.large, closeTo(17.6, 1e-9));
      // width = 5*97.6 + 4*17.6 + 17.6 = 576, height = 6*17.6 + 17.6 = 123.2.
      expect(g.width, closeTo(576, 1e-9));
      expect(g.height, closeTo(123.2, 1e-9));
    });

    test(
      'every cell of every glyph is a dot; "X" cells are the large ones',
      () {
        final g = DotLogoGeometry(text: 'SYNKLY', dot: 4);
        expect(g.dots, hasLength(6 * 7 * 5));
        // S 15 + Y 10 + N 17 + K 14 + L 11 + Y 10 "X" cells.
        expect(g.dots.where((d) => d.large), hasLength(77));
      },
    );

    test('dot positions: first dot is half a large dot in, later cells step by spacing', () {
      final g = DotLogoGeometry(text: 'SYNKLY', dot: 4);
      final pad = g.large / 2;
      expect(g.dots.first.x, closeTo(pad, 1e-9));
      expect(g.dots.first.y, closeTo(pad, 1e-9));
      // Dot of character 1, row 2, column 3.
      final dot = g.dots[1 * 35 + 2 * 5 + 3];
      expect(dot.x, closeTo(g.advance + 3 * g.spacing + pad, 1e-9));
      expect(dot.y, closeTo(2 * g.spacing + pad, 1e-9));
    });

    test('per-dot phase is frac(sin((c*1009 + r*31 + k*7 + 9001) * 12.9898) * 43758.5453)', () {
      // Reference values from an independent evaluation of the formula.
      expect(
        DotLogoGeometry.dotPhase(0, 0, 0),
        closeTo(0.037882038104726234, 1e-9),
      );
      expect(
        DotLogoGeometry.dotPhase(0, 3, 2),
        closeTo(0.9172811945245485, 1e-9),
      );
      expect(
        DotLogoGeometry.dotPhase(1, 2, 3),
        closeTo(0.6221548208923195, 1e-9),
      );
      expect(
        DotLogoGeometry.dotPhase(5, 6, 4),
        closeTo(0.7843211852127752, 1e-9),
      );
      final g = DotLogoGeometry(text: 'SYNKLY', dot: 4);
      expect(
        g.dots[1 * 35 + 2 * 5 + 3].phase,
        closeTo(0.6221548208923195, 1e-9),
      );
    });

    test('breathing wave is (sin((p + phase) * 2pi) + 1) / 2', () {
      expect(DotLogoPainter.wave(0, 0), closeTo(0.5, 1e-12));
      expect(DotLogoPainter.wave(0.25, 0), closeTo(1, 1e-12));
      expect(DotLogoPainter.wave(0.75, 0), closeTo(0, 1e-12));
      expect(DotLogoPainter.wave(0.25, 0.5), closeTo(0, 1e-12));
    });

    test('the font covers A-Z, 0-9, ".", "-" and " " with 5 x 7 cells', () {
      const expected = 26 + 10 + 3;
      expect(dotFont, hasLength(expected));
      for (final entry in dotFont.entries) {
        expect(entry.value, hasLength(7), reason: entry.key);
        for (final row in entry.value) {
          expect(row, matches(RegExp(r'^[.X]{5}$')), reason: entry.key);
        }
      }
      expect(dotFont['A']![3], 'XXXXX');
      expect(dotFont['.']![6], '..X..');
      expect(dotFont[' ']!.every((r) => r == '.....'), isTrue);
    });

    test(
      'unknown characters render as a blank cell and lower case is upper-cased',
      () {
        final g = DotLogoGeometry(text: 'a?', dot: 4);
        expect(g.dots, hasLength(70));
        expect(g.dots.sublist(0, 35).where((d) => d.large), hasLength(18));
        expect(g.dots.sublist(35).where((d) => d.large), isEmpty);
      },
    );
  });

  group('DotLogo widget', () {
    testWidgets('sizes itself from the screen width and is labelled "Synkly"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      useGoldenViewport(tester, size: const Size(400, 800));
      await tester.pumpWidget(
        synkApp(const Center(child: DotLogo(animate: false))),
      );
      const d = 280 / 92.4;
      final g = DotLogoGeometry(text: 'SYNKLY', dot: d);
      expect(
        tester.getSize(find.byType(DotLogo)).width,
        closeTo(g.width, 1e-6),
      );
      expect(
        tester.getSize(find.byType(DotLogo)).height,
        closeTo(g.height, 1e-6),
      );
      expect(find.bySemanticsLabel('Synkly'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('maxWidthFraction replaces the 0.7 share', (tester) async {
      useGoldenViewport(tester, size: const Size(400, 800));
      await tester.pumpWidget(
        synkApp(
          const Center(child: DotLogo(animate: false, maxWidthFraction: 0.5)),
        ),
      );
      // 0.5 * 400 / 92.4 = 2.16 -> clamped to 2.5.
      final g = DotLogoGeometry(text: 'SYNKLY', dot: 2.5);
      expect(
        tester.getSize(find.byType(DotLogo)).width,
        closeTo(g.width, 1e-6),
      );
    });

    testWidgets('animation loops while shown and stops with the widget', (
      tester,
    ) async {
      final shown = ValueNotifier<bool>(true);
      addTearDown(shown.dispose);
      await tester.pumpWidget(
        _driven<bool>(
          shown,
          (show) => show ? const Center(child: DotLogo()) : const SizedBox(),
        ),
      );
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      // Runs well past one 2.4 s loop without settling.
      await tester.pump(const Duration(milliseconds: 3000));
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      shown.value = false;
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('animate: false and reduced motion keep the ticker off', (
      tester,
    ) async {
      final animate = ValueNotifier<bool>(false);
      addTearDown(animate.dispose);
      await tester.pumpWidget(
        _driven<bool>(
          animate,
          (value) => Center(child: DotLogo(animate: value)),
        ),
      );
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('reduced motion wins over animate: true', (tester) async {
      // The harness disables animations by default.
      await tester.pumpWidget(synkApp(const Center(child: DotLogo())));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('toggling animate starts and stops the ticker', (tester) async {
      final animate = ValueNotifier<bool>(false);
      addTearDown(animate.dispose);
      await tester.pumpWidget(
        _driven<bool>(
          animate,
          (value) => Center(child: DotLogo(animate: value)),
        ),
      );
      expect(tester.binding.transientCallbackCount, 0);
      animate.value = true;
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      animate.value = false;
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    });

    test('painter repaints for new geometry, colour or animation only', () {
      final g = DotLogoGeometry(text: 'SYNKLY', dot: 4);
      final base = DotLogoPainter(geometry: g, color: Colors.white);
      expect(
        base.shouldRepaint(DotLogoPainter(geometry: g, color: Colors.white)),
        isFalse,
      );
      expect(
        base.shouldRepaint(DotLogoPainter(geometry: g, color: Colors.black)),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          DotLogoPainter(
            geometry: DotLogoGeometry(text: 'SYNKLY', dot: 5),
            color: Colors.white,
          ),
        ),
        isTrue,
      );
    });
  });

  group('Confetti', () {
    test('a seeded burst is reproducible and respects the physics ranges', () {
      final a = ConfettiPiece.burst(70, seed: 42);
      final b = ConfettiPiece.burst(70, seed: 42);
      expect(a, hasLength(70));
      for (var i = 0; i < a.length; i++) {
        expect(a[i].angle, b[i].angle);
        expect(a[i].speed, b[i].speed);
        expect(a[i].color, b[i].color);
        expect(a[i].round, b[i].round);
      }
      expect(
        ConfettiPiece.burst(70, seed: 43).map((p) => p.angle),
        isNot(a.map((p) => p.angle)),
      );
      for (final p in ConfettiPiece.burst(500, seed: 7)) {
        expect(p.angle, inInclusiveRange(-(0.35 + 2.44), -0.35));
        expect(p.speed, inInclusiveRange(0.45, 1.2));
        expect(p.spin, inInclusiveRange(-1.5, 1.5));
        expect(p.size, inInclusiveRange(5, 11));
        expect(p.phase, inInclusiveRange(0, 360));
        expect(SynkPalette.confetti, contains(p.color));
      }
    });

    test(
      'about a quarter of the pieces are discs and all six colours appear',
      () {
        final pieces = ConfettiPiece.burst(2000, seed: 11);
        final round = pieces.where((p) => p.round).length / pieces.length;
        expect(round, inInclusiveRange(0.21, 0.29));
        expect(pieces.map((p) => p.color).toSet(), hasLength(6));
      },
    );

    test(
      'position: launch from (w/2, 0.62h), speed*h per second, gravity 1.7h',
      () {
        const piece = ConfettiPiece(
          angle: -math.pi / 2, // straight up
          speed: 1,
          spin: 1,
          size: 8,
          color: Colors.white,
          round: false,
          phase: 90,
        );
        const area = Size(100, 200);
        final start = piece.positionAt(0, area);
        expect(start.dx, closeTo(50, 1e-9));
        expect(start.dy, closeTo(124, 1e-9)); // 0.62 * 200
        // t = 0.5 s: y = 124 - 1*200*0.5 + 0.5*(1.7*200)*0.25 = 66.5.
        final mid = piece.positionAt(0.5, area);
        expect(mid.dx, closeTo(50, 1e-9));
        expect(mid.dy, closeTo(66.5, 1e-9));
        // The piece falls back below its origin eventually (gravity wins).
        expect(piece.positionAt(2.4, area).dy, greaterThan(124));
      },
    );

    test('position: a 45 degree launch moves sideways by cos(angle) * speed * h * t', () {
      const piece = ConfettiPiece(
        angle: -math.pi / 4,
        speed: 0.5,
        spin: 0,
        size: 8,
        color: Colors.white,
        round: true,
        phase: 0,
      );
      const area = Size(300, 400);
      final p = piece.positionAt(1, area);
      expect(p.dx, closeTo(150 + math.cos(math.pi / 4) * 0.5 * 400, 1e-9));
      expect(
        p.dy,
        closeTo(
          0.62 * 400 - math.sin(math.pi / 4) * 0.5 * 400 + 0.5 * 680,
          1e-9,
        ),
      );
    });

    test('rotation is phase degrees plus spin turns per second', () {
      const piece = ConfettiPiece(
        angle: -1,
        speed: 1,
        spin: 0.5,
        size: 8,
        color: Colors.white,
        round: false,
        phase: 90,
      );
      expect(piece.rotationAt(0), closeTo(math.pi / 2, 1e-12));
      // 0.5 turns/s for 1 s = 180 degrees more.
      expect(piece.rotationAt(1), closeTo(math.pi / 2 + math.pi, 1e-12));
    });

    test('opacity is 1 until t = 0.7, then fades linearly to 0 at the end', () {
      expect(Confetti.alphaAt(0), 1);
      expect(Confetti.alphaAt(0.69), 1);
      expect(Confetti.alphaAt(0.7), closeTo(1, 1e-12));
      expect(Confetti.alphaAt(0.85), closeTo(0.5, 1e-12));
      expect(Confetti.alphaAt(1), 0);
      expect(Confetti.alphaAt(1.2), 0);
    });

    testWidgets(
      'plays when trigger changes to a positive value and calls onEnd',
      (tester) async {
        var ended = 0;
        final trigger = ValueNotifier<int>(0);
        addTearDown(trigger.dispose);
        await tester.pumpWidget(
          _driven<int>(
            trigger,
            (value) => Stack(
              children: [
                Positioned.fill(
                  child: Confetti(
                    trigger: value,
                    seed: 1,
                    onEnd: () => ended++,
                  ),
                ),
              ],
            ),
          ),
        );
        expect(tester.binding.transientCallbackCount, 0, reason: 'idle at 0');

        trigger.value = 1;
        await tester.pump();
        expect(tester.binding.transientCallbackCount, greaterThan(0));
        await tester.pump(const Duration(milliseconds: 1200));
        expect(ended, 0, reason: 'still flying');
        await tester.pump(const Duration(milliseconds: 1300));
        expect(ended, 1);
        expect(tester.binding.transientCallbackCount, 0);

        // The same trigger does not replay, a new one does.
        trigger.value = 1;
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);
        trigger.value = 2;
        await tester.pump();
        expect(tester.binding.transientCallbackCount, greaterThan(0));
        await tester.pump(const Duration(milliseconds: 2500));
        expect(ended, 2);

        // Dropping back to zero must not start another burst.
        trigger.value = 0;
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);
        expect(ended, 2);
      },
    );

    testWidgets('changing the trigger mid-burst restarts it', (tester) async {
      var ended = 0;
      final trigger = ValueNotifier<int>(1);
      addTearDown(trigger.dispose);
      await tester.pumpWidget(
        _driven<int>(
          trigger,
          (value) => Stack(
            children: [
              Positioned.fill(
                child: Confetti(trigger: value, onEnd: () => ended++),
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));
      trigger.value = 2;
      await tester.pump();
      // Without the restart the first burst would have ended after another 900 ms.
      await tester.pump(const Duration(milliseconds: 1000));
      expect(ended, 0);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(ended, 1);
    });

    testWidgets('a trigger that is already positive on mount plays once', (
      tester,
    ) async {
      var ended = 0;
      await tester.pumpWidget(
        synkApp(
          _animated(
            Stack(
              children: [
                Positioned.fill(
                  child: Confetti(trigger: 3, onEnd: () => ended++),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 2500));
      expect(ended, 1);
    });

    testWidgets('removing it mid-burst stops the ticker', (tester) async {
      final shown = ValueNotifier<bool>(true);
      addTearDown(shown.dispose);
      await tester.pumpWidget(
        _driven<bool>(
          shown,
          (show) => Stack(
            children: [
              if (show) const Positioned.fill(child: Confetti(trigger: 1)),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      shown.value = false;
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('reduced motion skips the burst but still reports the end', (
      tester,
    ) async {
      var ended = 0;
      await tester.pumpWidget(
        synkApp(
          Stack(
            children: [
              Positioned.fill(
                child: Confetti(trigger: 1, onEnd: () => ended++),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      expect(ended, 1);
    });

    testWidgets('never intercepts touches', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        synkApp(
          _animated(
            Stack(
              children: [
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps++,
                    child: const SizedBox(
                      key: ValueKey('target'),
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
                const Positioned.fill(child: Confetti(trigger: 1, seed: 3)),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('target')));
      expect(taps, 1);
      final ignore = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(Confetti),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignore.ignoring, isTrue);
      await tester.pump(const Duration(milliseconds: 2500));
    });

    test('painter draws nothing before the start and after the end', () {
      final pieces = ConfettiPiece.burst(70, seed: 1);
      for (final t in [0.0, 1.0]) {
        final painter = ConfettiPainter(
          pieces: pieces,
          progress: AlwaysStoppedAnimation<double>(t),
        );
        // Painting must be a no-op and not throw on any canvas.
        painter.paint(_RecordingCanvas(), const Size(300, 400));
        expect((painter.progress.value), t);
      }
    });
  });

  group('DotGridBackground', () {
    test(
      'lattice points are offset by half a step and stay inside the area',
      () {
        final points = DotGridPainter.pointsFor(const Size(30, 30), 14);
        expect(points.toList(), [7, 7, 21, 7, 7, 21, 21, 21]);
        expect(DotGridPainter.pointsFor(Size.zero, 14), isEmpty);
        final big = DotGridPainter.pointsFor(const Size(100, 50), 10);
        // x in {5, 15, ..., 95} (10), y in {5, 15, ..., 45} (5).
        expect(big, hasLength(10 * 5 * 2));
        for (var i = 0; i < big.length; i += 2) {
          expect(big[i], inInclusiveRange(0, 100));
          expect(big[i + 1], inInclusiveRange(0, 50));
        }
      },
    );

    testWidgets('defaults to the foreground colour at ~6% in both themes', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          synkApp(const DotGridBackground(), brightness: brightness),
        );
        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(DotGridBackground),
            matching: find.byType(CustomPaint),
          ),
        );
        final painter = paint.painter! as DotGridPainter;
        final colors = brightness == Brightness.dark
            ? SynkColors.dark
            : SynkColors.light;
        expect(
          painter.color,
          colors.foreground.withValues(alpha: 0.06),
          reason: brightness.name,
        );
        expect(painter.spacing, 14);
        expect(painter.dotRadius, 0.8);
      }
    });

    testWidgets('explicit colour, spacing and radius are used', (tester) async {
      const colour = Color(0x33FF0000);
      await tester.pumpWidget(
        synkApp(
          const DotGridBackground(spacing: 20, dotRadius: 1.5, color: colour),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(DotGridBackground),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as DotGridPainter;
      expect(painter.color, colour);
      expect(painter.spacing, 20);
      expect(painter.dotRadius, 1.5);
    });

    testWidgets('fills its parent alone, sizes to its child otherwise', (
      tester,
    ) async {
      useGoldenViewport(tester, size: const Size(400, 600));
      await tester.pumpWidget(synkApp(const DotGridBackground()));
      expect(
        tester.getSize(find.byType(DotGridBackground)),
        const Size(400, 600),
      );

      await tester.pumpWidget(
        synkApp(
          const Align(
            alignment: Alignment.topLeft,
            child: DotGridBackground(child: SizedBox(width: 120, height: 80)),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(DotGridBackground)),
        const Size(120, 80),
      );
    });

    test('painter repaints only when its inputs change', () {
      final base = DotGridPainter(
        spacing: 14,
        dotRadius: 0.8,
        color: const Color(0x0F000000),
      );
      expect(
        base.shouldRepaint(
          DotGridPainter(
            spacing: 14,
            dotRadius: 0.8,
            color: const Color(0x0F000000),
          ),
        ),
        isFalse,
      );
      expect(
        base.shouldRepaint(
          DotGridPainter(
            spacing: 16,
            dotRadius: 0.8,
            color: const Color(0x0F000000),
          ),
        ),
        isTrue,
      );
    });
  });

  group('RingCounter', () {
    testWidgets(
      'shows the label over the value inside a circle of the given size',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          synkApp(
            const Center(
              child: RingCounter(label: 'Used', value: '1066', size: 64),
            ),
          ),
        );
        expect(tester.getSize(find.byType(RingCounter)), const Size(64, 64));
        final label = tester.getCenter(find.text('Used'));
        final value = tester.getCenter(find.text('1066'));
        expect(
          label.dy,
          lessThan(value.dy),
          reason: 'label sits above the value',
        );
        expect(find.bySemanticsLabel('Used 1066'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets(
      'text stays inside the ring at 1.3x text scale with long values',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            const Center(
              child: RingCounter(label: 'Used', value: '1,234,567', size: 56),
            ),
            textScale: 1.3,
          ),
        );
        final ring = tester.getRect(find.byType(RingCounter));
        expect(
          ring.contains(tester.getRect(find.text('1,234,567')).topLeft),
          isTrue,
        );
        expect(
          ring.contains(tester.getRect(find.text('1,234,567')).bottomRight),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('uses the supplied ring colour', (tester) async {
      const colour = Color(0xFF6366F1);
      await tester.pumpWidget(
        synkApp(
          const Center(
            child: RingCounter(label: 'Used', value: '5', color: colour),
          ),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(RingCounter),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as DashedRingPainter;
      expect(painter.color, colour);
    });

    test('the dash count divides the circumference into whole dashes', () {
      // radius 27.25: circumference 171.2 / (3.5 + 3) = 26.3 -> 26 dashes.
      expect(DashedRingPainter.dashCount(27.25, 3.5, 3), 26);
      // Tiny rings keep at least four dashes.
      expect(DashedRingPainter.dashCount(1, 3.5, 3), 4);
    });
  });

  group('golden sheets', () {
    testWidgets('dot logo frames, confetti frames, dot grid, ring counter', (
      tester,
    ) async {
      final g = DotLogoGeometry(
        text: 'SYNKLY',
        dot: DotLogoGeometry.dotDiameter(text: 'SYNKLY', screenWidth: 420),
      );
      Widget logoFrame(double? progress, {Color? onColor, Color? bg}) =>
          Builder(
            builder: (context) {
              final colors = context.colors;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: g.width,
                    height: g.height,
                    child: CustomPaint(
                      painter: DotLogoPainter(
                        geometry: g,
                        color: onColor ?? colors.foreground,
                        progress: progress == null
                            ? null
                            : AlwaysStoppedAnimation<double>(progress),
                      ),
                    ),
                  ),
                ),
              );
            },
          );

      final cells = <GoldenCell>[
        GoldenCell('dot logo, resting', logoFrame(null)),
        GoldenCell('dot logo, progress 0.00', logoFrame(0)),
        GoldenCell('dot logo, progress 0.25', logoFrame(0.25)),
        GoldenCell('dot logo, progress 0.50', logoFrame(0.5)),
        GoldenCell('dot logo, progress 0.75', logoFrame(0.75)),
        GoldenCell(
          'dot logo, white on brand pink',
          logoFrame(null, onColor: Colors.white, bg: SynkPalette.brandPink),
        ),
      ];
      await expectStateSheetGolden(
        tester,
        'dot_logo',
        cells,
        size: const Size(420, 710),
      );
    });

    testWidgets('confetti at fixed times (seeded)', (tester) async {
      final pieces = ConfettiPiece.burst(70, seed: 20260920);
      Widget frame(double t) => Builder(
        builder: (context) {
          return DecoratedBox(
            decoration: BoxDecoration(
              // Dark stage like the watch room: the white pieces would vanish on a light card.
              color: const Color(0xFF14141C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                size: const Size(180, 240),
                painter: ConfettiPainter(
                  pieces: pieces,
                  progress: AlwaysStoppedAnimation<double>(t),
                ),
              ),
            ),
          );
        },
      );
      await expectStateSheetGolden(
        tester,
        'confetti',
        [
          for (final t in [0.05, 0.15, 0.3, 0.45, 0.6, 0.7])
            GoldenCell('t = ${t.toStringAsFixed(2)}', frame(t)),
        ],
        size: const Size(420, 880),
        cellWidth: 180,
      );
    });

    testWidgets('dot grid backdrop', (tester) async {
      final cells = <GoldenCell>[
        GoldenCell(
          'dot grid (default)',
          SizedBox(
            width: 380,
            height: 150,
            child: DotGridBackground(
              child: Center(
                child: Builder(
                  builder: (context) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 22,
                      ),
                      child: Text('Card over the backdrop'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const GoldenCell(
          'dot grid (spacing 10, r 0.6)',
          SizedBox(
            width: 380,
            height: 80,
            child: DotGridBackground(spacing: 10, dotRadius: 0.6),
          ),
        ),
      ];
      await expectStateSheetGolden(
        tester,
        'dot_grid',
        cells,
        size: const Size(420, 330),
        cellWidth: 388,
      );
    });

    testWidgets('ring counters', (tester) async {
      final cells = <GoldenCell>[
        const GoldenCell(
          'ring 40',
          RingCounter(label: 'Used', value: '42', size: 40),
        ),
        const GoldenCell('ring 56', RingCounter(label: 'Used', value: '1066')),
        const GoldenCell(
          'ring 72',
          RingCounter(label: 'Used', value: '1066', size: 72),
        ),
        const GoldenCell(
          'ring 88',
          RingCounter(label: 'Left', value: '12.4k', size: 88),
        ),
        const GoldenCell(
          'ring, tinted',
          RingCounter(label: 'Used', value: '1066', color: Color(0xFFA9B6FD)),
        ),
        const GoldenCell(
          'ring, long value',
          RingCounter(label: 'Total', value: '1,234,567', size: 64),
        ),
      ];
      await expectStateSheetGolden(
        tester,
        'ring_counter',
        cells,
        size: const Size(420, 420),
        cellWidth: 120,
      );
    });

    testWidgets('ring counters at 1.3x text scale', (tester) async {
      await expectStateSheetGolden(
        tester,
        'ring_counter_scaled',
        const [
          GoldenCell('ring 56', RingCounter(label: 'Used', value: '1066')),
          GoldenCell(
            'ring 72',
            RingCounter(label: 'Used', value: '1066', size: 72),
          ),
          GoldenCell(
            'long value',
            RingCounter(label: 'Total', value: '1,234,567', size: 64),
          ),
        ],
        size: const Size(420, 290),
        cellWidth: 120,
        textScale: 1.3,
      );
    });
  });
}

/// A canvas that fails the test on any call (a painter that draws nothing must not touch it).
class _RecordingCanvas implements Canvas {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    fail('Nothing should be drawn, but ${invocation.memberName} was called');
  }
}
