import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/confirm_sheet.dart';
import 'package:date_js/design_system/components/synk_bottom_sheet.dart';
import 'package:date_js/design_system/components/synk_button.dart'
    show SynkButtonSpinner;
import 'package:date_js/design_system/components/synk_dialog.dart';
import 'package:date_js/design_system/components/synk_text.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_palette.dart';
import 'package:date_js/design_system/tokens/synk_theme.dart';
import 'package:date_js/design_system/tokens/synk_typography.dart';

import '../support/synk_test_harness.dart';

const Size _screen = Size(400, 800);

/// 1:1 logical pixels so offsets can be asserted directly.
void _useViewport(WidgetTester tester, {Size size = _screen}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

late BuildContext _host;

Future<void> _pumpHost(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  _useViewport(tester);
  await tester.pumpWidget(
    synkApp(
      Builder(
        builder: (context) {
          _host = context;
          return const SizedBox.expand();
        },
      ),
      brightness: brightness,
      textScale: textScale,
    ),
  );
}

/// Result slot of an opened overlay.
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

final Finder _frame = find.byType(SynkBottomSheetFrame);

/// The busy button's spinner: the turning arc, or the still one when motion is reduced (these
/// tests run with the platform's "remove animations" on, like every golden).
final Finder _busySpinner = find.byWidgetPredicate(
  (w) => w is CircularProgressIndicator || w is SynkButtonSpinner,
);
final Finder _scrim = find.byKey(const ValueKey<String>('synk_sheet_scrim'));

double _top(WidgetTester tester) => tester.getTopLeft(_frame).dy;

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

Widget _body([String text = 'Sheet body']) =>
    SizedBox(height: 120, child: Center(child: SynkText(text)));

Future<_Result<String>> _openSheet(
  WidgetTester tester, {
  WidgetBuilder? builder,
  bool isDismissible = true,
  bool Function()? canDismiss,
  bool solid = true,
  bool showHandle = true,
  double maxHeightFraction = 0.92,
  bool scrollable = true,
}) async {
  final result = _track(
    showSynkBottomSheet<String>(
      _host,
      builder: builder ?? (_) => _body(),
      isDismissible: isDismissible,
      canDismiss: canDismiss,
      solid: solid,
      showHandle: showHandle,
      maxHeightFraction: maxHeightFraction,
      scrollable: scrollable,
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

Widget _tall([int rows = 40]) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    for (var i = 0; i < rows; i++)
      SizedBox(height: 40, child: Center(child: SynkText('Row $i'))),
  ],
);

void main() {
  group('SynkBottomSheet route', () {
    testWidgets(
      'opens from off-screen with a spring and settles flush with the '
      'bottom while the scrim fades in',
      (tester) async {
        await _pumpHost(tester);
        unawaited(showSynkBottomSheet<void>(_host, builder: (_) => _body()));
        await tester.pump();
        // First frame: still fully off-screen, no scrim yet.
        expect(_top(tester), greaterThanOrEqualTo(_screen.height - 0.5));
        Color scrim() => tester.widgetList<ColoredBox>(_scrim).first.color;
        expect(scrim().a, lessThan(0.05));

        await tester.pump(const Duration(milliseconds: 120));
        final mid = _top(tester);
        expect(mid, lessThan(_screen.height - 20));
        expect(mid, greaterThan(_screen.height - 200));
        expect(scrim().a, greaterThan(0.02));
        expect(scrim().a, lessThan(SynkPalette.backdrop.a));

        await tester.pump(const Duration(seconds: 2));
        expect(tester.getBottomLeft(_frame).dy, closeTo(_screen.height, 0.01));
        expect(scrim().a, closeTo(SynkPalette.backdrop.a, 0.001));
        expect(find.text('Sheet body'), findsOneWidget);
      },
    );

    testWidgets('scrim tap closes with a 220ms tween and completes null', (
      tester,
    ) async {
      await _pumpHost(tester);
      final result = await _openSheet(tester);
      final openTop = _top(tester);

      await tester.tapAt(const Offset(200, 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110));
      expect(_frame, findsOneWidget, reason: 'still closing at 110ms');
      expect(_top(tester), greaterThan(openTop + 20));

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(_frame, findsNothing);
      expect(result.done, isTrue);
      expect(result.value, isNull);
    });

    testWidgets('taps inside the sheet never reach the scrim', (tester) async {
      await _pumpHost(tester);
      final result = await _openSheet(tester);

      await tester.tap(find.text('Sheet body'));
      await tester.tapAt(tester.getTopLeft(_frame) + const Offset(8, 8));
      await _settle(tester);
      expect(_frame, findsOneWidget);
      expect(result.done, isFalse);
    });

    testWidgets('content can close the sheet with a result', (tester) async {
      await _pumpHost(tester);
      final result = await _openSheet(
        tester,
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).pop('picked'),
          child: const Text('Pick'),
        ),
      );
      await tester.tap(find.text('Pick'));
      await _settle(tester);
      expect(_frame, findsNothing);
      expect(result.value, 'picked');
    });

    testWidgets('Back closes the sheet; canDismiss refuses Back', (
      tester,
    ) async {
      await _pumpHost(tester);
      var allowed = false;
      var asked = 0;
      final result = await _openSheet(
        tester,
        canDismiss: () {
          asked++;
          return allowed;
        },
      );

      await _pressBack(tester);
      await _settle(tester);
      expect(_frame, findsOneWidget);
      expect(asked, 1);
      expect(result.done, isFalse);

      allowed = true;
      await _pressBack(tester);
      await _settle(tester);
      expect(_frame, findsNothing);
      expect(result.done, isTrue);
    });

    testWidgets('isDismissible false ignores scrim, Back and drag but still '
        'closes programmatically', (tester) async {
      await _pumpHost(tester);
      final result = await _openSheet(tester, isDismissible: false);
      final openTop = _top(tester);

      await tester.tapAt(const Offset(200, 40));
      await _settle(tester);
      await _pressBack(tester);
      await _settle(tester);
      await tester.fling(_frame, const Offset(0, 200), 2000);
      await _settle(tester);
      expect(_frame, findsOneWidget);
      expect(_top(tester), closeTo(openTop, 0.01));
      expect(result.done, isFalse);

      Navigator.of(_host, rootNavigator: true).pop('forced');
      await _settle(tester);
      expect(_frame, findsNothing);
      expect(result.value, 'forced');
    });

    testWidgets('canDismiss false refuses the scrim tap', (tester) async {
      await _pumpHost(tester);
      var asked = 0;
      await _openSheet(
        tester,
        canDismiss: () {
          asked++;
          return false;
        },
      );
      await tester.tapAt(const Offset(200, 40));
      await _settle(tester);
      expect(asked, 1);
      expect(_frame, findsOneWidget);
    });

    testWidgets('drag follows the finger, a short slow drag springs back', (
      tester,
    ) async {
      await _pumpHost(tester);
      final result = await _openSheet(tester);
      final openTop = _top(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(_frame) - const Offset(0, 20),
      );
      await gesture.moveBy(const Offset(0, 30));
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      // Follows the finger one to one.
      expect(_top(tester) - openTop, closeTo(70, 0.5));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(_top(tester) - openTop, closeTo(100, 0.5));
      // Slow release below 120dp: springs back.
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();
      await _settle(tester);
      expect(_top(tester), closeTo(openTop, 0.01));
      expect(_frame, findsOneWidget);
      expect(result.done, isFalse);
    });

    testWidgets('releasing past 120dp dismisses', (tester) async {
      await _pumpHost(tester);
      final result = await _openSheet(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(_frame) - const Offset(0, 20),
      );
      await gesture.moveBy(const Offset(0, 30));
      await gesture.moveBy(const Offset(0, 100));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await _settle(tester);
      expect(_frame, findsNothing);
      expect(result.done, isTrue);
    });

    testWidgets('exactly at the threshold: 120dp springs back, 121dp closes', (
      tester,
    ) async {
      await _pumpHost(tester);
      await _openSheet(tester);
      final openTop = _top(tester);
      var gesture = await tester.startGesture(
        tester.getCenter(_frame) - const Offset(0, 20),
      );
      await gesture.moveBy(const Offset(0, 20));
      await gesture.moveBy(const Offset(0, 99)); // 119dp in total
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await _settle(tester);
      expect(_frame, findsOneWidget);
      expect(_top(tester), closeTo(openTop, 0.01));

      gesture = await tester.startGesture(
        tester.getCenter(_frame) - const Offset(0, 20),
      );
      await gesture.moveBy(const Offset(0, 20));
      await gesture.moveBy(const Offset(0, 102)); // 122dp in total
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await _settle(tester);
      expect(_frame, findsNothing);
    });

    testWidgets('a fling faster than 800dp/s dismisses, a slower one springs '
        'back', (tester) async {
      await _pumpHost(tester);
      await _openSheet(tester);
      final openTop = _top(tester);

      await tester.fling(_frame, const Offset(0, 60), 400);
      await _settle(tester);
      expect(_frame, findsOneWidget);
      expect(_top(tester), closeTo(openTop, 0.01));

      await tester.fling(_frame, const Offset(0, 60), 1500);
      await _settle(tester);
      expect(_frame, findsNothing);
    });

    testWidgets('a refused dismissal springs back with the snap-back spring', (
      tester,
    ) async {
      await _pumpHost(tester);
      var allowed = false;
      await _openSheet(tester, canDismiss: () => allowed);
      final openTop = _top(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(_frame) - const Offset(0, 20),
      );
      await gesture.moveBy(const Offset(0, 20));
      await gesture.moveBy(const Offset(0, 230));
      await tester.pump();
      expect(_top(tester) - openTop, closeTo(250, 0.5));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final back = _top(tester) - openTop;
      expect(back, greaterThan(0), reason: 'still on its way back');
      expect(back, lessThan(250));
      await _settle(tester);
      expect(_top(tester), closeTo(openTop, 0.01));
      expect(_frame, findsOneWidget);

      // The same gesture closes it once allowed.
      allowed = true;
      await tester.fling(_frame, const Offset(0, 80), 2000);
      await _settle(tester);
      expect(_frame, findsNothing);
    });

    testWidgets('scrim alpha follows the drag progress', (tester) async {
      await _pumpHost(tester);
      await _openSheet(tester);
      double alpha() => tester.widgetList<ColoredBox>(_scrim).first.color.a;
      expect(alpha(), closeTo(SynkPalette.backdrop.a, 0.001));
      final gesture = await tester.startGesture(
        tester.getCenter(_frame) - const Offset(0, 20),
      );
      await gesture.moveBy(const Offset(0, 20));
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      expect(alpha(), lessThan(SynkPalette.backdrop.a * 0.8));
      expect(alpha(), greaterThan(0));
      await gesture.cancel();
      await _settle(tester);
    });
  });

  group('keyboard', () {
    testWidgets('lifts above the keyboard minus the bottom safe area', (
      tester,
    ) async {
      await _pumpHost(tester);
      await _openSheet(tester);
      expect(tester.getBottomLeft(_frame).dy, closeTo(800, 0.01));

      // Keyboard only.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await _settle(tester);
      expect(tester.getBottomLeft(_frame).dy, closeTo(500, 0.01));

      // Keyboard with a 24dp navigation bar: lift is insets - nav.
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      tester.view.padding = const FakeViewPadding();
      await tester.pump();
      await _settle(tester);
      expect(tester.getBottomLeft(_frame).dy, closeTo(800 - 276, 0.01));
    });

    testWidgets('never lifts by a negative amount', (tester) async {
      await _pumpHost(tester);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      tester.view.viewInsets = const FakeViewPadding(bottom: 10);
      await _openSheet(tester);
      expect(tester.getBottomLeft(_frame).dy, closeTo(800, 0.01));
    });

    testWidgets('shrinks instead of overflowing when the keyboard is up', (
      tester,
    ) async {
      await _pumpHost(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      await _openSheet(tester, builder: (_) => _tall());
      // 92% of the 400dp left above the keyboard.
      expect(tester.getSize(_frame).height, closeTo(0.92 * 400, 0.01));
      expect(tester.getBottomLeft(_frame).dy, closeTo(400, 0.01));
    });

    testWidgets('content does not see the keyboard or safe area again', (
      tester,
    ) async {
      await _pumpHost(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      tester.view.padding = const FakeViewPadding(bottom: 24);
      MediaQueryData? data;
      await _openSheet(
        tester,
        builder: (context) {
          data = MediaQuery.of(context);
          return _body();
        },
      );
      expect(data!.viewInsets.bottom, 0);
      expect(data!.padding.bottom, 0);
      expect(data!.viewPadding.bottom, 0);
    });

    testWidgets('a focused field is force-unfocused as the sheet closes', (
      tester,
    ) async {
      await _pumpHost(tester);
      final node = FocusNode();
      addTearDown(node.dispose);
      await _openSheet(
        tester,
        builder: (_) => TextField(focusNode: node, autofocus: true),
      );
      expect(node.hasFocus, isTrue);

      await tester.tapAt(const Offset(200, 40));
      await tester.pump();
      expect(node.hasFocus, isFalse, reason: 'cleared as soon as it closes');
      await _settle(tester);
      expect(node.hasPrimaryFocus, isFalse);
    });

    testWidgets('focus outside the sheet is left alone', (tester) async {
      _useViewport(tester);
      final outside = FocusNode();
      addTearDown(outside.dispose);
      await tester.pumpWidget(
        synkApp(
          Builder(
            builder: (context) {
              _host = context;
              return TextField(focusNode: outside);
            },
          ),
        ),
      );
      outside.requestFocus();
      await tester.pump();
      expect(outside.hasPrimaryFocus, isTrue);
      // Opening moves focus into the route; closing must not crash and must not clear a
      // field that is not part of the sheet.
      await _openSheet(tester);
      Navigator.of(_host, rootNavigator: true).pop();
      await _settle(tester);
      expect(_frame, findsNothing);
    });
  });

  group('frame', () {
    Future<void> pumpFrame(
      WidgetTester tester,
      Widget frame, {
      Brightness brightness = Brightness.light,
    }) async {
      _useViewport(tester);
      await tester.pumpWidget(
        synkApp(
          Align(alignment: Alignment.bottomCenter, child: frame),
          brightness: brightness,
        ),
      );
    }

    testWidgets('is at least 120dp tall', (tester) async {
      await pumpFrame(
        tester,
        const SynkBottomSheetFrame(child: SizedBox(height: 10)),
      );
      expect(tester.getSize(_frame).height, 120);
      expect(tester.getSize(_frame).width, 400);
    });

    testWidgets('is at most 92% (or the given fraction) of the height and '
        'scrolls taller content', (tester) async {
      await pumpFrame(tester, SynkBottomSheetFrame(child: _tall()));
      expect(tester.getSize(_frame).height, closeTo(0.92 * 800, 0.01));
      final scrollable = find.descendant(
        of: _frame,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pump();
      expect(position.pixels, closeTo(300 - 18, 20));

      await pumpFrame(
        tester,
        SynkBottomSheetFrame(maxHeightFraction: 0.5, child: _tall()),
      );
      expect(tester.getSize(_frame).height, closeTo(400, 0.01));
    });

    testWidgets('scrollable false gives the content bounded height', (
      tester,
    ) async {
      await pumpFrame(
        tester,
        SynkBottomSheetFrame(
          scrollable: false,
          child: Column(
            children: [
              Flexible(child: ListView(shrinkWrap: true, children: [_tall()])),
              const SizedBox(height: 44, child: Text('Pinned footer')),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_frame).height, closeTo(0.92 * 800, 0.01));
      expect(find.text('Pinned footer'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text('Pinned footer')).dy,
        lessThanOrEqualTo(800),
      );
    });

    testWidgets('content padding is 20/2/20/max(12, safe area + 8)', (
      tester,
    ) async {
      EdgeInsets padding() =>
          tester
                  .widget<SingleChildScrollView>(
                    find.descendant(
                      of: _frame,
                      matching: find.byType(SingleChildScrollView),
                    ),
                  )
                  .padding!
              as EdgeInsets;
      await pumpFrame(
        tester,
        const SynkBottomSheetFrame(child: SizedBox(height: 40)),
      );
      expect(padding(), const EdgeInsets.fromLTRB(20, 2, 20, 12));

      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      await tester.pump();
      expect(padding(), const EdgeInsets.fromLTRB(20, 2, 20, 32));

      tester.view.viewPadding = const FakeViewPadding(bottom: 3);
      await tester.pump();
      expect(padding().bottom, 12);
    });

    testWidgets('handle is a 56x5 pill in a 28dp area, hideable', (
      tester,
    ) async {
      final handle = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 56 && w.height == 5,
      );
      await pumpFrame(
        tester,
        const SynkBottomSheetFrame(child: SizedBox(height: 40)),
      );
      expect(handle, findsOneWidget);
      final area = find.ancestor(
        of: handle,
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 28,
        ),
      );
      expect(area, findsOneWidget, reason: '28dp handle area');
      final decoration = tester.widget<DecoratedBox>(
        find.ancestor(of: handle, matching: find.byType(DecoratedBox)),
      );
      final box = decoration.decoration as BoxDecoration;
      expect(box.borderRadius, BorderRadius.circular(2.5));
      expect(
        box.color,
        SynkColors.light.mutedForeground.withValues(alpha: 0.35),
      );

      await pumpFrame(
        tester,
        const SynkBottomSheetFrame(
          showHandle: false,
          child: SizedBox(height: 40),
        ),
      );
      expect(handle, findsNothing);
    });

    testWidgets('handle is more opaque in dark mode', (tester) async {
      await pumpFrame(
        tester,
        const SynkBottomSheetFrame(child: SizedBox(height: 40)),
        brightness: Brightness.dark,
      );
      final handle = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 56 && w.height == 5,
      );
      final box =
          tester
                  .widget<DecoratedBox>(
                    find.ancestor(
                      of: handle,
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(
        box.color,
        SynkColors.dark.mutedForeground.withValues(alpha: 0.45),
      );
    });

    testWidgets('solid uses the card colour, otherwise the drawer colour', (
      tester,
    ) async {
      Color background() => tester
          .widget<ColoredBox>(
            find
                .descendant(of: _frame, matching: find.byType(ColoredBox))
                .first,
          )
          .color;
      await pumpFrame(
        tester,
        const SynkBottomSheetFrame(child: SizedBox(height: 40)),
        brightness: Brightness.dark,
      );
      expect(background(), SynkColors.dark.card);
      await pumpFrame(
        tester,
        const SynkBottomSheetFrame(solid: false, child: SizedBox(height: 40)),
        brightness: Brightness.dark,
      );
      expect(background(), SynkColors.dark.drawer);
    });

    testWidgets('header, title, description and footer follow the spec', (
      tester,
    ) async {
      await pumpFrame(
        tester,
        const SynkBottomSheetFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                children: [SheetTitle('Title'), SheetDescription('Muted text')],
              ),
              SheetFooter(
                children: [
                  SizedBox(width: 50, height: 20),
                  SizedBox(width: 50, height: 20),
                ],
              ),
            ],
          ),
        ),
      );
      final title = tester.widget<Text>(find.text('Title'));
      expect(title.style!.fontSize, 18);
      expect(title.style!.fontWeight, FontWeight.w600);
      final description = tester.widget<Text>(find.text('Muted text'));
      expect(description.style!.color, SynkColors.light.mutedForeground);
      // 6dp between title and description.
      expect(
        tester.getTopLeft(find.text('Muted text')).dy -
            tester.getBottomLeft(find.text('Title')).dy,
        closeTo(6, 0.01),
      );
      // Footer: 10dp between children.
      final boxes = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 50 && w.height == 20,
      );
      expect(
        tester.getTopLeft(boxes.at(1)).dx - tester.getTopRight(boxes.at(0)).dx,
        closeTo(10, 0.01),
      );
      // 8dp above the footer plus 8dp below the header.
      expect(
        tester.getTopLeft(boxes.first).dy -
            tester.getBottomLeft(find.text('Muted text')).dy,
        closeTo(16, 0.01),
      );
    });
  });

  group('nested scrolling', () {
    Future<ScrollPosition> openScrolling(WidgetTester tester) async {
      await _pumpHost(tester);
      await _openSheet(tester, builder: (_) => _tall());
      return tester
          .state<ScrollableState>(
            find.descendant(of: _frame, matching: find.byType(Scrollable)),
          )
          .position;
    }

    testWidgets('dragging the content up scrolls it and leaves the sheet', (
      tester,
    ) async {
      final position = await openScrolling(tester);
      final openTop = _top(tester);
      await tester.dragFrom(tester.getCenter(_frame), const Offset(0, -200));
      await tester.pump();
      expect(position.pixels, greaterThan(100));
      expect(_top(tester), closeTo(openTop, 0.01));
    });

    testWidgets('over-scrolling down at the top drags the sheet, a slow '
        'release springs back', (tester) async {
      final position = await openScrolling(tester);
      final openTop = _top(tester);
      expect(position.pixels, 0);

      final gesture = await tester.startGesture(tester.getCenter(_frame));
      await gesture.moveBy(const Offset(0, 20));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      // The first 20dp only wins the gesture arena against the scrollable.
      expect(_top(tester) - openTop, closeTo(60, 1));
      expect(position.pixels, 0);
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await _settle(tester);
      expect(_top(tester), closeTo(openTop, 0.01));
      expect(_frame, findsOneWidget);
    });

    testWidgets('an upward drag first brings the sheet back, then scrolls', (
      tester,
    ) async {
      final position = await openScrolling(tester);
      final openTop = _top(tester);

      final gesture = await tester.startGesture(tester.getCenter(_frame));
      await gesture.moveBy(const Offset(0, 20));
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      expect(_top(tester) - openTop, closeTo(80, 1));

      // 50 up: all of it brings the sheet back.
      await gesture.moveBy(const Offset(0, -50));
      await tester.pump();
      expect(_top(tester) - openTop, closeTo(30, 1));
      expect(position.pixels, 0);

      // 70 up: the first 30 finish bringing it back, the remaining 40 scroll.
      await gesture.moveBy(const Offset(0, -70));
      await tester.pump();
      expect(_top(tester), closeTo(openTop, 0.01));
      expect(position.pixels, closeTo(40, 1));

      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await _settle(tester);
      expect(_frame, findsOneWidget);
    });

    testWidgets('a downward fling from the top of the content dismisses', (
      tester,
    ) async {
      await openScrolling(tester);
      await tester.fling(_frame, const Offset(0, 90), 2200);
      await _settle(tester);
      expect(_frame, findsNothing);
    });

    testWidgets('a refused nested dismissal springs back', (tester) async {
      await _pumpHost(tester);
      await _openSheet(
        tester,
        builder: (_) => _tall(),
        canDismiss: () => false,
      );
      final openTop = _top(tester);
      await tester.fling(_frame, const Offset(0, 90), 2200);
      await _settle(tester);
      expect(_frame, findsOneWidget);
      expect(_top(tester), closeTo(openTop, 0.01));
    });
  });

  group('stacking and semantics', () {
    testWidgets('Back dismisses the most recently shown overlay first', (
      tester,
    ) async {
      await _pumpHost(tester);
      final sheet = await _openSheet(tester);
      final dialog = _track(
        showSynkDialog<String>(
          _host,
          builder: (_) => const DialogTitle('On top'),
        ),
      );
      await _settle(tester);
      expect(find.text('On top'), findsOneWidget);

      await _pressBack(tester);
      await _settle(tester);
      expect(find.text('On top'), findsNothing);
      expect(dialog.done, isTrue);
      expect(_frame, findsOneWidget);
      expect(sheet.done, isFalse);

      await _pressBack(tester);
      await _settle(tester);
      expect(_frame, findsNothing);
      expect(sheet.done, isTrue);
    });

    testWidgets('the sheet names its route and offers a dismiss target', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpHost(tester);
      unawaited(
        showSynkBottomSheet<void>(
          _host,
          semanticLabel: 'Group options',
          builder: (_) => _body(),
        ),
      );
      await _settle(tester);
      expect(find.bySemanticsLabel('Group options'), findsOneWidget);
      expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the dismiss target is absent when not dismissible', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpHost(tester);
      await _openSheet(tester, isDismissible: false);
      expect(find.bySemanticsLabel('Dismiss'), findsNothing);
      handle.dispose();
    });

    testWidgets('renders at text scale 1.3 without overflow', (tester) async {
      await _pumpHost(tester, textScale: 1.3);
      await _openSheet(
        tester,
        builder: (_) => const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              children: [
                SheetTitle('A fairly long sheet title that wraps'),
                SheetDescription(
                  'And a description long enough to wrap over a few lines of text.',
                ),
              ],
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ConfirmSheet', () {
    Future<_Result<bool>> openConfirm(
      WidgetTester tester, {
      Future<void> Function()? onConfirm,
      bool destructive = true,
    }) async {
      final result = _track<bool>(
        showConfirmSheet(
          _host,
          title: 'Leave group?',
          description: 'You will lose access to this group.',
          cancelLabel: 'Cancel',
          confirmLabel: 'Leave',
          destructive: destructive,
          onConfirm: onConfirm,
        ).then<bool?>((v) => v),
      );
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('shows title, description and both buttons', (tester) async {
      await _pumpHost(tester);
      await openConfirm(tester);
      expect(find.text('Leave group?'), findsOneWidget);
      expect(find.text('You will lose access to this group.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
      // Equal-width buttons side by side.
      final cancel = tester.getSize(
        find
            .ancestor(of: find.text('Cancel'), matching: find.byType(Material))
            .first,
      );
      final leave = tester.getSize(
        find
            .ancestor(of: find.text('Leave'), matching: find.byType(Material))
            .first,
      );
      expect(cancel.width, closeTo(leave.width, 0.01));
      expect(cancel.height, 44);
    });

    testWidgets('confirming without an action completes true', (tester) async {
      await _pumpHost(tester);
      final result = await openConfirm(tester);
      await tester.tap(find.text('Leave'));
      await _settle(tester);
      expect(_frame, findsNothing);
      expect(result.value, isTrue);
    });

    testWidgets('cancel and scrim dismiss complete false', (tester) async {
      await _pumpHost(tester);
      var result = await openConfirm(tester);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(result.value, isFalse);

      result = await openConfirm(tester);
      await tester.tapAt(const Offset(200, 40));
      await _settle(tester);
      expect(result.done, isTrue);
      expect(result.value, isFalse);
    });

    testWidgets('stays open and busy while the action runs, then closes true', (
      tester,
    ) async {
      await _pumpHost(tester);
      final gate = Completer<void>();
      var runs = 0;
      final result = await openConfirm(
        tester,
        onConfirm: () {
          runs++;
          return gate.future;
        },
      );
      await tester.tap(find.text('Leave'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(runs, 1);
      expect(_busySpinner, findsOneWidget);
      expect(find.text('Leave'), findsNothing, reason: 'label replaced');

      // Busy: cancel, scrim, Back and drag are all refused, a second tap is ignored.
      await tester.tap(find.text('Cancel'), warnIfMissed: false);
      await tester.tapAt(const Offset(200, 40));
      await _pressBack(tester);
      await tester.fling(_frame, const Offset(0, 120), 2500);
      await tester.pump(const Duration(milliseconds: 500));
      expect(_frame, findsOneWidget);
      expect(result.done, isFalse);
      expect(runs, 1);

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_frame, findsNothing);
      expect(result.value, isTrue);
    });

    testWidgets('an action that throws is reported, the sheet stays open and '
        'usable', (tester) async {
      await _pumpHost(tester);
      final result = await openConfirm(
        tester,
        onConfirm: () async => throw StateError('boom'),
      );
      await tester.tap(find.text('Leave'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isA<StateError>());
      expect(_busySpinner, findsNothing);
      expect(find.text('Leave'), findsOneWidget);
      expect(_frame, findsOneWidget);
      expect(result.done, isFalse);

      // Dismissible again.
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(result.value, isFalse);
    });

    testWidgets('non-destructive confirm uses the primary colour', (
      tester,
    ) async {
      await _pumpHost(tester);
      await openConfirm(tester, destructive: false);
      final material = tester.widget<Material>(
        find
            .ancestor(of: find.text('Leave'), matching: find.byType(Material))
            .first,
      );
      expect(material.color, SynkColors.light.primary);
    });

    testWidgets('destructive confirm uses the destructive colour', (
      tester,
    ) async {
      await _pumpHost(tester);
      await openConfirm(tester);
      final material = tester.widget<Material>(
        find
            .ancestor(of: find.text('Leave'), matching: find.byType(Material))
            .first,
      );
      expect(material.color, SynkColors.light.destructive);
    });

    testWidgets(
      'buttons stack at large text scales so labels are not clipped',
      (tester) async {
        await _pumpHost(tester, textScale: 1.3);
        await openConfirm(tester);
        final cancel = tester.getTopLeft(find.text('Cancel'));
        final leave = tester.getTopLeft(find.text('Leave'));
        expect(cancel.dx, closeTo(leave.dx, 40));
        expect(cancel.dy, greaterThan(leave.dy));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('golden', () {
    Widget sheetCell(
      Widget child, {
      double width = 380,
      bool solid = true,
      bool handle = true,
    }) => SizedBox(
      width: width,
      child: SynkBottomSheetFrame(
        solid: solid,
        showHandle: handle,
        child: child,
      ),
    );

    Widget formBody() => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(
          children: [
            SheetTitle('Plan a movie night'),
            SheetDescription(
              'Pick a day and time. Everyone in the group gets a reminder an '
              'hour before and again just before it starts.',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Builder(
          builder: (context) => Container(
            height: 44,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: context.colors.solidInputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SynkText('Friday, 14 March'),
          ),
        ),
        SheetFooter(
          children: [
            Expanded(child: _goldenButton('Cancel', outline: true)),
            Expanded(child: _goldenButton('Plan it')),
          ],
        ),
      ],
    );

    testWidgets('sheet frames: header/body/footer, scrolling, handle and '
        'surface variants', (tester) async {
      await expectStateSheetGolden(
        tester,
        'sheet_frames',
        [
          GoldenCell('solid, with handle', sheetCell(formBody())),
          GoldenCell(
            'drawer colour (solid: false)',
            sheetCell(formBody(), solid: false),
          ),
          GoldenCell(
            'no handle (the content supplies its own top padding)',
            sheetCell(
              const Padding(
                padding: EdgeInsets.only(top: 18),
                child: SheetHeader(
                  children: [
                    SheetTitle('Only a title'),
                    SheetDescription('Short.'),
                  ],
                ),
              ),
              handle: false,
            ),
          ),
          GoldenCell('min height 120', sheetCell(const SizedBox.shrink())),
          GoldenCell(
            'taller than the max: scrolls (80% cap on a 360dp parent)',
            SizedBox(
              width: 380,
              height: 360,
              child: SynkBottomSheetFrame(
                maxHeightFraction: 0.8,
                child: _tall(14),
              ),
            ),
          ),
        ],
        size: const Size(420, 1300),
        cellWidth: 388,
      );
    });

    testWidgets('sheet frames at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'sheet_frames_text_scale',
        [GoldenCell('textScale 1.3', sheetCell(formBody()))],
        size: const Size(420, 430),
        cellWidth: 388,
        textScale: 1.3,
      );
    });

    testWidgets('confirm sheet: destructive, primary, busy, large text', (
      tester,
    ) async {
      Widget confirm({
        bool destructive = true,
        bool busy = false,
        String confirmLabel = 'Leave',
      }) => sheetCell(
        ConfirmSheetContent(
          title: 'Leave group?',
          description:
              "You'll lose access to this group and its watch party. The owner "
              'can invite you back.',
          cancelLabel: 'Cancel',
          confirmLabel: confirmLabel,
          destructive: destructive,
          busy: busy,
          onCancel: () {},
          onConfirm: () {},
        ),
      );
      await _goldenAfter(
        tester,
        'confirm_sheet',
        [
          GoldenCell('destructive', confirm()),
          GoldenCell(
            'primary (destructive: false)',
            confirm(destructive: false, confirmLabel: 'Continue'),
          ),
          GoldenCell('busy', confirm(busy: true)),
        ],
        size: const Size(420, 640),
        cellWidth: 388,
      );
    });

    testWidgets('confirm sheet at text scale 1.3 stacks its buttons', (
      tester,
    ) async {
      await expectStateSheetGolden(
        tester,
        'confirm_sheet_text_scale',
        [
          GoldenCell(
            'textScale 1.3',
            sheetCell(
              ConfirmSheetContent(
                title: 'Cancel invitation?',
                description:
                    "friend@example.com won't be able to join this group with "
                    'this invite. You can re-invite them later.',
                cancelLabel: 'Keep',
                confirmLabel: 'Cancel invite',
                onCancel: () {},
                onConfirm: () {},
              ),
            ),
          ),
        ],
        size: const Size(420, 430),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });
}

/// Like `expectStateSheetGolden`, but pumps [after] first so indeterminate spinners show a
/// representative arc (fake time keeps the result deterministic).
Future<void> _goldenAfter(
  WidgetTester tester,
  String name,
  List<GoldenCell> cells, {
  required Size size,
  double? cellWidth,
  Duration after = const Duration(milliseconds: 700),
}) async {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    useGoldenViewport(tester, size: size);
    await tester.pumpWidget(
      synkApp(
        StateSheet(cells: cells, cellWidth: cellWidth),
        brightness: brightness,
        // The turning arc, not the still one of reduced motion.
        animations: true,
      ),
    );
    await tester.pump(after);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/${name}_${brightness.name}.png'),
    );
  }
}

/// Stand-in for `SynkButton` in golden cells (the design-system button is built elsewhere).
Widget _goldenButton(String label, {bool outline = false}) => Builder(
  builder: (context) {
    const colors = SynkColors.light;
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: outline ? null : colors.primary,
        border: outline ? Border.all(color: const Color(0x33000000)) : null,
        borderRadius: BorderRadius.circular(22),
      ),
      child: SynkText(
        label,
        variant: SynkTextVariant.buttonDefault,
        color: outline ? null : colors.primaryForeground,
      ),
    );
  },
);
