import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/synk_bottom_sheet.dart';
import 'package:date_js/design_system/components/toast.dart';
import 'package:date_js/design_system/foundation/synk_haptics.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_motion.dart';
import 'package:date_js/design_system/tokens/synk_palette.dart';
import 'package:date_js/design_system/tokens/synk_theme.dart';

import '../support/synk_test_harness.dart';

const Size _screen = Size(400, 800);

void _useViewport(WidgetTester tester, {Size size = _screen}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// A MaterialApp with the ToastHost in `builder`, exactly how the app mounts it.
Widget _app(
  ToastController controller, {
  Widget? home,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) {
  return SynkHapticsScope(
    player: const NoopHaptics(),
    child: MaterialApp(
      key: ValueKey<Brightness>(brightness),
      debugShowCheckedModeBanner: false,
      theme: SynkThemeData.light,
      darkTheme: SynkThemeData.dark,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: ToastHost(controller: controller, child: child!),
      ),
      home: home ?? const Scaffold(body: SizedBox.expand()),
    ),
  );
}

Future<ToastController> _pumpApp(
  WidgetTester tester, {
  Duration life = SynkMotion.toastLife,
  int maxVisible = 3,
  Size size = _screen,
  Widget? home,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  _useViewport(tester, size: size);
  final controller = ToastController(life: life, maxVisible: maxVisible);
  await tester.pumpWidget(
    _app(controller, home: home, brightness: brightness, textScale: textScale),
  );
  return controller;
}

/// Unmounts the app and disposes the controller (cancelling pending timers) before the test
/// framework checks for leftovers.
Future<void> _finish(WidgetTester tester, ToastController controller) async {
  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
}

Finder _card(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ToastCard));

Rect _rect(WidgetTester tester, String title) => tester.getRect(_card(title));

double _opacity(WidgetTester tester, String title) => tester
    .widget<Opacity>(
      find.ancestor(of: _card(title), matching: find.byType(Opacity)).first,
    )
    .opacity;

/// Settles the 220ms enter animation.
Future<void> _showAndSettle(
  WidgetTester tester,
  ToastController controller,
  String title, {
  String? description,
  ToastVariant variant = ToastVariant.defaultVariant,
}) async {
  controller.show(title, description: description, variant: variant);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// A flick with controlled timing (`tester.fling` yields no velocity for very short drags).
Future<void> _flick(
  WidgetTester tester,
  Finder target,
  double dy,
  Duration total,
) async {
  final gesture = await tester.startGesture(tester.getCenter(target));
  const steps = 5;
  for (var i = 1; i <= steps; i++) {
    await gesture.moveBy(Offset(0, dy / steps), timeStamp: total * i ~/ steps);
  }
  await gesture.up(timeStamp: total);
}

double _iconScale(WidgetTester tester, Finder icon) {
  final box = tester.renderObject<RenderBox>(icon);
  final tl = box.localToGlobal(Offset.zero);
  final br = box.localToGlobal(box.size.bottomRight(Offset.zero));
  return (br.dx - tl.dx) / box.size.width;
}

void main() {
  group('ToastController', () {
    testWidgets('show, error and success queue messages oldest first', (
      tester,
    ) async {
      final c = await _pumpApp(tester);
      c.show('One', description: 'first');
      c.error('Two', 'bad');
      c.success('Three');
      expect(c.visible.map((m) => m.title), ['One', 'Two', 'Three']);
      expect(c.visible.map((m) => m.variant), [
        ToastVariant.defaultVariant,
        ToastVariant.destructive,
        ToastVariant.success,
      ]);
      expect(c.visible.map((m) => m.description), ['first', 'bad', null]);
      expect(c.visible.map((m) => m.id).toSet(), hasLength(3));
      await _finish(tester, c);
    });

    testWidgets('an identical title and description is dropped', (
      tester,
    ) async {
      final c = await _pumpApp(tester);
      c.show('Saved', description: 'ok');
      c.show('Saved', description: 'ok');
      c.error('Saved', 'ok'); // same text, other variant: still a duplicate
      expect(c.visible, hasLength(1));
      c.show('Saved');
      c.show('Saved', description: 'different');
      c.show('Other', description: 'ok');
      expect(c.visible, hasLength(3));
      await _finish(tester, c);
    });

    testWidgets('a duplicate can be shown again after it was dismissed', (
      tester,
    ) async {
      final c = await _pumpApp(tester);
      c.show('Saved');
      c.dismiss(c.visible.single.id);
      expect(c.visible, isEmpty);
      c.show('Saved');
      expect(c.visible, hasLength(1));
      await _finish(tester, c);
    });

    testWidgets('a dropped duplicate does not reset the timer', (tester) async {
      final c = await _pumpApp(tester);
      c.show('Saved');
      await tester.pump(const Duration(milliseconds: 2000));
      c.show('Saved');
      await tester.pump(const Duration(milliseconds: 999));
      expect(c.visible, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(c.visible, isEmpty);
      await _finish(tester, c);
    });

    testWidgets('at most three stay: the oldest is evicted', (tester) async {
      final c = await _pumpApp(tester);
      for (final t in ['a', 'b', 'c', 'd']) {
        c.show(t);
      }
      expect(c.visible.map((m) => m.title), ['b', 'c', 'd']);
      c.show('e');
      expect(c.visible.map((m) => m.title), ['c', 'd', 'e']);
      await _finish(tester, c);
    });

    testWidgets('maxVisible is configurable', (tester) async {
      final c = await _pumpApp(tester, maxVisible: 1);
      c.show('a');
      c.show('b');
      expect(c.visible.map((m) => m.title), ['b']);
      await _finish(tester, c);
    });

    testWidgets('dismisses itself after exactly the life time', (tester) async {
      final c = await _pumpApp(tester);
      c.show('Hello');
      await tester.pump(const Duration(milliseconds: 2999));
      expect(c.visible, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(c.visible, isEmpty);
      await _finish(tester, c);
    });

    testWidgets('every toast has its own timer; an evicted one never fires '
        'again', (tester) async {
      final c = await _pumpApp(tester, life: const Duration(seconds: 3));
      c.show('first');
      await tester.pump(const Duration(seconds: 1));
      c.show('second');
      await tester.pump(const Duration(seconds: 1));
      c.show('third');
      c.show('fourth'); // evicts "first" and cancels its timer
      expect(c.visible.map((m) => m.title), ['second', 'third', 'fourth']);
      // t=3s: "first" would have expired now, but it was evicted and its timer cancelled.
      await tester.pump(const Duration(seconds: 1));
      expect(c.visible.map((m) => m.title), ['second', 'third', 'fourth']);
      // t=4s: "second" expires on its own schedule.
      await tester.pump(const Duration(seconds: 1));
      expect(c.visible.map((m) => m.title), ['third', 'fourth']);
      // t=5s: "third" and "fourth" were both shown at t=2s.
      await tester.pump(const Duration(seconds: 1));
      expect(c.visible, isEmpty);
      await _finish(tester, c);
    });

    testWidgets('the life time is configurable', (tester) async {
      final c = await _pumpApp(tester, life: const Duration(seconds: 10));
      c.show('slow');
      await tester.pump(const Duration(seconds: 9));
      expect(c.visible, hasLength(1));
      await tester.pump(const Duration(seconds: 1));
      expect(c.visible, isEmpty);
      await _finish(tester, c);
    });

    testWidgets('dismiss removes one message, ignores unknown ids and only '
        'notifies on change', (tester) async {
      final c = await _pumpApp(tester);
      var notified = 0;
      c.addListener(() => notified++);
      c.show('a');
      c.show('b');
      expect(notified, 2);
      c.dismiss(9999);
      expect(notified, 2);
      c.dismiss(c.visible.first.id);
      expect(notified, 3);
      expect(c.visible.map((m) => m.title), ['b']);
      c.show('b'); // duplicate: no notification
      expect(notified, 3);
      await _finish(tester, c);
    });

    testWidgets('visible cannot be modified from outside', (tester) async {
      final c = await _pumpApp(tester);
      c.show('a');
      expect(() => c.visible.clear(), throwsUnsupportedError);
      await _finish(tester, c);
    });

    testWidgets('dispose cancels the pending timers', (tester) async {
      final c = ToastController();
      c.show('a');
      c.show('b');
      c.dispose();
      // testWidgets fails the test when a timer is still pending afterwards.
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('ToastScope', () {
    testWidgets('context.toast reaches the controller without subscribing', (
      tester,
    ) async {
      var builds = 0;
      late ToastController found;
      final c = await _pumpApp(
        tester,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              builds++;
              found = context.toast;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      expect(found, same(c));
      final before = builds;
      c.show('Hello');
      await tester.pump();
      expect(builds, before, reason: 'no rebuild per toast');
      await _finish(tester, c);
    });

    testWidgets('of asserts without a host, maybeOf returns null', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      expect(ToastScope.maybeOf(context), isNull);
      expect(() => ToastScope.of(context), throwsFlutterError);
    });
  });

  group('ToastHost layout', () {
    testWidgets('top padding is max(12, status bar + 8) and the sides are 16', (
      tester,
    ) async {
      final c = await _pumpApp(tester, size: const Size(360, 800));
      await _showAndSettle(tester, c, 'Hello');
      final rect = _rect(tester, 'Hello');
      expect(rect.top, closeTo(12, 0.01));
      expect(rect.left, closeTo(16, 0.01));
      expect(rect.right, closeTo(360 - 16, 0.01));
      await _finish(tester, c);
    });

    testWidgets('clears the status bar by 8dp', (tester) async {
      _useViewport(tester);
      tester.view.padding = const FakeViewPadding(top: 40);
      tester.view.viewPadding = const FakeViewPadding(top: 40);
      final c = ToastController();
      await tester.pumpWidget(_app(c));
      await _showAndSettle(tester, c, 'Hello');
      expect(_rect(tester, 'Hello').top, closeTo(48, 0.01));
      await _finish(tester, c);
    });

    testWidgets('a small status bar still leaves 12dp', (tester) async {
      _useViewport(tester);
      tester.view.padding = const FakeViewPadding(top: 2);
      tester.view.viewPadding = const FakeViewPadding(top: 2);
      final c = ToastController();
      await tester.pumpWidget(_app(c));
      await _showAndSettle(tester, c, 'Hello');
      expect(_rect(tester, 'Hello').top, closeTo(12, 0.01));
      await _finish(tester, c);
    });

    testWidgets('toasts are centred and at most 400 wide', (tester) async {
      final c = await _pumpApp(tester, size: const Size(900, 800));
      await _showAndSettle(tester, c, 'Hello');
      final rect = _rect(tester, 'Hello');
      expect(rect.width, 400);
      expect(rect.center.dx, closeTo(450, 0.01));
      await _finish(tester, c);
    });

    testWidgets('toasts are stacked with an 8dp gap, oldest on top', (
      tester,
    ) async {
      final c = await _pumpApp(tester);
      await _showAndSettle(tester, c, 'First');
      await _showAndSettle(tester, c, 'Second');
      await _showAndSettle(tester, c, 'Third');
      final first = _rect(tester, 'First');
      final second = _rect(tester, 'Second');
      final third = _rect(tester, 'Third');
      expect(second.top - first.bottom, closeTo(8, 0.01));
      expect(third.top - second.bottom, closeTo(8, 0.01));
      await _finish(tester, c);
    });

    testWidgets('empty areas let touches through to the app below', (
      tester,
    ) async {
      var taps = 0;
      final c = await _pumpApp(
        tester,
        home: Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await _showAndSettle(tester, c, 'Hello');
      // Side gutter next to the toast, and below it.
      await tester.tapAt(const Offset(6, 30));
      await tester.tapAt(const Offset(200, 400));
      expect(taps, 2);
      // On the toast itself the app does not get the tap.
      await tester.tap(find.text('Hello'));
      expect(taps, 2);
      await _finish(tester, c);
    });

    testWidgets('toasts are drawn above an open bottom sheet', (tester) async {
      late BuildContext context;
      final c = await _pumpApp(
        tester,
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      unawaited(
        showSynkBottomSheet<void>(
          context,
          builder: (_) => const SizedBox(height: 300, child: Text('sheet')),
        ),
      );
      await tester.pumpAndSettle();
      await _showAndSettle(tester, c, 'Over the sheet');
      // The toast sits above the modal sheet: its close button still takes the tap.
      final close = find
          .descendant(
            of: _card('Over the sheet'),
            matching: find.byType(SynkIcon),
          )
          .last;
      await tester.tap(close);
      await tester.pump();
      expect(c.visible, isEmpty);
      expect(find.text('sheet'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await _finish(tester, c);
    });
  });

  group('ToastHost animation', () {
    testWidgets('slides in from 160dp above over 220ms', (tester) async {
      final c = await _pumpApp(tester);
      c.show('Hello');
      await tester.pump();
      expect(_rect(tester, 'Hello').top, closeTo(12 - 160, 0.5));
      expect(_opacity(tester, 'Hello'), closeTo(0, 0.01));

      await tester.pump(const Duration(milliseconds: 110));
      final mid = _rect(tester, 'Hello').top;
      expect(mid, greaterThan(12 - 160));
      expect(mid, lessThan(12));
      expect(_opacity(tester, 'Hello'), inExclusiveRange(0, 1));

      await tester.pump(const Duration(milliseconds: 120));
      expect(_rect(tester, 'Hello').top, closeTo(12, 0.01));
      expect(_opacity(tester, 'Hello'), closeTo(1, 0.001));
      await _finish(tester, c);
    });

    testWidgets('fades out over 180ms and is then removed', (tester) async {
      final c = await _pumpApp(tester);
      await _showAndSettle(tester, c, 'Hello');
      c.dismiss(c.visible.single.id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(find.text('Hello'), findsOneWidget);
      final alpha = _opacity(tester, 'Hello');
      expect(alpha, inExclusiveRange(0, 1));
      // A plain fade: it stays where it was.
      expect(_rect(tester, 'Hello').top, closeTo(12, 0.01));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hello'), findsNothing);
      await _finish(tester, c);
    });

    testWidgets('auto-dismiss through the host removes the card after the '
        'fade', (tester) async {
      final c = await _pumpApp(tester);
      c.show('Hello');
      await tester.pump(const Duration(milliseconds: 2900));
      expect(find.text('Hello'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hello'), findsOneWidget, reason: 'still fading');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hello'), findsNothing);
      await _finish(tester, c);
    });

    testWidgets('an evicted toast fades out while the others glide up', (
      tester,
    ) async {
      final c = await _pumpApp(tester, life: const Duration(hours: 1));
      for (final t in ['a', 'b', 'c']) {
        await _showAndSettle(tester, c, t);
      }
      final bBefore = _rect(tester, 'b');
      expect(bBefore.top, greaterThan(12 + 20));
      c.show('d');
      await tester.pump();
      expect(c.visible.map((m) => m.title), ['b', 'c', 'd']);
      expect(find.text('a'), findsOneWidget, reason: 'fading out');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('a'), findsNothing);
      expect(_rect(tester, 'b').top, closeTo(12, 0.01));
      await _finish(tester, c);
    });

    testWidgets('a duplicate does not animate a second card in', (
      tester,
    ) async {
      final c = await _pumpApp(tester);
      await _showAndSettle(tester, c, 'Same');
      c.show('Same');
      await tester.pump();
      expect(find.text('Same'), findsOneWidget);
      await _finish(tester, c);
    });
  });

  group('ToastCard', () {
    Future<void> pumpCard(
      WidgetTester tester,
      ToastMessage message, {
      Brightness brightness = Brightness.light,
      VoidCallback? onClose,
      double textScale = 1,
      bool animateIcon = true,
    }) async {
      _useViewport(tester);
      await tester.pumpWidget(
        synkApp(
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ToastCard(
                message: message,
                onClose: onClose,
                animateIcon: animateIcon,
              ),
            ),
          ),
          brightness: brightness,
          textScale: textScale,
        ),
      );
    }

    Color tileColor(WidgetTester tester) {
      final decoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(ToastCard),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.shape == BoxShape.circle);
      return decoration.color!;
    }

    SynkIcon mainIcon(WidgetTester tester) => tester
        .widgetList<SynkIcon>(find.byType(SynkIcon))
        .firstWhere((i) => i.icon != SynkIcons.close);

    const message = ToastMessage(id: 1, title: 'Title', description: 'Details');

    testWidgets('default: info icon in primary on a primary 0x15 tile', (
      tester,
    ) async {
      await pumpCard(tester, message);
      final icon = mainIcon(tester);
      expect(icon.icon, SynkIcons.info);
      expect(icon.color, SynkColors.light.primary);
      expect(
        tileColor(tester),
        SynkColors.light.primary.withValues(alpha: 0x15 / 255),
      );
      expect(
        tester.getSize(
          find
              .ancestor(
                of: find.byType(SynkIcon).first,
                matching: find.byType(SizedBox),
              )
              .first,
        ),
        const Size(32, 32),
      );
    });

    testWidgets('destructive: alert icon in the destructive colour', (
      tester,
    ) async {
      await pumpCard(
        tester,
        const ToastMessage(
          id: 1,
          title: 'Title',
          variant: ToastVariant.destructive,
        ),
        brightness: Brightness.dark,
      );
      final icon = mainIcon(tester);
      expect(icon.icon, SynkIcons.alert);
      expect(icon.color, SynkColors.dark.destructive);
      expect(
        tileColor(tester),
        SynkColors.dark.destructive.withValues(alpha: 0x15 / 255),
      );
    });

    testWidgets('success: check icon in the success colour', (tester) async {
      await pumpCard(
        tester,
        const ToastMessage(
          id: 1,
          title: 'Title',
          variant: ToastVariant.success,
        ),
      );
      final icon = mainIcon(tester);
      expect(icon.icon, SynkIcons.check);
      expect(icon.color, SynkPalette.success);
      expect(
        tileColor(tester),
        SynkPalette.success.withValues(alpha: 0x15 / 255),
      );
    });

    testWidgets('dark default icon uses a legible pink', (tester) async {
      await pumpCard(tester, message, brightness: Brightness.dark);
      expect(mainIcon(tester).color, SynkColors.dark.primaryText);
    });

    testWidgets('card: radius 14, card colour, 1dp border, 4dp-style shadow', (
      tester,
    ) async {
      await pumpCard(tester, message, brightness: Brightness.dark);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(ToastCard),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, SynkColors.dark.card);
      expect(decoration.borderRadius, BorderRadius.circular(14));
      expect(decoration.border, Border.all(color: SynkColors.dark.border));
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('title and description use the toast styles', (tester) async {
      await pumpCard(tester, message);
      final title = tester.widget<Text>(find.text('Title')).style!;
      expect(title.fontSize, 14);
      expect(title.fontWeight, FontWeight.w600);
      expect(title.color, SynkColors.light.foreground);
      final description = tester.widget<Text>(find.text('Details')).style!;
      expect(description.fontSize, 13);
      expect(description.color, SynkColors.light.mutedForeground);
    });

    testWidgets('padding 12 and a 12dp gap between tile, text and close', (
      tester,
    ) async {
      await pumpCard(tester, message);
      final card = tester.getRect(find.byType(ToastCard));
      final tile = tester.getRect(
        find
            .ancestor(
              of: find.byType(SynkIcon).first,
              matching: find.byType(SizedBox),
            )
            .first,
      );
      final title = tester.getRect(find.text('Title'));
      expect(tile.left - card.left, closeTo(12 + 1, 1.01)); // 1dp border
      expect(title.left - tile.right, closeTo(12, 0.01));
      final close = tester.getRect(find.byType(SynkIcon).last);
      // 16dp icon centred in a 24dp button with 12dp padding from the edge.
      expect(close.width, 16);
      expect(card.right - close.right, closeTo(12 + 4, 1.01));
    });

    testWidgets('the close button calls onClose, from a wide hit area', (
      tester,
    ) async {
      var closed = 0;
      await pumpCard(tester, message, onClose: () => closed++);
      await tester.tap(find.byType(SynkIcon).last);
      expect(closed, 1);
      // 6dp inside the card's right edge is still on the button.
      final card = tester.getRect(find.byType(ToastCard));
      await tester.tapAt(Offset(card.right - 8, card.center.dy));
      expect(closed, 2);
      // The text area is not a button.
      await tester.tap(find.text('Title'));
      expect(closed, 2);
    });

    testWidgets('long text is limited and does not overflow', (tester) async {
      await pumpCard(
        tester,
        ToastMessage(
          id: 1,
          title: 'A very long title ' * 20,
          description: 'An even longer description of what went wrong ' * 20,
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byType(ToastCard)).height, lessThan(400));
    });

    testWidgets('announces itself as a live region with the variant', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCard(
        tester,
        const ToastMessage(
          id: 1,
          title: 'Could not save',
          description: 'Check your connection',
          variant: ToastVariant.destructive,
        ),
        onClose: () {},
      );
      expect(
        tester.getSemantics(find.text('Could not save')),
        isSemantics(
          label: 'Error. Could not save. Check your connection',
          isLiveRegion: true,
        ),
      );
      expect(
        tester.getSemantics(find.byType(SynkIcon).last),
        isSemantics(label: 'Dismiss notification', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('a default toast announces just its text', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester, message);
      expect(
        tester.getSemantics(find.text('Title')),
        isSemantics(label: 'Title. Details', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('success icon pops: 1 to 1.18 in 110ms, then springs back', (
      tester,
    ) async {
      await pumpCard(
        tester,
        const ToastMessage(id: 1, title: 'Done', variant: ToastVariant.success),
      );
      final icon = find.byType(SynkIcon).first;
      expect(_iconScale(tester, icon), closeTo(1, 0.001));
      await tester.pump(const Duration(milliseconds: 55));
      final rising = _iconScale(tester, icon);
      expect(rising, greaterThan(1.02));
      expect(rising, lessThan(1.18));
      await tester.pump(const Duration(milliseconds: 55));
      expect(_iconScale(tester, icon), closeTo(1.18, 0.01));
      // The spring takes over one frame after the tween ends.
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_iconScale(tester, icon), lessThan(1.17));
      await tester.pump(const Duration(seconds: 2));
      expect(_iconScale(tester, icon), closeTo(1, 0.002));
    });

    testWidgets('only the success icon pops, and animateIcon can disable it', (
      tester,
    ) async {
      await pumpCard(tester, message);
      await tester.pump(const Duration(milliseconds: 110));
      expect(_iconScale(tester, find.byType(SynkIcon).first), 1);

      await pumpCard(
        tester,
        const ToastMessage(id: 1, title: 'Done', variant: ToastVariant.success),
        animateIcon: false,
      );
      await tester.pump(const Duration(milliseconds: 110));
      expect(_iconScale(tester, find.byType(SynkIcon).first), 1);
    });
  });

  group('ToastHost interaction', () {
    testWidgets('the close button dismisses the toast', (tester) async {
      final c = await _pumpApp(tester);
      await _showAndSettle(tester, c, 'Hello');
      final close = find
          .descendant(of: _card('Hello'), matching: find.byType(SynkIcon))
          .last;
      await tester.tap(close);
      await tester.pump();
      expect(c.visible, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Hello'), findsNothing);
      await _finish(tester, c);
    });

    testWidgets('swiping up past 40dp dismisses and slides it away', (
      tester,
    ) async {
      final c = await _pumpApp(tester, life: const Duration(hours: 1));
      await _showAndSettle(tester, c, 'Hello');
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hello')),
      );
      await gesture.moveBy(const Offset(0, -25));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();
      expect(c.visible, isEmpty);
      final released = _rect(tester, 'Hello').top;
      await tester.pump(const Duration(milliseconds: 90));
      expect(
        _rect(tester, 'Hello').top,
        lessThan(released),
        reason: 'slides up',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hello'), findsNothing);
      await _finish(tester, c);
    });

    testWidgets('a short slow swipe snaps back', (tester) async {
      final c = await _pumpApp(tester, life: const Duration(hours: 1));
      await _showAndSettle(tester, c, 'Hello');
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hello')),
      );
      await gesture.moveBy(const Offset(0, -15));
      await gesture.moveBy(const Offset(0, -15));
      await tester.pump();
      expect(_rect(tester, 'Hello').top, closeTo(12 - 30, 0.5));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(c.visible, hasLength(1));
      expect(_rect(tester, 'Hello').top, closeTo(12, 0.05));
      await _finish(tester, c);
    });

    testWidgets('a fast flick up dismisses even over a short distance', (
      tester,
    ) async {
      final c = await _pumpApp(tester, life: const Duration(hours: 1));
      await _showAndSettle(tester, c, 'Hello');
      // 25dp in 30ms is about 830dp/s: past the velocity rule, short of the distance rule.
      await _flick(
        tester,
        find.text('Hello'),
        -25,
        const Duration(milliseconds: 30),
      );
      await tester.pump();
      expect(c.visible, isEmpty);
      await tester.pump(const Duration(milliseconds: 300));
      await _finish(tester, c);
    });

    testWidgets('a slow flick below 600dp/s does not dismiss', (tester) async {
      final c = await _pumpApp(tester, life: const Duration(hours: 1));
      await _showAndSettle(tester, c, 'Hello');
      await _flick(
        tester,
        find.text('Hello'),
        -25,
        const Duration(milliseconds: 250),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(c.visible, hasLength(1));
      await _finish(tester, c);
    });

    testWidgets('downward drags are damped by 0.2 and snap back', (
      tester,
    ) async {
      final c = await _pumpApp(tester, life: const Duration(hours: 1));
      await _showAndSettle(tester, c, 'Hello');
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hello')),
      );
      await gesture.moveBy(const Offset(0, 50));
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();
      expect(_rect(tester, 'Hello').top, closeTo(12 + 20, 0.5));
      expect(_opacity(tester, 'Hello'), 1, reason: 'downward does not fade');
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(c.visible, hasLength(1));
      expect(_rect(tester, 'Hello').top, closeTo(12, 0.05));
      await _finish(tester, c);
    });

    testWidgets('alpha fades with 1 + drag / 120', (tester) async {
      final c = await _pumpApp(tester, life: const Duration(hours: 1));
      await _showAndSettle(tester, c, 'Hello');
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hello')),
      );
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      expect(_opacity(tester, 'Hello'), closeTo(0.75, 0.01));
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      expect(_opacity(tester, 'Hello'), closeTo(0.5, 0.01));
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      expect(_opacity(tester, 'Hello'), 0);
      await gesture.cancel();
      await tester.pump(const Duration(seconds: 1));
      await _finish(tester, c);
    });

    testWidgets('only the swiped toast leaves; the others stay and move up', (
      tester,
    ) async {
      final c = await _pumpApp(tester, life: const Duration(hours: 1));
      await _showAndSettle(tester, c, 'a');
      await _showAndSettle(tester, c, 'b');
      await tester.fling(find.text('a'), const Offset(0, -80), 1500);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.visible.map((m) => m.title), ['b']);
      expect(find.text('a'), findsNothing);
      expect(_rect(tester, 'b').top, closeTo(12, 0.01));
      await _finish(tester, c);
    });

    testWidgets(
      'renders three long toasts at text scale 1.3 without overflow',
      (tester) async {
        final c = await _pumpApp(tester, textScale: 1.3);
        c.error(
          'Could not load your account',
          'Check your connection and try again in a moment, we could not reach the server.',
        );
        c.success('Group renamed', 'Group is now "Friday movie night crew".');
        c.show('Invite saved');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await _finish(tester, c);
      },
    );
  });

  group('ToastHost controller swap', () {
    testWidgets('moves to a new controller', (tester) async {
      _useViewport(tester);
      final first = ToastController();
      final second = ToastController();
      await tester.pumpWidget(_app(first));
      first.show('from first');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('from first'), findsOneWidget);

      await tester.pumpWidget(_app(second));
      await tester.pump(const Duration(milliseconds: 300));
      second.show('from second');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('from second'), findsOneWidget);
      first.show('ignored now');
      await tester.pump();
      expect(find.text('ignored now'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      first.dispose();
      second.dispose();
    });
  });

  group('golden', () {
    Future<void> withRealShadows(Future<void> Function() body) async {
      debugDisableShadows = false;
      try {
        await body();
      } finally {
        debugDisableShadows = true;
      }
    }

    Widget stack(List<ToastMessage> messages) => SizedBox(
      width: 368,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ToastCard(message: m, onClose: () {}, animateIcon: false),
            ),
        ],
      ),
    );

    List<GoldenCell> cells() => [
      GoldenCell(
        'a stack of each variant',
        stack(const [
          ToastMessage(id: 1, title: 'Invite saved'),
          ToastMessage(
            id: 2,
            title: 'Invite Sent',
            description: 'Successfully sent invitation to friend@example.com',
            variant: ToastVariant.success,
          ),
          ToastMessage(
            id: 3,
            title: 'Group',
            description: 'Could not save changes',
            variant: ToastVariant.destructive,
          ),
        ]),
      ),
      GoldenCell(
        'long text (title 3 lines max, description 5 lines max)',
        stack(const [
          ToastMessage(
            id: 4,
            title:
                'Your session expired because you signed in on another device '
                'and we had to sign you out of this one for safety',
            description:
                'Please sign in again to keep watching together. If this keeps '
                'happening on every launch, check that you are not signed in '
                'on several phones with the same account, and that the date '
                'and time of this phone are set automatically by the network.',
            variant: ToastVariant.destructive,
          ),
          ToastMessage(id: 5, title: 'Short'),
        ]),
      ),
    ];

    testWidgets('toast stacks: every variant and long text', (tester) async {
      await withRealShadows(
        () => expectStateSheetGolden(
          tester,
          'toast_stacks',
          cells(),
          size: const Size(400, 560),
          cellWidth: 368,
        ),
      );
    });

    testWidgets('toast stacks at text scale 1.3', (tester) async {
      await withRealShadows(
        () => expectStateSheetGolden(
          tester,
          'toast_stacks_text_scale',
          cells(),
          size: const Size(400, 700),
          cellWidth: 368,
          textScale: 1.3,
        ),
      );
    });
  });
}
