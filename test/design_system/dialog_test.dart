import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/synk_dialog.dart';
import 'package:date_js/design_system/components/synk_text.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_palette.dart';
import 'package:date_js/design_system/tokens/synk_theme.dart';
import 'package:date_js/design_system/tokens/synk_typography.dart';

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
  double textScale = 1,
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
      textScale: textScale,
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

final Finder _frame = find.byType(SynkDialogFrame);

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

Widget _simple([String title = 'Invite a member']) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    DialogHeader(
      children: [
        DialogTitle(title),
        const DialogDescription("We'll email them a link."),
      ],
    ),
  ],
);

Future<_Result<String>> _open(
  WidgetTester tester, {
  WidgetBuilder? builder,
  bool dismissible = true,
  String? semanticLabel,
}) async {
  final result = _track(
    showSynkDialog<String>(
      _host,
      builder: builder ?? (_) => _simple(),
      dismissible: dismissible,
      semanticLabel: semanticLabel,
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

double _opacityOf(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(of: _frame, matching: find.byType(Opacity)).first,
    )
    .opacity;

/// Scale of the dialog card (the transform is not part of its layout size).
double _scaleOf(WidgetTester tester) {
  final box = tester.renderObject<RenderBox>(_frame);
  final topLeft = box.localToGlobal(Offset.zero);
  final bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
  return (bottomRight.dx - topLeft.dx) / box.size.width;
}

Widget _stubButton(String label, {double? width, bool primary = false}) =>
    Builder(
      builder: (context) {
        final colors = context.colors;
        return Container(
          key: ValueKey<String>('btn_$label'),
          height: 44,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: primary ? colors.primary : null,
            border: primary ? null : Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            widthFactor: 1,
            child: SynkText(
              label,
              variant: SynkTextVariant.buttonDefault,
              color: primary ? colors.primaryForeground : null,
            ),
          ),
        );
      },
    );

void main() {
  group('route', () {
    testWidgets('fades and scales in: alpha over 130ms, scale 0.96 to 1 on a '
        'spring', (tester) async {
      await _pumpHost(tester);
      unawaited(showSynkDialog<void>(_host, builder: (_) => _simple()));
      await tester.pump();
      expect(_opacityOf(tester), 0);
      expect(_scaleOf(tester), closeTo(0.96, 0.001));

      await tester.pump(const Duration(milliseconds: 40));
      final earlyAlpha = _opacityOf(tester);
      expect(earlyAlpha, greaterThan(0));
      expect(earlyAlpha, lessThan(1));
      expect(_scaleOf(tester), greaterThan(0.96));

      await tester.pump(const Duration(milliseconds: 100));
      expect(_opacityOf(tester), 1, reason: 'alpha is done after 130ms');
      await tester.pump(const Duration(seconds: 1));
      expect(_scaleOf(tester), closeTo(1, 0.0005));
    });

    testWidgets('the scrim is the dialog backdrop', (tester) async {
      await _pumpHost(tester);
      await _open(tester);
      final barrier = tester.widget<AnimatedModalBarrier>(
        find.byType(AnimatedModalBarrier),
      );
      expect(barrier.color.value, SynkPalette.dialogBackdrop);
    });

    testWidgets('fades and scales out: alpha over 160ms, scale to 0.97', (
      tester,
    ) async {
      await _pumpHost(tester);
      final result = await _open(tester);
      expect(_scaleOf(tester), closeTo(1, 0.0005));

      Navigator.of(_host, rootNavigator: true).pop('bye');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(_frame, findsOneWidget, reason: 'still animating out at 80ms');
      final alpha = _opacityOf(tester);
      expect(alpha, greaterThan(0));
      expect(alpha, lessThan(1));
      final scale = _scaleOf(tester);
      expect(scale, lessThan(1));
      expect(scale, greaterThan(0.97));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(_frame, findsNothing);
      expect(result.value, 'bye');
    });

    testWidgets('barrier tap and Back dismiss a dismissible dialog', (
      tester,
    ) async {
      await _pumpHost(tester);
      var result = await _open(tester);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(_frame, findsNothing);
      expect(result.done, isTrue);
      expect(result.value, isNull);

      result = await _open(tester);
      await _pressBack(tester);
      await tester.pumpAndSettle();
      expect(_frame, findsNothing);
      expect(result.done, isTrue);
    });

    testWidgets('a non-dismissible dialog ignores the barrier and Back', (
      tester,
    ) async {
      await _pumpHost(tester);
      final result = await _open(tester, dismissible: false);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await _pressBack(tester);
      await tester.pumpAndSettle();
      expect(_frame, findsOneWidget);
      expect(result.done, isFalse);

      // It still closes programmatically.
      Navigator.of(_host, rootNavigator: true).pop('done');
      await tester.pumpAndSettle();
      expect(_frame, findsNothing);
      expect(result.value, 'done');
    });

    testWidgets('taps inside the card do not dismiss', (tester) async {
      await _pumpHost(tester);
      final result = await _open(tester);
      await tester.tap(find.text('Invite a member'));
      await tester.tapAt(tester.getTopLeft(_frame) + const Offset(40, 3));
      await tester.pumpAndSettle();
      expect(_frame, findsOneWidget);
      expect(result.done, isFalse);
    });

    testWidgets('content closes the dialog with a result', (tester) async {
      await _pumpHost(tester);
      final result = await _open(
        tester,
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).pop('confirmed'),
          child: const Text('Confirm'),
        ),
      );
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result.value, 'confirmed');
    });

    testWidgets('Back closes only the top dialog', (tester) async {
      await _pumpHost(tester);
      final first = await _open(tester, builder: (_) => _simple('First'));
      final second = await _open(tester, builder: (_) => _simple('Second'));
      await _pressBack(tester);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(find.text('First'), findsOneWidget);
      expect(second.done, isTrue);
      expect(first.done, isFalse);
    });

    testWidgets('a non-dismissible dialog on top shields a dismissible one', (
      tester,
    ) async {
      await _pumpHost(tester);
      final below = await _open(tester, builder: (_) => _simple('Below'));
      await _open(tester, dismissible: false, builder: (_) => _simple('Top'));
      await _pressBack(tester);
      await tester.pumpAndSettle();
      expect(find.text('Top'), findsOneWidget);
      expect(find.text('Below'), findsOneWidget);
      expect(below.done, isFalse);
    });
  });

  group('layout', () {
    testWidgets('is centred with a max width of 420', (tester) async {
      await _pumpHost(tester, size: const Size(900, 800));
      await _open(tester);
      expect(tester.getSize(_frame).width, 420);
      expect(tester.getCenter(_frame).dx, closeTo(450, 0.01));
      expect(tester.getCenter(_frame).dy, closeTo(400, 0.01));
    });

    testWidgets('fills the width minus 16dp per side on a phone', (
      tester,
    ) async {
      await _pumpHost(tester, size: const Size(360, 800));
      await _open(tester);
      expect(tester.getSize(_frame).width, 328);
      expect(tester.getTopLeft(_frame).dx, closeTo(16, 0.01));
    });

    testWidgets('sits in the space above the keyboard with 12dp margins', (
      tester,
    ) async {
      await _pumpHost(tester);
      await _open(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      // Available band: 12 .. 800 - 300 - 12 = 488, so the centre is 250.
      expect(tester.getCenter(_frame).dy, closeTo(250, 0.01));
    });

    testWidgets('keeps clear of the status bar and cutouts', (tester) async {
      await _pumpHost(tester, size: const Size(360, 400));
      tester.view.viewPadding = const FakeViewPadding(
        top: 40,
        left: 10,
        right: 10,
      );
      tester.view.padding = const FakeViewPadding(top: 40, left: 10, right: 10);
      await _open(
        tester,
        builder: (_) => SizedBox(
          height: 2000,
          child: Column(children: [for (var i = 0; i < 6; i++) Text('Row $i')]),
        ),
      );
      final rect = tester.getRect(_frame);
      expect(rect.top, closeTo(40 + 12, 0.01));
      expect(rect.left, closeTo(10 + 16, 0.01));
      expect(rect.right, closeTo(360 - 10 - 16, 0.01));
      expect(rect.bottom, closeTo(400 - 12, 0.01));
    });

    testWidgets('content taller than the space scrolls', (tester) async {
      await _pumpHost(tester, size: const Size(360, 400));
      await _open(
        tester,
        builder: (_) =>
            Column(children: [for (var i = 0; i < 30; i++) Text('Row $i')]),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_frame).height, closeTo(400 - 24, 0.01));
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: _frame, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      await tester.drag(find.text('Row 3'), const Offset(0, -150));
      await tester.pump();
      expect(position.pixels, greaterThan(100));
    });

    testWidgets('inner padding is 20/20/20/max(16, bottom inset + 4)', (
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
      await _pumpHost(tester);
      await _open(tester);
      expect(padding(), const EdgeInsets.fromLTRB(20, 20, 20, 16));

      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      await tester.pump();
      expect(padding(), const EdgeInsets.fromLTRB(20, 20, 20, 52));
    });

    testWidgets('uses the card colour, radius 18 and a 1dp border', (
      tester,
    ) async {
      await _pumpHost(tester, brightness: Brightness.dark);
      await _open(tester);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: _frame,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, SynkColors.dark.card);
      expect(decoration.borderRadius, BorderRadius.circular(18));
      expect(decoration.border, Border.all(color: SynkColors.dark.border));
    });

    testWidgets('content no longer sees the keyboard or the safe area', (
      tester,
    ) async {
      await _pumpHost(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.viewPadding = const FakeViewPadding(top: 30, bottom: 24);
      tester.view.padding = const FakeViewPadding(top: 30, bottom: 24);
      MediaQueryData? data;
      await _open(
        tester,
        builder: (context) {
          data = MediaQuery.of(context);
          return _simple();
        },
      );
      expect(data!.viewInsets.bottom, 0);
      expect(data!.padding, EdgeInsets.zero);
    });

    testWidgets('header, title, description and footer follow the spec', (
      tester,
    ) async {
      await _pumpHost(tester, size: const Size(360, 800));
      await _open(
        tester,
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DialogHeader(
              children: [
                DialogTitle('Rename group'),
                DialogDescription('Muted'),
              ],
            ),
            DialogFooter(
              children: [
                _stubButton('Cancel', width: 110),
                _stubButton('Save', width: 110, primary: true),
              ],
            ),
          ],
        ),
      );
      final title = tester.widget<Text>(find.text('Rename group'));
      expect(title.style!.fontSize, 19);
      expect(title.style!.fontWeight, FontWeight.w600);
      expect(
        tester.widget<Text>(find.text('Muted')).style!.color,
        SynkColors.light.mutedForeground,
      );
      // 6dp title/description gap.
      expect(
        tester.getTopLeft(find.text('Muted')).dy -
            tester.getBottomLeft(find.text('Rename group')).dy,
        closeTo(6, 0.01),
      );
      // Footer is end-aligned with a 10dp gap and sits 16dp below the header.
      final cancel = tester.getRect(find.text('Cancel'));
      final save = tester.getRect(find.text('Save'));
      final cancelBox = tester.getRect(
        find.byKey(const ValueKey<String>('btn_Cancel')),
      );
      final saveBox = tester.getRect(
        find.byKey(const ValueKey<String>('btn_Save')),
      );
      expect(saveBox.right, closeTo(tester.getRect(_frame).right - 20, 0.01));
      expect(saveBox.left - cancelBox.right, closeTo(10, 0.01));
      expect(cancel.top, closeTo(save.top, 0.01));
      expect(
        cancelBox.top - tester.getBottomLeft(find.text('Muted')).dy,
        closeTo(16, 0.01),
      );
    });

    testWidgets('footer buttons wrap instead of overflowing when they do not '
        'fit', (tester) async {
      await _pumpHost(tester, size: const Size(360, 800));
      await _open(
        tester,
        builder: (_) => DialogFooter(
          children: [
            _stubButton('Cancel', width: 200),
            _stubButton('Confirm', width: 200, primary: true),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.text('Cancel'));
      final second = tester.getRect(find.text('Confirm'));
      expect(second.top, greaterThan(first.bottom));
    });
  });

  group('semantics', () {
    testWidgets('names the route and labels the barrier only when '
        'dismissible', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpHost(tester);
      await _open(tester, semanticLabel: 'Invite dialog');
      expect(find.bySemanticsLabel('Invite dialog'), findsOneWidget);
      expect(find.bySemanticsLabel('Dismiss'), findsOneWidget);
      Navigator.of(_host, rootNavigator: true).pop();
      await tester.pumpAndSettle();

      await _open(tester, dismissible: false);
      expect(find.bySemanticsLabel('Dismiss'), findsNothing);
      expect(find.bySemanticsLabel('Dialog'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the title is a header', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpHost(tester);
      await _open(tester);
      expect(
        tester.getSemantics(find.text('Invite a member')),
        matchesSemantics(label: 'Invite a member', isHeader: true),
      );
      handle.dispose();
    });
  });

  group('golden', () {
    Widget cell(Widget child) =>
        SizedBox(width: 340, child: SynkDialogFrame(child: child));

    Widget field(String text, {bool placeholder = false}) => Builder(
      builder: (context) {
        final colors = context.colors;
        return Container(
          height: 46,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.solidInputBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SynkText(
            text,
            variant: SynkTextVariant.input,
            color: placeholder ? colors.mutedForeground : null,
          ),
        );
      },
    );

    List<GoldenCell> cells() => [
      GoldenCell(
        'title, description, footer',
        cell(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DialogHeader(
                children: [
                  DialogTitle('Invite a member'),
                  DialogDescription(
                    "We'll email them a link. They sign up with that address, "
                    'then accept the invite in Synkly.',
                  ),
                ],
              ),
              DialogFooter(
                children: [
                  _stubButton('Cancel'),
                  _stubButton('Invite', primary: true),
                ],
              ),
            ],
          ),
        ),
      ),
      GoldenCell(
        'with an input',
        cell(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DialogHeader(
                children: [
                  DialogTitle('Rename group'),
                  DialogDescription(
                    'Choose a new name for this group. Everyone will see the '
                    'updated name.',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              field('Group name', placeholder: true),
              const SizedBox(height: 8),
              DialogFooter(
                children: [
                  _stubButton('Cancel'),
                  _stubButton('Save', primary: true),
                ],
              ),
            ],
          ),
        ),
      ),
      GoldenCell(
        'title only, one button',
        cell(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DialogHeader(children: [DialogTitle('Update available')]),
              DialogFooter(children: [_stubButton('Update', primary: true)]),
            ],
          ),
        ),
      ),
      GoldenCell(
        'long text',
        cell(
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DialogHeader(
                children: [
                  DialogTitle('A rather long dialog title that needs to wrap'),
                  DialogDescription(
                    'This description is intentionally long so that it wraps '
                    'over several lines and shows how the card grows with its '
                    'content while keeping the same padding all around it.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];

    testWidgets('dialog frames in several content shapes', (tester) async {
      await expectStateSheetGolden(
        tester,
        'dialog_frames',
        cells(),
        size: const Size(380, 880),
        cellWidth: 348,
      );
    });

    testWidgets('dialog frames at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'dialog_frames_text_scale',
        cells().take(2).toList(),
        size: const Size(380, 600),
        cellWidth: 348,
        textScale: 1.3,
      );
    });
  });
}
