import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/synk_button.dart';
import 'package:date_js/design_system/components/synk_chip.dart';
import 'package:date_js/design_system/components/synk_pill_tabs.dart';
import 'package:date_js/design_system/components/synk_segmented_tabs.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';

import '../support/synk_test_harness.dart';

enum _Kind { friends, partner, family }

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(420, 800),
}) async {
  useGoldenViewport(tester, size: size);
  await tester.pumpWidget(
    synkApp(
      Align(alignment: Alignment.topLeft, child: child),
      brightness: brightness,
      textScale: textScale,
    ),
  );
}

const _two = <SynkTabOption<_Kind>>[
  SynkTabOption(value: _Kind.friends, label: 'Friends', icon: SynkIcons.users),
  SynkTabOption(value: _Kind.partner, label: 'Partner', icon: SynkIcons.heart),
];

const _three = <SynkTabOption<_Kind>>[
  SynkTabOption(value: _Kind.friends, label: 'Friends'),
  SynkTabOption(value: _Kind.partner, label: 'Partner'),
  SynkTabOption(value: _Kind.family, label: 'Family'),
];

Widget _segmented({
  List<SynkTabOption<_Kind>> options = _two,
  _Kind selected = _Kind.friends,
  ValueChanged<_Kind>? onChanged,
  bool enabled = true,
  double width = 320,
}) => SizedBox(
  width: width,
  child: SynkSegmentedTabs<_Kind>(
    options: options,
    selected: selected,
    onChanged: onChanged ?? (_) {},
    enabled: enabled,
  ),
);

const _pills = <SynkPillOption<String>>[
  SynkPillOption(value: 'org', label: 'Organization'),
  SynkPillOption(value: 'teams', label: 'Teams'),
  SynkPillOption(value: 'users', label: 'Users'),
];

List<SynkPillOption<int>> _manyPills(int n) => [
  for (var i = 0; i < n; i++)
    SynkPillOption(value: i, label: 'Group number $i', count: i * 10),
];

void main() {
  const light = SynkColors.light;

  group('SynkSegmentedTabs', () {
    testWidgets('tapping another option reports it', (tester) async {
      final picked = <_Kind>[];
      await _pump(tester, _segmented(onChanged: picked.add));
      await tester.tap(find.text('Partner'));
      expect(picked, [_Kind.partner]);
    });

    testWidgets('tapping the selected option does not fire', (tester) async {
      final picked = <_Kind>[];
      await _pump(tester, _segmented(onChanged: picked.add));
      await tester.tap(find.text('Friends'));
      expect(picked, isEmpty);
    });

    testWidgets('disabled control is dimmed and inert', (tester) async {
      final picked = <_Kind>[];
      await _pump(tester, _segmented(onChanged: picked.add, enabled: false));
      await tester.tap(find.text('Partner'));
      expect(picked, isEmpty);
      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(SynkSegmentedTabs<_Kind>),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.5);
    });

    testWidgets('options share the width equally', (tester) async {
      await _pump(tester, _segmented(options: _three, width: 320));
      final a = tester.getSize(find.text('Friends')).width;
      expect(a, greaterThan(0));
      // Track 320 - padding 8 - gaps 8 = 304 / 3.
      final tabs = find.byType(AnimatedContainer);
      expect(tabs, findsNWidgets(3));
      for (final element in tabs.evaluate()) {
        expect(element.size!.width, closeTo(304 / 3, 0.01));
      }
    });

    testWidgets('track and pill styling follows the spec', (tester) async {
      await _pump(tester, _segmented());
      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(SynkSegmentedTabs<_Kind>),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final track = decorated.decoration as BoxDecoration;
      expect(track.color, light.foreground.withValues(alpha: 0.06));
      expect(track.borderRadius, BorderRadius.circular(12));

      final pills = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final selected = pills.first.decoration! as BoxDecoration;
      expect(selected.color, light.card);
      expect(selected.borderRadius, BorderRadius.circular(9));
      expect((selected.border! as Border).top.width, 1);
      expect((selected.border! as Border).top.color, light.border);
      final other = pills.last.decoration! as BoxDecoration;
      expect(other.color, Colors.transparent);
    });

    testWidgets('label 13/600, selected foreground, unselected muted', (
      tester,
    ) async {
      await _pump(tester, _segmented());
      TextStyle styleOf(String label) =>
          DefaultTextStyle.of(tester.element(find.text(label))).style;
      expect(styleOf('Friends').fontSize, 13);
      expect(styleOf('Friends').fontWeight, FontWeight.w600);
      expect(styleOf('Friends').color, light.foreground);
      expect(styleOf('Partner').color, light.mutedForeground);
    });

    testWidgets('selected icon is primary, unselected muted', (tester) async {
      await _pump(tester, _segmented());
      final icons = tester.widgetList<SynkIcon>(find.byType(SynkIcon)).toList();
      expect(icons[0].color, light.primary);
      expect(icons[1].color, light.mutedForeground);
    });

    testWidgets('pressed option dims to 80%', (tester) async {
      await _pump(tester, _segmented());
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Partner')),
      );
      await tester.pump();
      final opacities = tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .map((o) => o.opacity)
          .toList();
      expect(opacities, [1, 0.8]);
      await gesture.up();
      await tester.pump();
    });

    testWidgets('semantics: tab role, selected state, tap action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _segmented());
      final selected = tester.getSemantics(find.bySemanticsLabel('Friends'));
      expect(
        selected,
        isSemantics(
          label: 'Friends',
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(selected.getSemanticsData().role, SemanticsRole.tab);
      final other = tester.getSemantics(find.bySemanticsLabel('Partner'));
      expect(
        other,
        isSemantics(
          label: 'Partner',
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('disabled options expose a disabled state', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _segmented(enabled: false));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Partner')),
        isSemantics(
          label: 'Partner',
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('survives text scale 1.3 and long labels', (tester) async {
      await _pump(
        tester,
        _segmented(
          width: 300,
          options: const [
            SynkTabOption(
              value: _Kind.friends,
              label: 'Friends and family',
              icon: SynkIcons.users,
            ),
            SynkTabOption(
              value: _Kind.partner,
              label: 'Partner',
              icon: SynkIcons.heart,
            ),
          ],
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark theme uses dark tokens', (tester) async {
      await _pump(tester, _segmented(), brightness: Brightness.dark);
      final pill =
          tester
                  .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
                  .first
                  .decoration!
              as BoxDecoration;
      expect(pill.color, SynkColors.dark.muted);
    });
  });

  group('SynkPillTabs', () {
    Widget pills({
      List<SynkPillOption<String>> options = _pills,
      String selected = 'org',
      ValueChanged<String>? onChanged,
      bool scrollable = true,
      EdgeInsets padding = EdgeInsets.zero,
      double width = 360,
    }) => SizedBox(
      width: width,
      child: SynkPillTabs<String>(
        options: options,
        selected: selected,
        onChanged: onChanged ?? (_) {},
        scrollable: scrollable,
        padding: padding,
      ),
    );

    /// The colour currently painted (not the animation target).
    Color pillFill(WidgetTester tester, String label) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedContainer),
              ),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color!;
    }

    testWidgets('tapping another pill reports its value', (tester) async {
      final picked = <String>[];
      await _pump(tester, pills(onChanged: picked.add));
      await tester.tap(find.text('Teams'));
      expect(picked, ['teams']);
      await tester.tap(find.text('Organization'));
      expect(picked, [
        'teams',
      ], reason: 're-tapping the selected pill is silent');
    });

    testWidgets('selected pill is ink, others are muted', (tester) async {
      await _pump(tester, pills());
      expect(pillFill(tester, 'Organization'), light.ink);
      expect(pillFill(tester, 'Teams'), synkSoftFill(light));
      TextStyle styleOf(String label) => tester
          .widget<AnimatedDefaultTextStyle>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(AnimatedDefaultTextStyle),
                )
                .first,
          )
          .style;
      expect(styleOf('Organization').color, light.inkForeground);
      expect(styleOf('Teams').color, isNot(light.inkForeground));
    });

    testWidgets('pills are 40dp tall full-radius with 18dp side padding', (
      tester,
    ) async {
      await _pump(tester, pills());
      final box = find.ancestor(
        of: find.text('Teams'),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(box).height, 40);
      final decoration =
          tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(9999));
      expect(
        tester.getTopLeft(find.text('Teams')).dx - tester.getTopLeft(box).dx,
        closeTo(18, 0.5),
      );
    });

    testWidgets('counts render after the label in a lighter weight', (
      tester,
    ) async {
      await _pump(
        tester,
        pills(
          options: const [
            SynkPillOption(value: 'all', label: 'All', count: 1273),
            SynkPillOption(value: 'new', label: 'New', count: 4),
          ],
          selected: 'all',
        ),
      );
      expect(find.text('1273'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('1273')).dx,
        greaterThan(tester.getTopRight(find.text('All')).dx),
      );
      TextStyle styleOf(String text) => tester
          .widget<AnimatedDefaultTextStyle>(
            find
                .ancestor(
                  of: find.text(text),
                  matching: find.byType(AnimatedDefaultTextStyle),
                )
                .first,
          )
          .style;
      expect(styleOf('All').fontWeight, FontWeight.w600);
      expect(styleOf('1273').fontWeight, FontWeight.w500);
      expect(styleOf('1273').color, isNot(styleOf('All').color));
    });

    testWidgets('leading icon is drawn when given', (tester) async {
      await _pump(
        tester,
        pills(
          options: const [
            SynkPillOption(value: 'a', label: 'Mine', icon: SynkIcons.user),
          ],
          selected: 'a',
        ),
      );
      final icon = tester.widget<SynkIcon>(find.byType(SynkIcon));
      expect(icon.icon, SynkIcons.user);
      expect(icon.color, light.inkForeground);
      expect(
        tester.getTopRight(find.byType(SynkIcon)).dx,
        lessThan(tester.getTopLeft(find.text('Mine')).dx),
      );
    });

    testWidgets('colour change animates over 180ms', (tester) async {
      var selected = 'org';
      late StateSetter setSelected;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setSelected = setState;
            return pills(
              selected: selected,
              onChanged: (v) => setState(() => selected = v),
            );
          },
        ),
      );
      setSelected(() => selected = 'teams');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final mid = pillFill(tester, 'Teams');
      expect(mid, isNot(light.ink));
      expect(mid, isNot(synkSoftFill(light)));
      await tester.pump(const Duration(milliseconds: 120));
      expect(pillFill(tester, 'Teams'), light.ink);
      expect(pillFill(tester, 'Organization'), synkSoftFill(light));
    });

    testWidgets('scrolls horizontally when the pills overflow', (tester) async {
      await _pump(
        tester,
        pills(options: _manyPills(8).map(_toString).toList(), width: 320),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.pixels, 0);
      expect(scrollable.position.maxScrollExtent, greaterThan(100));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-200, 0),
      );
      await tester.pump();
      expect(scrollable.position.pixels, greaterThan(100));
    });

    testWidgets('has an edge fade mask while it can scroll', (tester) async {
      await _pump(
        tester,
        pills(options: _manyPills(8).map(_toString).toList(), width: 320),
      );
      await tester.pump();
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('padding insets the first pill but not the scroll area', (
      tester,
    ) async {
      await _pump(
        tester,
        pills(padding: const EdgeInsets.symmetric(horizontal: 16)),
      );
      final first = find.ancestor(
        of: find.text('Organization'),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getTopLeft(first).dx, 16);
      expect(tester.getRect(find.byType(SingleChildScrollView)).left, 0);
    });

    testWidgets('the selected pill is scrolled into view', (tester) async {
      final options = _manyPills(12).map(_toString).toList();
      await _pump(tester, pills(options: options, selected: '11', width: 320));
      await tester.pump();
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.pixels, greaterThan(0));
      final rect = tester.getRect(
        find.ancestor(
          of: find.text('Group number 11'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(rect.right, lessThanOrEqualTo(320.5));
      expect(rect.left, greaterThanOrEqualTo(0));
    });

    testWidgets('changing the selection scrolls the new pill into view', (
      tester,
    ) async {
      final options = _manyPills(12).map(_toString).toList();
      var selected = '0';
      late StateSetter setSelected;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            setSelected = setState;
            return pills(options: options, selected: selected, width: 320);
          },
        ),
      );
      await tester.pump();
      setSelected(() => selected = '9');
      await tester.pumpAndSettle();
      final rect = tester.getRect(
        find.ancestor(
          of: find.text('Group number 9'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(rect.right, lessThanOrEqualTo(320.5));
      expect(rect.left, greaterThanOrEqualTo(0));
    });

    testWidgets('scrollable false wraps instead of scrolling', (tester) async {
      await _pump(
        tester,
        pills(
          options: _manyPills(8).map(_toString).toList(),
          scrollable: false,
          width: 320,
        ),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(Wrap), findsOneWidget);
      expect(tester.getSize(find.byType(Wrap)).height, greaterThan(80));
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics: tab role, selected state and the count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        pills(
          options: const [
            SynkPillOption(value: 'all', label: 'All', count: 1273),
            SynkPillOption(value: 'new', label: 'New'),
          ],
          selected: 'all',
        ),
      );
      final all = tester.getSemantics(find.bySemanticsLabel('All, 1273'));
      expect(
        all,
        isSemantics(
          label: 'All, 1273',
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(all.getSemanticsData().role, SemanticsRole.tab);
      expect(
        tester.getSemantics(find.bySemanticsLabel('New')),
        isSemantics(label: 'New', hasSelectedState: true, isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('survives text scale 1.3 (scrolling and wrapping)', (
      tester,
    ) async {
      await _pump(
        tester,
        Column(
          children: [
            pills(width: 300),
            pills(
              options: const [
                SynkPillOption(
                  value: 'all',
                  label: 'All',
                  count: 1273,
                  icon: SynkIcons.users,
                ),
                SynkPillOption(value: 'teams', label: 'Teams', count: 12),
                SynkPillOption(value: 'users', label: 'Users', count: 1261),
              ],
              selected: 'all',
              scrollable: false,
              width: 300,
            ),
          ],
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('works in RTL', (tester) async {
      useGoldenViewport(tester);
      await tester.pumpWidget(
        synkApp(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.topLeft,
              child: pills(
                options: _manyPills(8).map(_toString).toList(),
                width: 320,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      // The first pill hugs the right edge in RTL.
      final first = tester.getRect(
        find.ancestor(
          of: find.text('Group number 0'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(first.right, closeTo(320 - 16, 0.5));
    });
  });

  group('SynkChip', () {
    testWidgets('tap fires and pressed dims to 80%', (tester) async {
      var taps = 0;
      await _pump(tester, SynkChip(label: "I'm in", onTap: () => taps++));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text("I'm in")),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0.8,
      );
      await gesture.up();
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('selected is primary, unselected is muted', (tester) async {
      Color fill() =>
          (tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as BoxDecoration)
              .color!;
      TextStyle style() => tester.widget<Text>(find.text('Going')).style!;

      await _pump(tester, SynkChip(label: 'Going', onTap: () {}));
      expect(fill(), light.muted);
      expect(style().color, light.foreground);

      await _pump(
        tester,
        SynkChip(label: 'Going', selected: true, onTap: () {}),
      );
      await tester.pumpAndSettle();
      expect(fill(), light.primary);
      expect(style().color, light.primaryForeground);
    });

    testWidgets('pill geometry: radius full, h14 v7, 12/600', (tester) async {
      await _pump(tester, SynkChip(label: 'Going', onTap: () {}));
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        container.padding,
        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      );
      expect(
        (container.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(9999),
      );
      final style = tester.widget<Text>(find.text('Going')).style!;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w600);
      expect(tester.getSize(find.byType(SynkChip)).height, 30);
    });

    testWidgets('icon and count render', (tester) async {
      await _pump(
        tester,
        SynkChip(
          label: 'Going',
          icon: SynkIcons.check,
          count: 12,
          selected: true,
          onTap: () {},
        ),
      );
      expect(find.byType(SynkIcon), findsOneWidget);
      expect(
        tester.widget<SynkIcon>(find.byType(SynkIcon)).color,
        light.primaryForeground,
      );
      expect(find.text('12'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('12')).style!.fontWeight,
        FontWeight.w500,
      );
    });

    testWidgets('semantics: button with selected state', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        SynkChip(label: 'Going', count: 3, selected: true, onTap: () {}),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Going, 3')),
        isSemantics(
          label: 'Going, 3',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('without onTap the chip is a read-only label', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const SynkChip(label: 'Enabled', selected: true));
      await tester.tap(find.text('Enabled'));
      final node = tester.getSemantics(find.bySemanticsLabel('Enabled'));
      expect(
        node,
        isSemantics(
          label: 'Enabled',
          isButton: false,
          hasTapAction: false,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('long label ellipsizes and survives text scale 1.3', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 120,
          child: SynkChip(
            label: 'A very long chip label',
            icon: SynkIcons.users,
            count: 10,
            onTap: () {},
          ),
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark theme uses dark tokens', (tester) async {
      await _pump(
        tester,
        SynkChip(label: 'Going', selected: true, onTap: () {}),
        brightness: Brightness.dark,
      );
      final fill =
          (tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as BoxDecoration)
              .color;
      expect(fill, SynkColors.dark.primary);
    });
  });

  group('golden state sheets', () {
    Widget segmentedCell({
      List<SynkTabOption<_Kind>> options = _two,
      _Kind selected = _Kind.friends,
      bool enabled = true,
    }) => SynkSegmentedTabs<_Kind>(
      options: options,
      selected: selected,
      onChanged: (_) {},
      enabled: enabled,
    );

    List<GoldenCell> segmentedCells() => [
      GoldenCell('2 options with icons, first selected', segmentedCell()),
      GoldenCell(
        '2 options with icons, second selected',
        segmentedCell(selected: _Kind.partner),
      ),
      GoldenCell(
        '3 options, text only',
        segmentedCell(options: _three, selected: _Kind.partner),
      ),
      GoldenCell(
        'disabled',
        segmentedCell(selected: _Kind.partner, enabled: false),
      ),
      GoldenCell(
        'long labels (ellipsis)',
        segmentedCell(
          options: const [
            SynkTabOption(
              value: _Kind.friends,
              label: 'Friends and extended family',
              icon: SynkIcons.users,
            ),
            SynkTabOption(
              value: _Kind.partner,
              label: 'Partner',
              icon: SynkIcons.heart,
            ),
            SynkTabOption(value: _Kind.family, label: 'Family'),
          ],
        ),
      ),
    ];

    List<GoldenCell> pillCells() => [
      GoldenCell(
        'Organization / Teams / Users',
        SynkPillTabs<String>(
          options: _pills,
          selected: 'org',
          onChanged: (_) {},
        ),
      ),
      GoldenCell(
        'second selected',
        SynkPillTabs<String>(
          options: _pills,
          selected: 'teams',
          onChanged: (_) {},
        ),
      ),
      GoldenCell(
        'with counts',
        SynkPillTabs<String>(
          options: const [
            SynkPillOption(value: 'all', label: 'All', count: 1273),
            SynkPillOption(value: 'teams', label: 'Teams', count: 12),
            SynkPillOption(value: 'users', label: 'Users', count: 1261),
          ],
          selected: 'all',
          onChanged: (_) {},
        ),
      ),
      GoldenCell(
        'with icons',
        SynkPillTabs<String>(
          options: const [
            SynkPillOption(value: 'a', label: 'Groups', icon: SynkIcons.users),
            SynkPillOption(
              value: 'b',
              label: 'Invites',
              icon: SynkIcons.mail,
              count: 2,
            ),
            SynkPillOption(value: 'c', label: 'Starred', icon: SynkIcons.heart),
          ],
          selected: 'b',
          onChanged: (_) {},
        ),
      ),
      GoldenCell(
        'overflow: scrolls, fade on the trailing edge',
        SynkPillTabs<String>(
          options: const [
            SynkPillOption(value: 'a', label: 'Everyone', count: 1273),
            SynkPillOption(value: 'b', label: 'Organizations', count: 8),
            SynkPillOption(value: 'c', label: 'Teams', count: 41),
            SynkPillOption(value: 'd', label: 'Users', count: 1224),
            SynkPillOption(value: 'e', label: 'Guests', count: 3),
          ],
          selected: 'a',
          onChanged: (_) {},
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
      GoldenCell(
        'overflow: selected pill revealed',
        SynkPillTabs<String>(
          options: const [
            SynkPillOption(value: 'a', label: 'Everyone', count: 1273),
            SynkPillOption(value: 'b', label: 'Organizations', count: 8),
            SynkPillOption(value: 'c', label: 'Teams', count: 41),
            SynkPillOption(value: 'd', label: 'Users', count: 1224),
            SynkPillOption(value: 'e', label: 'Guests', count: 3),
          ],
          selected: 'd',
          onChanged: (_) {},
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
      GoldenCell(
        'scrollable: false (wraps)',
        SizedBox(
          width: 300,
          child: SynkPillTabs<String>(
            options: const [
              SynkPillOption(value: 'a', label: 'Everyone', count: 1273),
              SynkPillOption(value: 'b', label: 'Organizations', count: 8),
              SynkPillOption(value: 'c', label: 'Teams', count: 41),
            ],
            selected: 'c',
            scrollable: false,
            onChanged: (_) {},
          ),
        ),
      ),
    ];

    List<GoldenCell> chipCells() => [
      GoldenCell(
        'RSVP: unselected / selected',
        Wrap(
          spacing: 8,
          children: [
            SynkChip(label: "I'm in", onTap: () {}),
            SynkChip(label: "Can't make it", selected: true, onTap: () {}),
          ],
        ),
      ),
      GoldenCell(
        'with icon / count',
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SynkChip(
              label: 'Going',
              icon: SynkIcons.check,
              selected: true,
              onTap: () {},
            ),
            SynkChip(label: 'Going', icon: SynkIcons.check, onTap: () {}),
            SynkChip(label: 'Friends', count: 12, onTap: () {}),
            SynkChip(label: 'Friends', count: 12, selected: true, onTap: () {}),
          ],
        ),
      ),
      const GoldenCell(
        'read-only (no onTap)',
        Wrap(
          spacing: 8,
          children: [
            SynkChip(label: 'Enabled', selected: true),
            SynkChip(label: 'Off'),
          ],
        ),
      ),
      GoldenCell(
        'ellipsis at 110dp',
        SizedBox(
          width: 110,
          child: SynkChip(
            label: 'A very long chip label',
            icon: SynkIcons.users,
            onTap: () {},
          ),
        ),
      ),
    ];

    testWidgets('segmented tabs', (tester) async {
      await expectStateSheetGolden(
        tester,
        'tabs_segmented',
        segmentedCells(),
        size: const Size(420, 480),
        cellWidth: 388,
      );
    });

    testWidgets('pill tabs', (tester) async {
      await expectStateSheetGolden(
        tester,
        'tabs_pills',
        pillCells(),
        size: const Size(420, 590),
        cellWidth: 388,
      );
    });

    testWidgets('chips', (tester) async {
      await expectStateSheetGolden(
        tester,
        'tabs_chips',
        chipCells(),
        size: const Size(420, 290),
        cellWidth: 388,
      );
    });

    testWidgets('tabs and chips at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'tabs_scale13',
        [
          GoldenCell('segmented', segmentedCell()),
          GoldenCell(
            'pills (scroll)',
            SynkPillTabs<String>(
              options: const [
                SynkPillOption(value: 'all', label: 'All', count: 1273),
                SynkPillOption(value: 'teams', label: 'Teams', count: 12),
                SynkPillOption(value: 'users', label: 'Users', count: 1261),
              ],
              selected: 'all',
              onChanged: (_) {},
            ),
          ),
          GoldenCell(
            'pills (wrap)',
            SizedBox(
              width: 300,
              child: SynkPillTabs<String>(
                options: const [
                  SynkPillOption(
                    value: 'all',
                    label: 'All',
                    count: 1273,
                    icon: SynkIcons.users,
                  ),
                  SynkPillOption(value: 'teams', label: 'Teams', count: 12),
                  SynkPillOption(value: 'users', label: 'Users', count: 1261),
                ],
                selected: 'teams',
                scrollable: false,
                onChanged: (_) {},
              ),
            ),
          ),
          GoldenCell(
            'chips',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SynkChip(label: "I'm in", selected: true, onTap: () {}),
                SynkChip(label: "Can't make it", onTap: () {}),
                SynkChip(
                  label: 'Friends',
                  count: 12,
                  icon: SynkIcons.users,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
        size: const Size(420, 400),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });
}

SynkPillOption<String> _toString(SynkPillOption<int> o) =>
    SynkPillOption<String>(
      value: '${o.value}',
      label: o.label,
      count: o.count,
      icon: o.icon,
    );
