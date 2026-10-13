import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/circle_icon_button.dart';
import 'package:date_js/design_system/components/synk_button.dart';
import 'package:date_js/design_system/components/synk_icon_button.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';

import '../support/synk_test_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Alignment alignment = Alignment.topLeft,
}) async {
  await tester.pumpWidget(
    synkApp(
      Align(alignment: alignment, child: child),
      brightness: brightness,
      textScale: textScale,
    ),
  );
}

Material _materialOf(WidgetTester tester, Finder owner) =>
    tester.widget<Material>(
      find.descendant(of: owner, matching: find.byType(Material)).first,
    );

double _dimOpacity(WidgetTester tester, Finder owner) => tester
    .widget<Opacity>(
      find.descendant(of: owner, matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  group('SynkButton behaviour', () {
    testWidgets('fires onPressed on tap', (tester) async {
      var taps = 0;
      await _pump(tester, SynkButton(label: 'Save', onPressed: () => taps++));
      await tester.tap(find.text('Save'));
      expect(taps, 1);
    });

    testWidgets('disabled button ignores taps and is dimmed to 50%', (
      tester,
    ) async {
      await _pump(tester, const SynkButton(label: 'Save'));
      await tester.tap(find.text('Save'), warnIfMissed: false);
      expect(_dimOpacity(tester, find.byType(SynkButton)), 0.5);
    });

    testWidgets('enabled button is fully opaque', (tester) async {
      await _pump(tester, SynkButton(label: 'Save', onPressed: () {}));
      expect(_dimOpacity(tester, find.byType(SynkButton)), 1);
    });

    testWidgets(
      'loading blocks taps, dims, hides the label and shows a spinner',
      (tester) async {
        var taps = 0;
        await _pump(
          tester,
          SynkButton(label: 'Save', loading: true, onPressed: () => taps++),
        );
        await tester.tap(find.byType(SynkButton), warnIfMissed: false);
        expect(taps, 0);
        expect(_dimOpacity(tester, find.byType(SynkButton)), 0.5);
        expect(find.byType(SynkButtonSpinner), findsOneWidget);
        final hidden = tester.widget<Opacity>(
          find
              .ancestor(of: find.text('Save'), matching: find.byType(Opacity))
              .first,
        );
        expect(hidden.opacity, 0);
        expect(
          tester.getSize(find.byType(SynkButtonSpinner)),
          const Size(20, 20),
        );
      },
    );

    testWidgets('loading keeps the width of the idle button', (tester) async {
      await _pump(tester, SynkButton(label: 'Continue', onPressed: () {}));
      final idle = tester.getSize(find.byType(SynkButton));
      await _pump(
        tester,
        SynkButton(label: 'Continue', loading: true, onPressed: () {}),
      );
      expect(tester.getSize(find.byType(SynkButton)), idle);
    });

    testWidgets('spinner is a still arc when animations are disabled', (
      tester,
    ) async {
      await _pump(tester, const SynkButton(label: 'Save', loading: true));
      // synkApp disables animations, so nothing keeps scheduling frames.
      await tester.pumpAndSettle();
      expect(find.byType(SynkButtonSpinner), findsOneWidget);
    });

    testWidgets('semantic label overrides the visible label', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        SynkButton(
          label: 'Go',
          semanticLabel: 'Go to settings',
          onPressed: () {},
        ),
      );
      final node = tester.getSemantics(find.byType(SynkButton));
      expect(
        node,
        isSemantics(
          label: 'Go to settings',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(find.bySemanticsLabel('Go'), findsNothing);
      handle.dispose();
    });

    testWidgets('semantics expose a disabled button while loading', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        SynkButton(label: 'Save', loading: true, onPressed: () {}),
      );
      expect(
        tester.getSemantics(find.byType(SynkButton)),
        isSemantics(
          label: 'Save',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('custom child takes its semantics from the child', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        SynkButton(child: const Text('Custom body'), onPressed: () {}),
      );
      expect(
        tester.getSemantics(find.byType(SynkButton)),
        isSemantics(label: 'Custom body', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('contentColor overrides label and icon colour', (tester) async {
      const custom = Color(0xFF00AA55);
      await _pump(
        tester,
        SynkButton(
          label: 'Save',
          leadingIcon: SynkIcons.check,
          contentColor: custom,
          onPressed: () {},
        ),
      );
      expect(tester.widget<Text>(find.text('Save')).style?.color, isNull);
      final style = DefaultTextStyle.of(tester.element(find.text('Save')))
          .style;
      expect(style.color, custom);
      expect(tester.widget<SynkIcon>(find.byType(SynkIcon)).color, custom);
    });

    testWidgets('leading icon is 16dp with a gap of 8 to the label', (
      tester,
    ) async {
      await _pump(
        tester,
        SynkButton(label: 'Add', leadingIcon: SynkIcons.add, onPressed: () {}),
      );
      expect(tester.getSize(find.byType(SynkIcon)), const Size(16, 16));
      final gap =
          tester.getTopLeft(find.text('Add')).dx -
          tester.getTopRight(find.byType(SynkIcon)).dx;
      expect(gap, closeTo(8, 0.5));
    });

    testWidgets('label is a single line', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 120,
          child: SynkButton(
            label: 'A rather long button label that cannot fit',
            onPressed: () {},
            expand: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SynkButton)).width, 120);
      expect(tester.getSize(find.byType(SynkButton)).height, 44);
    });

    testWidgets('needs a label, child or icon, and icon-only needs a label', (
      tester,
    ) async {
      expect(() => SynkButton(onPressed: () {}), throwsAssertionError);
      expect(
        () => SynkButton(leadingIcon: SynkIcons.add, onPressed: () {}),
        throwsAssertionError,
      );
    });

    testWidgets('ripple is tinted per variant', (tester) async {
      const colors = SynkColors.light;
      Color splash(SynkButtonVariant v) {
        return SynkButtonColors.resolve(colors, v).ripple;
      }

      expect(splash(SynkButtonVariant.primary), const Color(0x38FFFFFF));
      expect(splash(SynkButtonVariant.destructive), const Color(0x38FFFFFF));
      expect(
        splash(SynkButtonVariant.secondary),
        colors.primary.withValues(alpha: 0.20),
      );
      expect(
        splash(SynkButtonVariant.outline),
        colors.primary.withValues(alpha: 0.20),
      );
      expect(
        splash(SynkButtonVariant.ghost),
        colors.primary.withValues(alpha: 0.20),
      );
      expect(splash(SynkButtonVariant.glass), const Color(0x26FFFFFF));

      await _pump(tester, SynkButton(label: 'Save', onPressed: () {}));
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.splashColor, splash(SynkButtonVariant.primary));
    });
  });

  group('SynkButton appearance', () {
    final sizes = <SynkButtonSize, double>{
      SynkButtonSize.sm: 36,
      SynkButtonSize.md: 44,
      SynkButtonSize.lg: 50,
    };
    for (final entry in sizes.entries) {
      testWidgets('${entry.key.name} is ${entry.value}dp tall', (tester) async {
        await _pump(
          tester,
          SynkButton(label: 'Save', size: entry.key, onPressed: () {}),
        );
        expect(tester.getSize(find.byType(SynkButton)).height, entry.value);
      });
    }

    testWidgets('horizontal padding follows the size', (tester) async {
      for (final (size, pad) in [
        (SynkButtonSize.sm, 14.0),
        (SynkButtonSize.md, 20.0),
        (SynkButtonSize.lg, 24.0),
      ]) {
        await _pump(
          tester,
          SynkButton(label: 'Save', size: size, onPressed: () {}),
        );
        final inset =
            tester.getTopLeft(find.text('Save')).dx -
            tester.getTopLeft(find.byType(SynkButton)).dx;
        expect(inset, closeTo(pad, 0.6), reason: size.name);
      }
    });

    testWidgets('icon size is a 40dp circle', (tester) async {
      await _pump(
        tester,
        SynkButton(
          size: SynkButtonSize.icon,
          leadingIcon: SynkIcons.add,
          semanticLabel: 'Add',
          variant: SynkButtonVariant.secondary,
          onPressed: () {},
        ),
      );
      expect(tester.getSize(find.byType(SynkButton)), const Size(40, 40));
      expect(
        _materialOf(tester, find.byType(SynkButton)).shape,
        isA<CircleBorder>(),
      );
    });

    testWidgets(
      'every variant and size has one shape: a pill, or a circle for icons',
      (tester) async {
        for (final variant in SynkButtonVariant.values) {
          for (final size in SynkButtonSize.values) {
            final iconOnly = size == SynkButtonSize.icon;
            await _pump(
              tester,
              SynkButton(
                label: iconOnly ? null : 'Save',
                leadingIcon: iconOnly ? SynkIcons.close : null,
                semanticLabel: iconOnly ? 'Close' : null,
                variant: variant,
                size: size,
                onPressed: () {},
              ),
            );
            final shape = _materialOf(tester, find.byType(SynkButton)).shape;
            expect(
              shape,
              iconOnly ? isA<CircleBorder>() : isA<StadiumBorder>(),
              reason: '${variant.name} / ${size.name}',
            );
          }
        }
      },
    );

    testWidgets('expand fills the available width', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: SynkButton(label: 'Continue', expand: true, onPressed: () {}),
        ),
      );
      expect(tester.getSize(find.byType(SynkButton)).width, 300);
    });

    testWidgets('without expand the button hugs its content', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SynkButton(label: 'Go', onPressed: () {}),
          ),
        ),
      );
      expect(tester.getSize(find.byType(SynkButton)).width, lessThan(120));
    });

    testWidgets('fills and content colours per variant (light)', (
      tester,
    ) async {
      const c = SynkColors.light;
      final expected = <SynkButtonVariant, ({Color? bg, Color fg})>{
        SynkButtonVariant.primary: (bg: c.primary, fg: c.primaryForeground),
        SynkButtonVariant.destructive: (
          bg: c.destructive,
          fg: c.primaryForeground,
        ),
        SynkButtonVariant.secondary: (
          bg: c.secondary,
          fg: c.secondaryForeground,
        ),
        SynkButtonVariant.outline: (bg: null, fg: c.foreground),
        SynkButtonVariant.ghost: (bg: null, fg: c.foreground),
        SynkButtonVariant.glass: (bg: c.glassOverlay, fg: c.foreground),
        SynkButtonVariant.ink: (bg: c.ink, fg: c.inkForeground),
        SynkButtonVariant.soft: (bg: synkSoftFill(c), fg: c.foreground),
      };
      for (final entry in expected.entries) {
        await _pump(
          tester,
          SynkButton(label: 'Save', variant: entry.key, onPressed: () {}),
        );
        final material = _materialOf(tester, find.byType(SynkButton));
        expect(
          material.color,
          entry.value.bg ?? Colors.transparent,
          reason: '${entry.key.name} fill',
        );
        final style = DefaultTextStyle.of(tester.element(find.text('Save')))
            .style;
        expect(style.color, entry.value.fg, reason: '${entry.key.name} text');
      }
    });

    testWidgets('outline draws a 1dp border, others none', (tester) async {
      await _pump(
        tester,
        SynkButton(
          label: 'Save',
          variant: SynkButtonVariant.outline,
          onPressed: () {},
        ),
      );
      final shape =
          _materialOf(tester, find.byType(SynkButton)).shape! as OutlinedBorder;
      expect(shape.side.width, 1);
      expect(shape.side.color, SynkColors.light.border);

      await _pump(tester, SynkButton(label: 'Save', onPressed: () {}));
      final plain =
          _materialOf(tester, find.byType(SynkButton)).shape! as OutlinedBorder;
      expect(plain.side, BorderSide.none);
    });

    testWidgets('spinner colour per variant', (tester) async {
      const c = SynkColors.light;
      final expected = <SynkButtonVariant, Color>{
        SynkButtonVariant.primary: c.primaryForeground,
        SynkButtonVariant.destructive: c.primaryForeground,
        SynkButtonVariant.glass: c.foreground,
        SynkButtonVariant.ink: c.inkForeground,
        SynkButtonVariant.secondary: c.primary,
        SynkButtonVariant.outline: c.primary,
        SynkButtonVariant.ghost: c.primary,
        SynkButtonVariant.soft: c.primary,
      };
      for (final entry in expected.entries) {
        await _pump(
          tester,
          SynkButton(label: 'Save', variant: entry.key, loading: true),
        );
        expect(
          tester
              .widget<SynkButtonSpinner>(find.byType(SynkButtonSpinner))
              .color,
          entry.value,
          reason: entry.key.name,
        );
      }
    });

    testWidgets('dark theme resolves dark tokens', (tester) async {
      await _pump(
        tester,
        SynkButton(
          label: 'Save',
          variant: SynkButtonVariant.ink,
          onPressed: () {},
        ),
        brightness: Brightness.dark,
      );
      final material = _materialOf(tester, find.byType(SynkButton));
      expect(material.color, SynkColors.dark.ink);
    });

    testWidgets('survives text scale 1.3 in every size and variant', (
      tester,
    ) async {
      useGoldenViewport(tester, size: const Size(360, 900));
      await _pump(
        tester,
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final size in SynkButtonSize.values)
                for (final variant in SynkButtonVariant.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SynkButton(
                      label: size == SynkButtonSize.icon ? null : 'Continue',
                      leadingIcon: SynkIcons.check,
                      semanticLabel: 'Continue',
                      size: size,
                      variant: variant,
                      onPressed: () {},
                    ),
                  ),
            ],
          ),
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('long label in a narrow expanded button does not overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 140,
          child: Row(
            children: [
              Expanded(
                child: SynkButton(
                  label: 'Create a brand new group',
                  size: SynkButtonSize.lg,
                  expand: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays out in a horizontal list (unbounded width)', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              SynkButton(label: 'One', onPressed: () {}),
              SynkButton(label: 'Two', onPressed: () {}),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SynkIconButton', () {
    testWidgets('defaults to a 40dp ghost circle with an 18dp icon', (
      tester,
    ) async {
      await _pump(
        tester,
        SynkIconButton(
          icon: SynkIcons.settings,
          semanticLabel: 'Settings',
          onPressed: () {},
        ),
      );
      expect(tester.getSize(find.byType(SynkIconButton)), const Size(40, 40));
      final icon = tester.widget<SynkIcon>(find.byType(SynkIcon));
      expect(icon.size, 18);
      expect(icon.strokeWidth, 1.8);
      expect(icon.color, SynkColors.light.foreground);
      final material = _materialOf(tester, find.byType(SynkIconButton));
      expect(material.color, Colors.transparent);
      expect(material.shape, isA<CircleBorder>());
    });

    testWidgets('size, iconSize, strokeWidth and tint are applied', (
      tester,
    ) async {
      const tint = Color(0xFFFF8800);
      await _pump(
        tester,
        SynkIconButton(
          icon: SynkIcons.add,
          semanticLabel: 'Add',
          size: 32,
          iconSize: 14,
          strokeWidth: 2.4,
          tint: tint,
          variant: SynkButtonVariant.secondary,
          onPressed: () {},
        ),
      );
      expect(tester.getSize(find.byType(SynkIconButton)), const Size(32, 32));
      final icon = tester.widget<SynkIcon>(find.byType(SynkIcon));
      expect(icon.size, 14);
      expect(icon.strokeWidth, 2.4);
      expect(icon.color, tint);
    });

    testWidgets('icon takes the variant content colour', (tester) async {
      await _pump(
        tester,
        SynkIconButton(
          icon: SynkIcons.add,
          semanticLabel: 'Add',
          variant: SynkButtonVariant.primary,
          onPressed: () {},
        ),
      );
      expect(
        tester.widget<SynkIcon>(find.byType(SynkIcon)).color,
        SynkColors.light.primaryForeground,
      );
    });

    testWidgets('taps fire, disabled and loading block them', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        SynkIconButton(
          icon: SynkIcons.add,
          semanticLabel: 'Add',
          onPressed: () => taps++,
        ),
      );
      await tester.tap(find.byType(SynkIconButton));
      expect(taps, 1);

      await _pump(
        tester,
        SynkIconButton(
          icon: SynkIcons.add,
          semanticLabel: 'Add',
          loading: true,
          onPressed: () => taps++,
        ),
      );
      await tester.tap(find.byType(SynkIconButton), warnIfMissed: false);
      expect(taps, 1);
      expect(find.byType(SynkButtonSpinner), findsOneWidget);

      await _pump(
        tester,
        const SynkIconButton(icon: SynkIcons.add, semanticLabel: 'Add'),
      );
      expect(_dimOpacity(tester, find.byType(SynkIconButton)), 0.5);
    });

    testWidgets('exposes its label as a button', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        SynkIconButton(
          icon: SynkIcons.settings,
          semanticLabel: 'Open settings',
          onPressed: () {},
        ),
      );
      expect(
        tester.getSemantics(find.byType(SynkIconButton)),
        isSemantics(
          label: 'Open settings',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('CircleIconButton', () {
    testWidgets('is a 44dp circle with a 20dp icon by default', (tester) async {
      await _pump(
        tester,
        CircleIconButton(
          icon: SynkIcons.arrowRight,
          semanticLabel: 'Next',
          onPressed: () {},
        ),
      );
      expect(tester.getSize(find.byType(CircleIconButton)), const Size(44, 44));
      expect(tester.getSize(find.byType(SynkIcon)), const Size(20, 20));
      final material = _materialOf(tester, find.byType(CircleIconButton));
      expect(material.color, SynkColors.light.ink);
      expect(material.shape, isA<CircleBorder>());
      expect(
        tester.widget<SynkIcon>(find.byType(SynkIcon)).color,
        SynkColors.light.inkForeground,
      );
    });

    testWidgets('tones map to ink / outline / soft', (tester) async {
      const c = SynkColors.light;
      for (final tone in CircleButtonTone.values) {
        await _pump(
          tester,
          CircleIconButton(
            icon: SynkIcons.add,
            semanticLabel: 'Add',
            tone: tone,
            onPressed: () {},
          ),
        );
        final material = _materialOf(tester, find.byType(CircleIconButton));
        switch (tone) {
          case CircleButtonTone.ink:
            expect(material.color, c.ink);
          case CircleButtonTone.outline:
            expect(material.color, Colors.transparent);
            expect((material.shape! as OutlinedBorder).side.color, c.border);
          case CircleButtonTone.soft:
            expect(material.color, synkSoftFill(c));
        }
      }
    });

    testWidgets('custom diameter and icon size', (tester) async {
      await _pump(
        tester,
        CircleIconButton(
          icon: SynkIcons.add,
          semanticLabel: 'Add',
          diameter: 56,
          iconSize: 26,
          onPressed: () {},
        ),
      );
      expect(tester.getSize(find.byType(CircleIconButton)), const Size(56, 56));
      expect(tester.getSize(find.byType(SynkIcon)), const Size(26, 26));
    });

    testWidgets('badge is pinned to the top-right and does not eat taps', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(20),
          child: CircleIconButton(
            icon: SynkIcons.mail,
            semanticLabel: 'Inbox',
            onPressed: () => taps++,
            badge: Container(
              key: const ValueKey('badge'),
              width: 12,
              height: 12,
              color: Colors.red,
            ),
          ),
        ),
      );
      final badge = tester.getRect(find.byKey(const ValueKey('badge')));
      final button = tester.getRect(find.byType(CircleIconButton));
      expect(badge.top, lessThan(button.top + 4));
      expect(badge.right, greaterThan(button.right - 14));
      await tester.tapAt(badge.center);
      expect(taps, 0, reason: 'badge itself is not interactive');
      await tester.tapAt(button.center);
      expect(taps, 1);
    });

    testWidgets(
      'loading shows a spinner in place of the icon and blocks taps',
      (tester) async {
        var taps = 0;
        await _pump(
          tester,
          CircleIconButton(
            icon: SynkIcons.add,
            semanticLabel: 'Add',
            loading: true,
            onPressed: () => taps++,
          ),
        );
        await tester.tap(find.byType(CircleIconButton), warnIfMissed: false);
        expect(taps, 0);
        expect(find.byType(SynkButtonSpinner), findsOneWidget);
        expect(
          tester.getSize(find.byType(SynkButtonSpinner)).width,
          lessThanOrEqualTo(20),
        );
        expect(
          tester
              .widget<Opacity>(
                find
                    .ancestor(
                      of: find.byType(SynkIcon),
                      matching: find.byType(Opacity),
                    )
                    .first,
              )
              .opacity,
          0,
        );
      },
    );

    testWidgets('disabled is dimmed to 50% and inert', (tester) async {
      await _pump(
        tester,
        const CircleIconButton(icon: SynkIcons.add, semanticLabel: 'Add'),
      );
      expect(_dimOpacity(tester, find.byType(CircleIconButton)), 0.5);
    });

    testWidgets('exposes its label as a button', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        CircleIconButton(
          icon: SynkIcons.add,
          semanticLabel: 'Create group',
          onPressed: () {},
        ),
      );
      expect(
        tester.getSemantics(find.byType(CircleIconButton)),
        isSemantics(label: 'Create group', isButton: true, isEnabled: true),
      );
      handle.dispose();
    });
  });

  group('golden state sheets', () {
    List<GoldenCell> variantRows() => [
      for (final variant in SynkButtonVariant.values)
        GoldenCell(
          variant.name,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SynkButton(label: 'Save', variant: variant, onPressed: () {}),
              const SizedBox(width: 8),
              SynkButton(
                label: 'Add',
                leadingIcon: SynkIcons.add,
                variant: variant,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              SynkButton(label: 'Off', variant: variant),
              const SizedBox(width: 8),
              SynkButton(
                label: 'Wait',
                variant: variant,
                loading: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
    ];

    List<GoldenCell> sizeRows() => [
      for (final variant in [
        SynkButtonVariant.primary,
        SynkButtonVariant.ink,
        SynkButtonVariant.soft,
        SynkButtonVariant.outline,
      ])
        GoldenCell(
          '${variant.name} sm / md / lg / icon',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SynkButton(
                label: 'Small',
                size: SynkButtonSize.sm,
                variant: variant,
                onPressed: () {},
              ),
              SynkButton(label: 'Medium', variant: variant, onPressed: () {}),
              SynkButton(
                label: 'Large',
                size: SynkButtonSize.lg,
                variant: variant,
                onPressed: () {},
              ),
              SynkButton(
                size: SynkButtonSize.icon,
                leadingIcon: SynkIcons.add,
                semanticLabel: 'Add',
                variant: variant,
                onPressed: () {},
              ),
            ],
          ),
        ),
      GoldenCell(
        'expand (primary lg / ink md / outline sm)',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SynkButton(
              label: 'Continue with Google',
              leadingIcon: SynkIcons.mail,
              size: SynkButtonSize.lg,
              expand: true,
              onPressed: () {},
            ),
            const SizedBox(height: 8),
            SynkButton(
              label: 'Create group',
              variant: SynkButtonVariant.ink,
              expand: true,
              onPressed: () {},
            ),
            const SizedBox(height: 8),
            SynkButton(
              label: 'Not now',
              variant: SynkButtonVariant.outline,
              size: SynkButtonSize.sm,
              expand: true,
              onPressed: () {},
            ),
            const SizedBox(height: 8),
            SynkButton(
              label: 'Saving',
              variant: SynkButtonVariant.ink,
              expand: true,
              loading: true,
              onPressed: () {},
            ),
          ],
        ),
      ),
      GoldenCell(
        'contentColor / destructive text / long label (ellipsis at 150)',
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SynkButton(
              label: 'Sign out',
              leadingIcon: SynkIcons.signOut,
              variant: SynkButtonVariant.ghost,
              contentColor: SynkColors.light.destructive,
              onPressed: () {},
            ),
            SizedBox(
              width: 150,
              child: SynkButton(
                label: 'A very long label that is cut',
                variant: SynkButtonVariant.secondary,
                expand: true,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    ];

    List<GoldenCell> iconRows() => [
      for (final variant in SynkButtonVariant.values)
        GoldenCell(
          'SynkIconButton ${variant.name}',
          Row(
            children: [
              SynkIconButton(
                icon: SynkIcons.settings,
                semanticLabel: 'Settings',
                variant: variant,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              SynkIconButton(
                icon: SynkIcons.settings,
                semanticLabel: 'Settings',
                variant: variant,
              ),
              const SizedBox(width: 8),
              SynkIconButton(
                icon: SynkIcons.settings,
                semanticLabel: 'Settings',
                variant: variant,
                loading: true,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              SynkIconButton(
                icon: SynkIcons.heart,
                semanticLabel: 'Like',
                variant: variant,
                tint: const Color(0xFFE11D48),
                onPressed: () {},
              ),
            ],
          ),
        ),
      for (final tone in CircleButtonTone.values)
        GoldenCell(
          'CircleIconButton ${tone.name} (default / disabled / loading / badge / 56)',
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Row(
              children: [
                CircleIconButton(
                  icon: SynkIcons.arrowRight,
                  semanticLabel: 'Next',
                  tone: tone,
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                CircleIconButton(
                  icon: SynkIcons.arrowRight,
                  semanticLabel: 'Next',
                  tone: tone,
                ),
                const SizedBox(width: 10),
                CircleIconButton(
                  icon: SynkIcons.arrowRight,
                  semanticLabel: 'Next',
                  tone: tone,
                  loading: true,
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                CircleIconButton(
                  icon: SynkIcons.mail,
                  semanticLabel: 'Inbox',
                  tone: tone,
                  onPressed: () {},
                  badge: Builder(
                    builder: (context) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: SynkColors.light.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleIconButton(
                  icon: SynkIcons.play,
                  semanticLabel: 'Play',
                  tone: tone,
                  diameter: 56,
                  iconSize: 24,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
    ];

    testWidgets('variants', (tester) async {
      await expectStateSheetGolden(
        tester,
        'buttons_variants',
        variantRows(),
        size: const Size(420, 650),
        cellWidth: 388,
      );
    });

    testWidgets('sizes, expand and content colour', (tester) async {
      await expectStateSheetGolden(
        tester,
        'buttons_sizes',
        sizeRows(),
        size: const Size(420, 680),
        cellWidth: 388,
      );
    });

    testWidgets('icon and circle buttons', (tester) async {
      await expectStateSheetGolden(
        tester,
        'buttons_icon',
        iconRows(),
        size: const Size(420, 880),
        cellWidth: 388,
      );
    });

    testWidgets('variants at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'buttons_variants_scale13',
        [
          for (final variant in SynkButtonVariant.values)
            GoldenCell(
              variant.name,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SynkButton(label: 'Save', variant: variant, onPressed: () {}),
                  SynkButton(
                    label: 'Add',
                    leadingIcon: SynkIcons.add,
                    size: SynkButtonSize.lg,
                    variant: variant,
                    onPressed: () {},
                  ),
                  SynkButton(
                    label: 'Small',
                    size: SynkButtonSize.sm,
                    variant: variant,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
        ],
        size: const Size(420, 760),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });
}
