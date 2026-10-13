import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/inline_state.dart';
import 'package:date_js/design_system/components/offline_banner.dart';
import 'package:date_js/design_system/components/subpage_header.dart';
import 'package:date_js/design_system/components/synk_button.dart';
import 'package:date_js/design_system/components/synk_badge.dart';
import 'package:date_js/design_system/components/synk_spinner.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';

import '../support/synk_test_harness.dart';

Widget _top(Widget child) => Align(alignment: Alignment.topLeft, child: child);

Widget _wide(Widget child, {double width = 388}) =>
    _top(SizedBox(width: width, child: child));

InlineState _state({
  String title = 'No groups yet',
  String? body = 'Create a group or wait for an invite to join a watch party.',
  String? actionLabel,
  VoidCallback? onAction,
  bool compact = false,
  bool outlineAction = false,
  SynkIcons icon = SynkIcons.users,
}) => InlineState(
  icon: icon,
  title: title,
  body: body,
  actionLabel: actionLabel,
  onAction: onAction,
  compact: compact,
  outlineAction: outlineAction,
);

/// Like [expectStateSheetGolden] but lets time pass first, so indeterminate spinners are
/// captured mid-rotation (fake time keeps the frame exact).
Future<void> _expectSheetGoldenAfter(
  WidgetTester tester,
  String name,
  List<GoldenCell> cells, {
  required Size size,
  required double cellWidth,
  double textScale = 1.0,
  Duration settle = const Duration(milliseconds: 700),
}) async {
  for (final brightness in Brightness.values) {
    useGoldenViewport(tester, size: size);
    await tester.pumpWidget(
      synkApp(
        StateSheet(cells: cells, cellWidth: cellWidth),
        brightness: brightness,
        textScale: textScale,
      ),
    );
    await tester.pump(settle);
    final suffix = brightness == Brightness.dark ? 'dark' : 'light';
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/${name}_$suffix.png'),
    );
  }
}

void main() {
  group('InlineState', () {
    testWidgets('lays out icon, title, body and action with the spec spacing', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(_wide(_state(actionLabel: 'New group', onAction: () {}))),
      );
      final icon = tester.getRect(find.byType(SynkIcon));
      final title = tester.getRect(find.text('No groups yet'));
      final body = tester.getRect(find.textContaining('Create a group'));
      final button = tester.getRect(find.byType(SynkButton));
      expect(icon.size, const Size(28, 28));
      expect(icon.top, 40, reason: 'vertical padding 40');
      expect(icon.center.dx, 194, reason: 'centred');
      expect(title.top - icon.bottom, closeTo(10, 0.01));
      expect(body.top - title.bottom, closeTo(4, 0.01));
      expect(button.top - body.bottom, closeTo(16, 0.01));
      expect(button.height, 36);
      expect(button.left, 20, reason: 'horizontal padding 20');
      expect(button.width, 388 - 40, reason: 'full width');
      expect(
        tester.getSize(find.byType(InlineState)).height,
        button.bottom + 40,
        reason: 'bottom padding 40',
      );
    });

    testWidgets('icon is muted with a 1.5dp stroke; title and body styles', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        final colors = brightness == Brightness.dark
            ? SynkColors.dark
            : SynkColors.light;
        await tester.pumpWidget(
          synkApp(_wide(_state()), brightness: brightness),
        );
        final icon = tester.widget<SynkIcon>(find.byType(SynkIcon));
        expect(icon.size, 28);
        expect(icon.strokeWidth, 1.5);
        expect(icon.color, colors.mutedForeground);
        final title = tester.widget<Text>(find.text('No groups yet')).style!;
        expect(title.fontSize, 14);
        expect(title.fontWeight, FontWeight.w500);
        expect(title.color, colors.foreground);
        final body = tester
            .widget<Text>(find.textContaining('Create a group'))
            .style!;
        expect(body.fontSize, 12);
        expect(body.color, colors.mutedForeground);
        expect(
          tester.widget<Text>(find.textContaining('Create a group')).textAlign,
          TextAlign.center,
        );
      }
    });

    testWidgets('body and action are optional', (tester) async {
      await tester.pumpWidget(synkApp(_wide(_state(body: null))));
      expect(find.textContaining('Create a group'), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
      expect(
        tester.getSize(find.byType(InlineState)).height,
        40 + 28 + 10 + tester.getSize(find.text('No groups yet')).height + 40,
      );
    });

    testWidgets('the action needs both a label and a callback', (tester) async {
      await tester.pumpWidget(synkApp(_wide(_state(actionLabel: 'Retry'))));
      expect(find.text('Retry'), findsNothing);
      await tester.pumpWidget(synkApp(_wide(_state(onAction: () {}))));
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('action fires, dims while pressed and is a labelled button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        synkApp(
          _wide(_state(actionLabel: 'New group', onAction: () => taps++)),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('New group')),
        isSemantics(isButton: true, hasTapAction: true, label: 'New group'),
      );
      await tester.tap(find.text('New group'));
      await tester.pump();
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets(
      'the action is a pill SynkButton: primary, or outline for errors',
      (tester) async {
        await tester.pumpWidget(
          synkApp(_wide(_state(actionLabel: 'Go', onAction: () {}))),
        );
        var button = tester.widget<SynkButton>(find.byType(SynkButton));
        expect(button.variant, SynkButtonVariant.primary);
        expect(button.size, SynkButtonSize.sm);
        expect(button.expand, isTrue);
        expect(
          SynkButton.shapeFor(button.variant, false),
          isA<StadiumBorder>(),
        );

        await tester.pumpWidget(
          synkApp(
            _wide(
              _state(actionLabel: 'Go', onAction: () {}, outlineAction: true),
            ),
          ),
        );
        button = tester.widget<SynkButton>(find.byType(SynkButton));
        expect(button.variant, SynkButtonVariant.outline);
      },
    );

    testWidgets('compact tightens padding and icon', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _wide(_state(compact: true, actionLabel: 'Go', onAction: () {})),
        ),
      );
      final icon = tester.getRect(find.byType(SynkIcon));
      expect(icon.size, const Size(24, 24));
      expect(icon.top, 20);
      final button = tester.getRect(find.byType(SynkButton));
      expect(button.left, 16);
      final compactHeight = tester.getSize(find.byType(InlineState)).height;
      expect(compactHeight, lessThan(await _fullHeight(tester)));
    });

    testWidgets('title and body read as one node; the icon is decorative', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          _wide(_state(title: 'No groups yet', body: 'Wait for an invite.')),
        ),
      );
      expect(
        tester.getSemantics(find.text('No groups yet')),
        isSemantics(label: 'No groups yet\nWait for an invite.'),
      );
      handle.dispose();
    });

    testWidgets('survives text scale 1.3 with long text in a narrow column', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _wide(
            _state(
              title: 'We could not load your memories right now',
              body: 'Check your connection and try again in a few moments, or pull down to refresh.',
              actionLabel: 'Try again later or refresh the page',
              onAction: () {},
            ),
            width: 240,
          ),
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('EmptyState defaults to the users icon', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _wide(
            const EmptyState(
              title: 'No memories yet',
              body: 'Everything you watch together shows up here.',
            ),
          ),
        ),
      );
      expect(
        tester.widget<SynkIcon>(find.byType(SynkIcon)).icon,
        SynkIcons.users,
      );
      expect(find.text('No memories yet'), findsOneWidget);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('EmptyState forwards icon and action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        synkApp(
          _wide(
            EmptyState(
              title: 'No memories yet',
              icon: SynkIcons.film,
              actionLabel: 'Pick a movie',
              onAction: () => taps++,
            ),
          ),
        ),
      );
      expect(
        tester.widget<SynkIcon>(find.byType(SynkIcon)).icon,
        SynkIcons.film,
      );
      await tester.tap(find.text('Pick a movie'));
      expect(taps, 1);
    });

    testWidgets('ErrorState shows the alert icon and a retry action', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        synkApp(
          _wide(
            ErrorState(
              title: 'Couldn’t load your memories',
              body: 'Check your connection and try again.',
              onRetry: () => retries++,
            ),
          ),
        ),
      );
      expect(
        tester.widget<SynkIcon>(find.byType(SynkIcon)).icon,
        SynkIcons.alert,
      );
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
      expect(
        tester.widget<SynkButton>(find.byType(SynkButton)).variant,
        SynkButtonVariant.outline,
        reason: 'the retry is the quieter outline button',
      );
    });

    testWidgets(
      'ErrorState has a generic title, custom retry label and no retry without a callback',
      (tester) async {
        await tester.pumpWidget(synkApp(_wide(const ErrorState())));
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Try again'), findsNothing);

        await tester.pumpWidget(
          synkApp(_wide(ErrorState(retryLabel: 'Reload', onRetry: () {}))),
        );
        expect(find.text('Reload'), findsOneWidget);

        var actions = 0;
        await tester.pumpWidget(
          synkApp(
            _wide(
              ErrorState(
                actionLabel: 'Contact support',
                onAction: () => actions++,
                onRetry: () {},
              ),
            ),
          ),
        );
        expect(find.text('Try again'), findsNothing);
        await tester.tap(find.text('Contact support'));
        expect(actions, 1);
      },
    );

    testWidgets('golden: inline, empty and error states', (tester) async {
      await expectStateSheetGolden(
        tester,
        'states_inline',
        [
          GoldenCell(
            'InlineState: icon + title + body + action',
            _state(actionLabel: 'New group', onAction: () {}),
          ),
          GoldenCell(
            'InlineState: title only',
            _state(body: null, icon: SynkIcons.film, title: 'No memories yet'),
          ),
          GoldenCell(
            'InlineState compact: outline action',
            _state(
              compact: true,
              outlineAction: true,
              actionLabel: 'View full leaderboard',
              onAction: () {},
              icon: SynkIcons.crown,
              title: 'No groups ranked yet',
              body: 'Start watching together to claim the #1 spot this week!',
            ),
          ),
          const GoldenCell(
            'EmptyState',
            EmptyState(
              title: 'No memories yet',
              body: 'Everything you watch together shows up here.',
              icon: SynkIcons.film,
            ),
          ),
          GoldenCell(
            'ErrorState',
            ErrorState(
              title: 'Couldn’t load your memories',
              body: 'Check your connection and try again.',
              icon: SynkIcons.refresh,
              onRetry: () {},
            ),
          ),
        ],
        size: const Size(420, 1040),
        cellWidth: 388,
      );
    });

    testWidgets('golden: states at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'states_inline_scale13',
        [
          GoldenCell(
            'InlineState',
            _state(actionLabel: 'New group', onAction: () {}),
          ),
          GoldenCell(
            'ErrorState',
            ErrorState(
              title: 'Couldn’t load your memories',
              body: 'Check your connection and try again.',
              onRetry: () {},
            ),
          ),
        ],
        size: const Size(420, 560),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });

  group('OfflineBanner', () {
    testWidgets('is a full-width muted bar with a hairline bottom border', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        final colors = brightness == Brightness.dark
            ? SynkColors.dark
            : SynkColors.light;
        tester.view.physicalSize = const Size(840, 1600);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          synkApp(
            _top(const OfflineBanner(message: 'Offline')),
            brightness: brightness,
          ),
        );
        expect(tester.getSize(find.byType(OfflineBanner)).width, 420);
        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(OfflineBanner),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(decoration.color, colors.muted);
        final border = decoration.border! as Border;
        expect(border.bottom.color, colors.border);
        expect(border.bottom.width, 0.5, reason: 'one physical pixel at 2x');
        expect(border.top, BorderSide.none);
      }
    });

    testWidgets('text is 14sp medium muted, centred, padded 12 / 6', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(_top(const OfflineBanner(message: 'Offline'))),
      );
      final text = tester.widget<Text>(find.text('Offline'));
      expect(text.style!.fontSize, 14);
      expect(text.style!.fontWeight, FontWeight.w500);
      expect(text.style!.color, SynkColors.light.mutedForeground);
      expect(text.textAlign, TextAlign.center);
      expect(
        tester.getCenter(find.text('Offline')).dx,
        closeTo(tester.getSize(find.byType(OfflineBanner)).width / 2, 0.01),
      );
      final textHeight = tester.getSize(find.text('Offline')).height;
      expect(
        tester.getSize(find.byType(OfflineBanner)).height,
        closeTo(textHeight + 12, 0.01),
      );
    });

    testWidgets('shows a spinner only while reconnecting', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const OfflineBanner(message: 'Reconnecting…', reconnecting: true),
          ),
        ),
      );
      expect(find.byType(SynkSpinner), findsOneWidget);
      expect(tester.getSize(find.byType(SynkSpinner)), const Size(14, 14));
      expect(
        tester.getCenter(find.byType(SynkSpinner)).dx,
        lessThan(tester.getCenter(find.text('Reconnecting…')).dx),
      );

      await tester.pumpWidget(
        synkApp(
          _top(const OfflineBanner(message: 'Offline — messages will send')),
        ),
      );
      expect(find.byType(SynkSpinner), findsNothing);
    });

    testWidgets('announces itself as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          _top(
            const OfflineBanner(message: 'Reconnecting…', reconnecting: true),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(OfflineBanner)),
        isSemantics(isLiveRegion: true, label: 'Reconnecting…'),
      );
      handle.dispose();
    });

    testWidgets('long messages wrap to two lines instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _wide(
            const OfflineBanner(
              message: 'Offline — messages will send when you reconnect',
              reconnecting: true,
            ),
            width: 300,
          ),
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(
        find.text('Offline — messages will send when you reconnect'),
      );
      expect(text.maxLines, 2);
      expect(tester.getSize(find.byType(OfflineBanner)).width, 300);
    });

    testWidgets('golden: both banner states', (tester) async {
      await _expectSheetGoldenAfter(
        tester,
        'states_offline_banner',
        [
          const GoldenCell(
            'offline',
            OfflineBanner(
              message: 'Offline — messages will send when you reconnect',
            ),
          ),
          const GoldenCell(
            'reconnecting',
            OfflineBanner(message: 'Reconnecting…', reconnecting: true),
          ),
        ],
        size: const Size(420, 150),
        cellWidth: 388,
      );
    });

    testWidgets('golden: banners at text scale 1.3', (tester) async {
      await _expectSheetGoldenAfter(
        tester,
        'states_offline_banner_scale13',
        [
          const GoldenCell(
            'offline',
            OfflineBanner(
              message: 'Offline — messages will send when you reconnect',
            ),
          ),
          const GoldenCell(
            'reconnecting',
            OfflineBanner(message: 'Reconnecting…', reconnecting: true),
          ),
        ],
        size: const Size(420, 190),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });

  group('SubpageHeader', () {
    testWidgets(
      'lays out back button, title and spacer on the 12 / 10 / 8 grid',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            _wide(SubpageHeader(title: 'Weekly leaderboard', onBack: () {})),
          ),
        );
        final back = tester.getRect(find.bySemanticsLabel('Back'));
        expect(back.size, const Size(36, 36));
        expect(back.left, 12);
        expect(back.top, 10);
        final title = tester.getRect(find.text('Weekly leaderboard'));
        expect(title.left, 12 + 36 + 8);
        // Title block ends before the 36dp spacer: 388 - 12 - 36 - 8.
        expect(tester.getSize(find.byType(SubpageHeader)).height, 10 + 36 + 10);
      },
    );

    testWidgets('title is 17/600 one line, subtitle 12 muted one line', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _wide(
            SubpageHeader(
              title: 'Weekly leaderboard',
              subtitle: 'Mon – Sun IST',
              onBack: () {},
            ),
          ),
        ),
      );
      final title = tester.widget<Text>(find.text('Weekly leaderboard'));
      expect(title.style!.fontSize, 17);
      expect(title.style!.fontWeight, FontWeight.w600);
      expect(title.style!.color, SynkColors.light.foreground);
      expect(title.maxLines, 1);
      final subtitle = tester.widget<Text>(find.text('Mon – Sun IST'));
      expect(subtitle.style!.fontSize, 12);
      expect(subtitle.style!.color, SynkColors.light.mutedForeground);
      expect(subtitle.maxLines, 1);
      expect(
        tester.getRect(find.text('Mon – Sun IST')).top -
            tester.getRect(find.text('Weekly leaderboard')).bottom,
        closeTo(1, 0.01),
      );
      expect(
        tester.getRect(find.text('Mon – Sun IST')).left,
        tester.getRect(find.text('Weekly leaderboard')).left,
      );
    });

    testWidgets('closes with a one-pixel border line in the border colour', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        final colors = brightness == Brightness.dark
            ? SynkColors.dark
            : SynkColors.light;
        tester.view.physicalSize = const Size(1260, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          synkApp(
            _top(SubpageHeader(title: 'Profile', onBack: () {})),
            brightness: brightness,
          ),
        );
        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(SubpageHeader),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        final border = decoration.border! as Border;
        expect(border.bottom.color, colors.border);
        expect(border.bottom.width * 3, closeTo(1, 1e-9));
        expect(border.top, BorderSide.none);
      }
    });

    testWidgets('back button: 22dp icon with 2.25 stroke, fires onBack', (
      tester,
    ) async {
      var backs = 0;
      await tester.pumpWidget(
        synkApp(_wide(SubpageHeader(title: 'Profile', onBack: () => backs++))),
      );
      final icon = tester.widget<SynkIcon>(find.byType(SynkIcon));
      expect(icon.icon, SynkIcons.back);
      expect(icon.size, 22);
      expect(icon.strokeWidth, 2.25);
      expect(icon.color, SynkColors.light.foreground);
      await tester.tap(find.byType(SynkIcon));
      expect(backs, 1);
    });

    testWidgets('back button fills muted only while pressed', (tester) async {
      Color fill() =>
          ((tester
                      .widget<Container>(
                        find
                            .ancestor(
                              of: find.byType(SynkIcon),
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration!)
                  as BoxDecoration)
              .color!;
      await tester.pumpWidget(
        synkApp(_wide(SubpageHeader(title: 'Profile', onBack: () {}))),
      );
      expect(fill(), Colors.transparent);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SynkIcon)),
      );
      await tester.pump();
      expect(fill(), SynkColors.light.muted);
      await gesture.up();
      await tester.pump();
      expect(fill(), Colors.transparent);

      // Dragging off the button cancels the press without firing.
      var backs = 0;
      await tester.pumpWidget(
        synkApp(_wide(SubpageHeader(title: 'Profile', onBack: () => backs++))),
      );
      final drag = await tester.startGesture(
        tester.getCenter(find.byType(SynkIcon)),
      );
      await tester.pump();
      expect(fill(), SynkColors.light.muted);
      await drag.moveBy(const Offset(0, 200));
      await drag.up();
      await tester.pump();
      expect(fill(), Colors.transparent);
      expect(backs, 0);
    });

    testWidgets('back button is announced as a button with backLabel', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(_wide(SubpageHeader(title: 'Profile', onBack: () {}))),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Back')),
        isSemantics(isButton: true, hasTapAction: true, label: 'Back'),
      );
      await tester.pumpWidget(
        synkApp(
          _wide(
            SubpageHeader(
              title: 'Profile',
              backLabel: 'Go back',
              onBack: () {},
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Go back'), findsOneWidget);
      expect(find.bySemanticsLabel('Back'), findsNothing);
      handle.dispose();
    });

    testWidgets('title block is a heading', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          _wide(
            SubpageHeader(
              title: 'Memories',
              subtitle: 'What you’ve watched',
              onBack: () {},
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Memories')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('without onBack the back slot stays so titles line up', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(_wide(const SubpageHeader(title: 'Memories'))),
      );
      expect(find.byType(SynkIcon), findsNothing);
      expect(tester.getRect(find.text('Memories')).left, 56);
    });

    testWidgets('trailing replaces the 36dp spacer on the right', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _wide(
            SubpageHeader(
              title: 'Profile',
              onBack: () {},
              trailing: const SynkBadge(text: 'Pro'),
            ),
          ),
        ),
      );
      final badge = tester.getRect(find.byType(SynkBadge));
      expect(badge.right, 388 - 12);

      // Without trailing the title block still reserves 36dp + the 8dp gap.
      await tester.pumpWidget(
        synkApp(
          _wide(
            SubpageHeader(
              title:
                  'A title long enough to be ellipsized in this narrow header',
              onBack: () {},
            ),
          ),
        ),
      );
      final title = tester.getRect(
        find.text('A title long enough to be ellipsized in this narrow header'),
      );
      expect(title.right, lessThanOrEqualTo(388 - 12 - 36 - 8 + 0.01));
    });

    testWidgets('long title and subtitle stay on one line without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _wide(
            SubpageHeader(
              title: 'A really long screen title that cannot possibly fit',
              subtitle:
                  'An equally long subtitle that cannot possibly fit either',
              onBack: () {},
            ),
            width: 280,
          ),
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(
        find.text('A really long screen title that cannot possibly fit'),
      );
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('golden: with / without subtitle, trailing and back', (
      tester,
    ) async {
      await expectStateSheetGolden(
        tester,
        'states_subpage_header',
        [
          GoldenCell(
            'title only',
            SubpageHeader(title: 'Memories', onBack: () {}),
          ),
          GoldenCell(
            'title + subtitle',
            SubpageHeader(
              title: 'Weekly leaderboard',
              subtitle: 'Mon – Sun IST',
              onBack: () {},
            ),
          ),
          GoldenCell(
            'trailing action',
            SubpageHeader(
              title: 'Group settings',
              subtitle: 'Friends watch party',
              onBack: () {},
              trailing: const SynkBadge(
                text: 'Owner',
                variant: SynkBadgeVariant.ink,
              ),
            ),
          ),
          const GoldenCell(
            'no back button',
            SubpageHeader(title: 'Profile', subtitle: 'Your account'),
          ),
          GoldenCell(
            'long text ellipsizes',
            SubpageHeader(
              title: 'A really long screen title that cannot possibly fit',
              subtitle:
                  'An equally long subtitle that cannot possibly fit either',
              onBack: () {},
            ),
          ),
        ],
        size: const Size(420, 480),
        cellWidth: 388,
      );
    });

    testWidgets('golden: headers at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'states_subpage_header_scale13',
        [
          GoldenCell(
            'title only',
            SubpageHeader(title: 'Memories', onBack: () {}),
          ),
          GoldenCell(
            'title + subtitle + trailing',
            SubpageHeader(
              title: 'Weekly leaderboard',
              subtitle: 'Mon – Sun IST',
              onBack: () {},
              trailing: const SynkBadge(text: 'Pro', small: true),
            ),
          ),
        ],
        size: const Size(420, 250),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });
}

Future<double> _fullHeight(WidgetTester tester) async {
  await tester.pumpWidget(
    synkApp(_wide(_state(actionLabel: 'Go', onAction: () {}))),
  );
  return tester.getSize(find.byType(InlineState)).height;
}
