import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/synk_popover.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_palette.dart';

import '../support/synk_test_harness.dart';

const Size _screen = Size(400, 800);

void _useViewport(WidgetTester tester, {Size size = _screen}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

late BuildContext _host;

Future<void> _pumpHost(
  WidgetTester tester, {
  Size size = _screen,
  Brightness brightness = Brightness.light,
}) async {
  _useViewport(tester, size: size);
  await tester.pumpWidget(
    synkApp(
      Builder(
        builder: (context) {
          _host = context;
          return const SizedBox.expand();
        },
      ),
      brightness: brightness,
    ),
  );
}

class _Result<T> {
  bool done = false;
  T? value;
}

_Result<T> _track<T>(Future<T?> future) {
  final result = _Result<T>();
  unawaited(
    future.then((value) {
      result
        ..done = true
        ..value = value;
    }),
  );
  return result;
}

final Finder _card = find.byType(SynkPopoverCard);

/// `flutter_test` draws shadows without blur by default; goldens show the real thing.
Future<void> _withRealShadows(Future<void> Function() body) async {
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = true;
  }
}

Widget _menu([List<String> labels = const ['Edit', 'Share', 'Delete']]) =>
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final l in labels) PopoverItem(label: l, onTap: () {})],
    );

Future<_Result<String>> _open(
  WidgetTester tester, {
  required Rect anchor,
  WidgetBuilder? builder,
  double minWidth = 200,
  double maxWidth = 320,
  double offsetY = 0,
  bool alignEnd = false,
  bool glass = false,
}) async {
  final result = _track(
    showSynkPopover<String>(
      _host,
      anchor: anchor,
      builder: builder ?? (_) => _menu(),
      minWidth: minWidth,
      maxWidth: maxWidth,
      offsetY: offsetY,
      alignEnd: alignEnd,
      glass: glass,
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

void main() {
  group('placement', () {
    const anchor = Rect.fromLTWH(100, 200, 40, 40);

    testWidgets('sits below the anchor with a 12dp gap, left edges aligned', (
      tester,
    ) async {
      await _pumpHost(tester);
      await _open(tester, anchor: anchor);
      final rect = tester.getRect(_card);
      expect(rect.top, closeTo(240 + 12, 0.01));
      expect(rect.left, closeTo(100, 0.01));
    });

    testWidgets('offsetY pushes it further away', (tester) async {
      await _pumpHost(tester);
      await _open(tester, anchor: anchor, offsetY: 6);
      expect(tester.getRect(_card).top, closeTo(240 + 12 + 6, 0.01));
    });

    testWidgets('alignEnd aligns the right edges', (tester) async {
      await _pumpHost(tester);
      await _open(
        tester,
        anchor: const Rect.fromLTWH(300, 200, 40, 40),
        alignEnd: true,
      );
      expect(tester.getRect(_card).right, closeTo(340, 0.01));
    });

    testWidgets('flips above when it does not fit below', (tester) async {
      await _pumpHost(tester);
      await _open(tester, anchor: const Rect.fromLTWH(100, 730, 40, 40));
      final rect = tester.getRect(_card);
      expect(rect.bottom, closeTo(730 - 12, 0.01));
      expect(rect.top, lessThan(730));
    });

    testWidgets('offsetY is mirrored when flipped above', (tester) async {
      await _pumpHost(tester);
      await _open(
        tester,
        anchor: const Rect.fromLTWH(100, 730, 40, 40),
        offsetY: 6,
      );
      expect(tester.getRect(_card).bottom, closeTo(730 - 12 - 6, 0.01));
    });

    testWidgets('stays 8dp from the screen edges', (tester) async {
      await _pumpHost(tester);
      await _open(tester, anchor: const Rect.fromLTWH(0, 100, 20, 20));
      expect(tester.getRect(_card).left, closeTo(8, 0.01));
    });

    testWidgets('is pulled back from the right edge too', (tester) async {
      await _pumpHost(tester);
      await _open(tester, anchor: const Rect.fromLTWH(380, 100, 20, 20));
      expect(tester.getRect(_card).right, closeTo(400 - 8, 0.01));
    });

    testWidgets('alignEnd is clamped at the left edge', (tester) async {
      await _pumpHost(tester);
      await _open(
        tester,
        anchor: const Rect.fromLTWH(0, 100, 20, 20),
        alignEnd: true,
      );
      expect(tester.getRect(_card).left, closeTo(8, 0.01));
    });

    testWidgets('is clamped inside the screen even when neither side fits', (
      tester,
    ) async {
      await _pumpHost(tester, size: const Size(400, 120));
      await _open(tester, anchor: const Rect.fromLTWH(100, 40, 40, 40));
      final rect = tester.getRect(_card);
      expect(rect.top, greaterThanOrEqualTo(8));
      expect(rect.bottom, lessThanOrEqualTo(120 - 8));
    });
  });

  group('tall content', () {
    testWidgets(
      'a menu taller than the screen scrolls instead of overflowing',
      (tester) async {
        await _pumpHost(tester, size: const Size(400, 300));
        await _open(
          tester,
          anchor: const Rect.fromLTWH(100, 40, 40, 40),
          builder: (_) => _menu([for (var i = 0; i < 20; i++) 'Entry $i']),
        );
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(_card);
        expect(rect.top, greaterThanOrEqualTo(8));
        expect(rect.bottom, lessThanOrEqualTo(300 - 8));
        final position = tester
            .state<ScrollableState>(
              find.descendant(of: _card, matching: find.byType(Scrollable)),
            )
            .position;
        expect(position.maxScrollExtent, greaterThan(0));
        await tester.drag(find.text('Entry 2'), const Offset(0, -120));
        await tester.pump();
        expect(position.pixels, greaterThan(50));
      },
    );
  });

  group('size', () {
    testWidgets('is at least minWidth wide and hugs its content otherwise', (
      tester,
    ) async {
      await _pumpHost(tester);
      await _open(
        tester,
        anchor: const Rect.fromLTWH(20, 100, 20, 20),
        builder: (_) => _menu(const ['Hi']),
      );
      expect(tester.getSize(_card).width, 200);
    });

    testWidgets('honours custom min and max widths', (tester) async {
      await _pumpHost(tester);
      await _open(
        tester,
        anchor: const Rect.fromLTWH(20, 100, 20, 20),
        minWidth: 260,
        builder: (_) => _menu(const ['Hi']),
      );
      expect(tester.getSize(_card).width, 260);
      Navigator.of(_host, rootNavigator: true).pop();
      await tester.pumpAndSettle();

      await _open(
        tester,
        anchor: const Rect.fromLTWH(20, 100, 20, 20),
        minWidth: 100,
        maxWidth: 150,
        builder: (_) => _menu(const ['A rather long menu entry label']),
      );
      expect(tester.getSize(_card).width, 150);
    });

    testWidgets('grows with long content up to 320dp', (tester) async {
      await _pumpHost(tester);
      await _open(
        tester,
        anchor: const Rect.fromLTWH(20, 100, 20, 20),
        builder: (_) => _menu(const ['A menu entry label that is quite wide']),
      );
      final width = tester.getSize(_card).width;
      expect(width, greaterThan(200));
      expect(width, lessThanOrEqualTo(320));
      expect(tester.takeException(), isNull);
    });

    testWidgets('never exceeds the screen minus the 8dp margins', (
      tester,
    ) async {
      await _pumpHost(tester, size: const Size(240, 600));
      await _open(
        tester,
        anchor: const Rect.fromLTWH(20, 100, 20, 20),
        builder: (_) => _menu(const ['A menu entry label that is quite wide']),
      );
      expect(tester.getSize(_card).width, lessThanOrEqualTo(240 - 16));
    });
  });

  group('surface and scrim', () {
    testWidgets('card: radius 14, 1dp border, padding h8 v6', (tester) async {
      await _pumpHost(tester, brightness: Brightness.dark);
      await _open(tester, anchor: const Rect.fromLTWH(100, 100, 20, 20));
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: _card,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, SynkColors.dark.card);
      expect(decoration.borderRadius, BorderRadius.circular(14));
      expect(decoration.border, Border.all(color: SynkColors.dark.border));
      final padding = tester.widget<Padding>(
        find.descendant(of: _card, matching: find.byType(Padding)).first,
      );
      expect(
        padding.padding,
        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      );
    });

    testWidgets('the scrim is 20% black', (tester) async {
      await _pumpHost(tester);
      await _open(tester, anchor: const Rect.fromLTWH(100, 100, 20, 20));
      final barrier = tester.widget<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier),
      );
      expect(barrier.color.value, SynkPalette.popoverBackdrop);
      expect(barrier.color.value!.a, closeTo(0.2, 0.01));
    });

    testWidgets('glass has no scrim and a translucent blurred card', (
      tester,
    ) async {
      await _pumpHost(tester, brightness: Brightness.dark);
      await _open(
        tester,
        anchor: const Rect.fromLTWH(100, 100, 20, 20),
        glass: true,
      );
      expect(find.byType(AnimatedModalBarrier), findsNothing);
      expect(find.byType(BackdropFilter), findsOneWidget);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: _card,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, SynkColors.dark.glassOverlay);
    });

    testWidgets('a glass popover still dismisses on an outside tap', (
      tester,
    ) async {
      await _pumpHost(tester);
      final result = await _open(
        tester,
        anchor: const Rect.fromLTWH(100, 100, 20, 20),
        glass: true,
      );
      await tester.tapAt(const Offset(5, 700));
      await tester.pumpAndSettle();
      expect(_card, findsNothing);
      expect(result.done, isTrue);
    });
  });

  group('animation', () {
    testWidgets('opens in 70ms scaling from 0.97 and fading in', (
      tester,
    ) async {
      await _pumpHost(tester);
      unawaited(
        showSynkPopover<void>(
          _host,
          anchor: const Rect.fromLTWH(100, 100, 20, 20),
          builder: (_) => _menu(),
        ),
      );
      await tester.pump();
      double scale() {
        final box = tester.renderObject<RenderBox>(_card);
        final tl = box.localToGlobal(Offset.zero);
        final br = box.localToGlobal(box.size.bottomRight(Offset.zero));
        return (br.dx - tl.dx) / box.size.width;
      }

      double opacity() => tester
          .widget<Opacity>(
            find.ancestor(of: _card, matching: find.byType(Opacity)).first,
          )
          .opacity;
      expect(scale(), closeTo(0.97, 0.001));
      expect(opacity(), closeTo(0, 0.001));

      await tester.pump(const Duration(milliseconds: 25));
      expect(scale(), greaterThan(0.97));
      expect(scale(), lessThan(1));
      expect(opacity(), inExclusiveRange(0, 1));

      await tester.pump(const Duration(milliseconds: 50));
      expect(scale(), closeTo(1, 0.0001));
      expect(opacity(), closeTo(1, 0.0001));
    });

    testWidgets('closes in 50ms', (tester) async {
      await _pumpHost(tester);
      await _open(tester, anchor: const Rect.fromLTWH(100, 100, 20, 20));
      Navigator.of(_host, rootNavigator: true).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(_card, findsOneWidget, reason: 'still closing at 20ms');
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump();
      expect(_card, findsNothing);
    });
  });

  group('dismissal and results', () {
    testWidgets('an outside tap and Back dismiss', (tester) async {
      await _pumpHost(tester);
      var result = await _open(
        tester,
        anchor: const Rect.fromLTWH(100, 100, 20, 20),
      );
      await tester.tapAt(const Offset(350, 700));
      await tester.pumpAndSettle();
      expect(_card, findsNothing);
      expect(result.done, isTrue);
      expect(result.value, isNull);

      result = await _open(
        tester,
        anchor: const Rect.fromLTWH(100, 100, 20, 20),
      );
      await _pressBack(tester);
      await tester.pumpAndSettle();
      expect(_card, findsNothing);
      expect(result.done, isTrue);
    });

    testWidgets('tapping inside the card does not dismiss it', (tester) async {
      await _pumpHost(tester);
      final result = await _open(
        tester,
        anchor: const Rect.fromLTWH(100, 100, 20, 20),
      );
      await tester.tapAt(tester.getTopLeft(_card) + const Offset(40, 3));
      await tester.pumpAndSettle();
      expect(_card, findsOneWidget);
      expect(result.done, isFalse);
    });

    testWidgets('an item can pop the route with a value', (tester) async {
      await _pumpHost(tester);
      final result = await _open(
        tester,
        anchor: const Rect.fromLTWH(100, 100, 20, 20),
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopoverItem(
              label: 'Pick me',
              onTap: () => Navigator.of(context).pop('picked'),
            ),
          ],
        ),
      );
      await tester.tap(find.text('Pick me'));
      await tester.pumpAndSettle();
      expect(result.value, 'picked');
      expect(_card, findsNothing);
    });
  });

  group('PopoverItem', () {
    Future<void> pumpItem(
      WidgetTester tester,
      PopoverItem item, {
      Brightness brightness = Brightness.light,
    }) async {
      _useViewport(tester);
      await tester.pumpWidget(
        synkApp(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 240, child: item),
          ),
          brightness: brightness,
        ),
      );
    }

    TextStyle styleOf(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label)).style!;

    testWidgets('padding h14 v10, 15sp regular foreground text', (
      tester,
    ) async {
      await pumpItem(tester, PopoverItem(label: 'Edit', onTap: () {}));
      final style = styleOf(tester, 'Edit');
      expect(style.fontSize, 15);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, SynkColors.light.foreground);
      final text = tester.getRect(find.text('Edit'));
      final item = tester.getRect(find.byType(PopoverItem));
      expect(text.left - item.left, closeTo(14, 0.01));
      expect(text.top - item.top, closeTo(10, 0.01));
      expect(item.bottom - text.bottom, closeTo(10, 0.01));
    });

    testWidgets('selected is semibold and primary', (tester) async {
      await pumpItem(
        tester,
        PopoverItem(label: 'Newest', selected: true, onTap: () {}),
      );
      final style = styleOf(tester, 'Newest');
      expect(style.fontWeight, FontWeight.w600);
      expect(style.color, SynkColors.light.primaryText);
    });

    testWidgets('selected uses the brand pink in dark mode for contrast', (
      tester,
    ) async {
      await pumpItem(
        tester,
        PopoverItem(label: 'Newest', selected: true, onTap: () {}),
        brightness: Brightness.dark,
      );
      expect(styleOf(tester, 'Newest').color, SynkColors.dark.primaryText);
    });

    testWidgets('destructive uses the destructive colour', (tester) async {
      await pumpItem(
        tester,
        PopoverItem(label: 'Delete', destructive: true, onTap: () {}),
        brightness: Brightness.dark,
      );
      expect(styleOf(tester, 'Delete').color, SynkColors.dark.destructive);
    });

    testWidgets('shows a leading icon in the text colour', (tester) async {
      await pumpItem(
        tester,
        PopoverItem(
          label: 'Edit',
          icon: SynkIcons.pencil,
          selected: true,
          onTap: () {},
        ),
      );
      final icon = tester.widget<SynkIcon>(find.byType(SynkIcon));
      expect(icon.icon, SynkIcons.pencil);
      expect(icon.color, SynkColors.light.primaryText);
      expect(
        tester.getRect(find.byType(SynkIcon)).right,
        lessThan(tester.getRect(find.text('Edit')).left),
      );
    });

    testWidgets('tap fires the callback', (tester) async {
      var taps = 0;
      await pumpItem(tester, PopoverItem(label: 'Edit', onTap: () => taps++));
      await tester.tap(find.text('Edit'));
      expect(taps, 1);
    });

    testWidgets('pressing paints foreground at 8%', (tester) async {
      await pumpItem(tester, PopoverItem(label: 'Edit', onTap: () {}));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PopoverItem)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(
        inkWell.highlightColor,
        SynkColors.light.foreground.withValues(alpha: 0.08),
      );
      expect(
        inkWell.splashColor,
        SynkColors.light.foreground.withValues(alpha: 0.08),
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a null onTap renders disabled and ignores taps', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpItem(tester, const PopoverItem(label: 'Soon'));
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(of: find.text('Soon'), matching: find.byType(Opacity))
            .first,
      );
      expect(opacity.opacity, 0.5);
      expect(
        tester.getSemantics(find.byType(PopoverItem)),
        isSemantics(
          label: 'Soon',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('semantics: a selected button with its label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpItem(
        tester,
        PopoverItem(label: 'Newest', selected: true, onTap: () {}),
      );
      expect(
        tester.getSemantics(find.byType(PopoverItem)),
        isSemantics(
          label: 'Newest',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('long labels wrap or ellipsize instead of overflowing', (
      tester,
    ) async {
      await pumpItem(
        tester,
        PopoverItem(
          label:
              'An extremely long label that cannot possibly fit in the row '
              'without wrapping',
          onTap: () {},
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('golden', () {
    Widget card(Widget child, {bool glass = false, double width = 250}) =>
        SizedBox(
          width: width,
          child: SynkPopoverCard(glass: glass, child: child),
        );

    List<GoldenCell> cells() => [
      GoldenCell(
        'items: normal, selected, destructive',
        card(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopoverItem(label: 'Newest first', onTap: () {}),
              PopoverItem(label: 'Oldest first', selected: true, onTap: () {}),
              PopoverItem(label: 'Most watched', onTap: () {}),
              PopoverItem(
                label: 'Remove from group',
                destructive: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      GoldenCell(
        'with icons, disabled',
        card(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopoverItem(
                label: 'Rename',
                icon: SynkIcons.pencil,
                onTap: () {},
              ),
              PopoverItem(
                label: 'Invite a member',
                icon: SynkIcons.userPlus,
                selected: true,
                onTap: () {},
              ),
              const PopoverItem(label: 'Leaderboard', icon: SynkIcons.crown),
              PopoverItem(
                label: 'Leave group',
                icon: SynkIcons.signOut,
                destructive: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      GoldenCell(
        'min width 200 (single short item)',
        SizedBox(
          width: 200,
          child: SynkPopoverCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [PopoverItem(label: 'Copy link', onTap: () {})],
            ),
          ),
        ),
      ),
      GoldenCell(
        'glass over a colourful backdrop',
        Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFFF60669),
                      Color(0xFFF59E0B),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: card(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopoverItem(label: 'Playback speed', onTap: () {}),
                    PopoverItem(label: 'Quality', selected: true, onTap: () {}),
                  ],
                ),
                glass: true,
                width: 220,
              ),
            ),
          ],
        ),
      ),
    ];

    testWidgets('popover cards: items, icons, widths and glass', (
      tester,
    ) async {
      await _withRealShadows(
        () => expectStateSheetGolden(
          tester,
          'popover_cards',
          [
            for (final c in cells())
              GoldenCell(
                c.label,
                c.label.startsWith('glass')
                    ? SizedBox(width: 260, height: 150, child: c.child)
                    : c.child,
              ),
          ],
          size: const Size(300, 780),
          cellWidth: 268,
        ),
      );
    });

    testWidgets('popover cards at text scale 1.3', (tester) async {
      await _withRealShadows(
        () => expectStateSheetGolden(
          tester,
          'popover_cards_text_scale',
          cells().take(1).toList(),
          size: const Size(320, 330),
          cellWidth: 288,
          textScale: 1.3,
        ),
      );
    });
  });
}
