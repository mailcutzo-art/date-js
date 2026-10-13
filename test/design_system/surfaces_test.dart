import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/pastel_card.dart';
import 'package:date_js/design_system/components/section_label.dart';
import 'package:date_js/design_system/components/synk_badge.dart';
import 'package:date_js/design_system/components/synk_card.dart';
import 'package:date_js/design_system/components/synk_separator.dart';
import 'package:date_js/design_system/components/synk_text.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_palette.dart';
import 'package:date_js/design_system/tokens/synk_radius.dart';
import 'package:date_js/design_system/tokens/synk_typography.dart';

import '../support/synk_test_harness.dart';

Widget _top(Widget child) => Align(alignment: Alignment.topLeft, child: child);

BoxDecoration _decorationOf(WidgetTester tester, Type owner) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byType(owner), matching: find.byType(Container)),
  );
  return container.decoration! as BoxDecoration;
}

double _opacityOf(WidgetTester tester, Finder within) => tester
    .widget<AnimatedOpacity>(
      find.descendant(of: within, matching: find.byType(AnimatedOpacity)),
    )
    .opacity;

Widget _sampleCard({VoidCallback? onTap}) => SynkCard(
  onTap: onTap,
  child: const Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SynkCardHeader(
        children: [
          SynkCardTitle('Weekly digest'),
          SynkCardDescription('Every Monday, in your inbox.'),
        ],
      ),
      SynkCardContent(
        child: SynkText('Watch time, streaks and the leaderboard.'),
      ),
      SynkCardFooter(
        children: [
          SynkBadge(text: 'Pro', small: true),
          SynkBadge(text: 'New', variant: SynkBadgeVariant.outline),
        ],
      ),
    ],
  ),
);

void main() {
  group('SynkCard', () {
    testWidgets('paints card colour, 18dp radius and a 1dp border', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(_top(const SynkCard(child: SizedBox(width: 80, height: 40)))),
      );
      var decoration = _decorationOf(tester, SynkCard);
      expect(decoration.color, SynkColors.light.card);
      expect(decoration.borderRadius, SynkRadius.lgAll);
      final border = decoration.border! as Border;
      expect(border.top.width, 1);
      expect(border.top.color, SynkColors.light.border);

      await tester.pumpWidget(
        synkApp(
          _top(const SynkCard(child: SizedBox(width: 80, height: 40))),
          brightness: Brightness.dark,
        ),
      );
      decoration = _decorationOf(tester, SynkCard);
      expect(decoration.color, SynkColors.dark.card);
      expect((decoration.border! as Border).top.color, SynkColors.dark.border);
    });

    testWidgets('honours radius, colour, padding and bordered', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SynkCard(
              radius: SynkRadius.xxlAll,
              color: Color(0xFF123456),
              padding: EdgeInsets.all(10),
              bordered: false,
              child: SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      );
      final decoration = _decorationOf(tester, SynkCard);
      expect(decoration.color, const Color(0xFF123456));
      expect(decoration.borderRadius, SynkRadius.xxlAll);
      expect(decoration.border, isNull);
      expect(tester.getSize(find.byType(SynkCard)), const Size(100, 60));
    });

    testWidgets('an empty card still renders', (tester) async {
      await tester.pumpWidget(synkApp(_top(const SynkCard())));
      expect(tester.takeException(), isNull);
      expect(find.byType(SynkCard), findsOneWidget);
    });

    testWidgets('onTap fires, dims while pressed and exposes a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(synkApp(_top(_sampleCard(onTap: () => taps++))));
      expect(_opacityOf(tester, find.byType(SynkCard)), 1);
      expect(
        tester.getSemantics(find.byType(SynkCard)),
        isSemantics(isButton: true, hasTapAction: true),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SynkCard)),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(_opacityOf(tester, find.byType(SynkCard)), 0.85);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 120));
      expect(_opacityOf(tester, find.byType(SynkCard)), 1);
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a card without onTap is not a button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(synkApp(_top(_sampleCard())));
      expect(
        find.descendant(
          of: find.byType(SynkCard),
          matching: find.byType(AnimatedOpacity),
        ),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.text('Weekly digest')),
        isNot(isSemantics(isButton: true)),
      );
      handle.dispose();
    });

    testWidgets('header, content and footer carry the specified padding', (
      tester,
    ) async {
      await tester.pumpWidget(synkApp(_top(_sampleCard())));
      EdgeInsetsGeometry paddingOf(Type type) => tester
          .widget<Padding>(
            find
                .descendant(
                  of: find.byType(type),
                  matching: find.byType(Padding),
                )
                .first,
          )
          .padding;
      expect(
        paddingOf(SynkCardHeader),
        const EdgeInsets.fromLTRB(20, 20, 20, 8),
      );
      expect(
        paddingOf(SynkCardContent),
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );
      expect(
        paddingOf(SynkCardFooter),
        const EdgeInsets.fromLTRB(20, 8, 20, 20),
      );
    });

    testWidgets(
      'header stacks children 6dp apart, footer lays them 8dp apart',
      (tester) async {
        await tester.pumpWidget(synkApp(_top(_sampleCard())));
        final title = tester.getRect(find.text('Weekly digest'));
        final description = tester.getRect(
          find.text('Every Monday, in your inbox.'),
        );
        // The gap is 6dp between the two text boxes (line-height padding sits inside them).
        expect(description.top - title.bottom, closeTo(6, 0.01));
        final first = tester.getRect(find.byType(SynkBadge).first);
        final second = tester.getRect(find.byType(SynkBadge).last);
        expect(second.left - first.right, closeTo(8, 0.01));
      },
    );

    testWidgets(
      'title is a heading in the card foreground, description is muted',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(synkApp(_top(_sampleCard())));
        expect(
          tester.getSemantics(find.text('Weekly digest')),
          isSemantics(isHeader: true, label: 'Weekly digest'),
        );
        final title = tester.widget<Text>(find.text('Weekly digest'));
        expect(title.style!.fontSize, 18);
        expect(title.style!.fontWeight, FontWeight.w600);
        expect(title.style!.color, SynkColors.light.cardForeground);
        final description = tester.widget<Text>(
          find.text('Every Monday, in your inbox.'),
        );
        expect(description.style!.color, SynkColors.light.mutedForeground);
        handle.dispose();
      },
    );

    testWidgets('golden: cards', (tester) async {
      await expectStateSheetGolden(
        tester,
        'surfaces_cards',
        [
          GoldenCell('default', _sampleCard()),
          GoldenCell('tappable', _sampleCard(onTap: () {})),
          const GoldenCell(
            'bordered: false, custom radius 28',
            SizedBox(
              width: double.infinity,
              child: SynkCard(
                bordered: false,
                radius: SynkRadius.xxlAll,
                padding: EdgeInsets.all(20),
                child: SynkText('Borderless card with padding 20'),
              ),
            ),
          ),
          const GoldenCell(
            'custom colour',
            SizedBox(
              width: double.infinity,
              child: SynkCard(
                color: Color(0xFFFFF4E3),
                padding: EdgeInsets.all(20),
                child: SynkText('Tinted card', color: Color(0xFF0A0A0A)),
              ),
            ),
          ),
        ],
        size: const Size(420, 640),
        cellWidth: 388,
      );
    });

    testWidgets('golden: cards at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'surfaces_cards_scale13',
        [
          GoldenCell('default', _sampleCard()),
          GoldenCell('tappable', _sampleCard(onTap: () {})),
        ],
        size: const Size(420, 590),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });

  group('PastelCard', () {
    testWidgets('fills with the surface of every tone, light and dark', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        final colors = brightness == Brightness.dark
            ? SynkColors.dark
            : SynkColors.light;
        for (final tone in SynkTone.values) {
          await tester.pumpWidget(
            synkApp(
              _top(
                PastelCard(
                  tone: tone,
                  child: const SizedBox(width: 80, height: 40),
                ),
              ),
              brightness: brightness,
            ),
          );
          final decoration = _decorationOf(tester, PastelCard);
          expect(
            decoration.color,
            colors.toneSurface(tone),
            reason: '$tone / $brightness',
          );
        }
      }
      // The tones are the reference pastels in light mode.
      expect(
        SynkColors.light.toneSurface(SynkTone.lavender),
        const Color(0xFFF2F5FF),
      );
      expect(
        SynkColors.light.toneSurface(SynkTone.ice),
        const Color(0xFFE6F3FA),
      );
      expect(
        SynkColors.light.toneSurface(SynkTone.blush),
        const Color(0xFFFBECF1),
      );
    });

    testWidgets(
      'has 28dp radius and 20dp padding by default, no pastel outline',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            _top(const PastelCard(child: SizedBox(width: 80, height: 40))),
          ),
        );
        final decoration = _decorationOf(tester, PastelCard);
        expect(decoration.borderRadius, BorderRadius.circular(SynkRadius.xxl));
        expect(decoration.border, isNull);
        expect(tester.getSize(find.byType(PastelCard)), const Size(120, 80));
      },
    );

    testWidgets('neutral tone keeps a hairline outline against the page', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const PastelCard(
              tone: SynkTone.neutral,
              child: SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      );
      final border = _decorationOf(tester, PastelCard).border! as Border;
      expect(border.top.color, SynkColors.light.border);
    });

    testWidgets('radius and padding are configurable', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const PastelCard(
              radius: 12,
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: SizedBox(width: 80, height: 40),
            ),
          ),
        ),
      );
      expect(
        _decorationOf(tester, PastelCard).borderRadius,
        BorderRadius.circular(12),
      );
      expect(tester.getSize(find.byType(PastelCard)), const Size(88, 56));
    });

    testWidgets('onTap fires and dims; semanticLabel names the button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        synkApp(
          _top(
            PastelCard(
              onTap: () => taps++,
              semanticLabel: 'Storage card',
              child: const SizedBox(width: 120, height: 60),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PastelCard)),
        isSemantics(isButton: true, hasTapAction: true, label: 'Storage card'),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PastelCard)),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(_opacityOf(tester, find.byType(PastelCard)), 0.85);
      await gesture.up();
      await tester.pump();
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a static card with a label is a labelled container', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          _top(
            const PastelCard(
              semanticLabel: 'Summary',
              child: SizedBox(width: 120, height: 60),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(PastelCard));
      expect(node, isSemantics(label: 'Summary'));
      expect(node, isNot(isSemantics(isButton: true)));
      handle.dispose();
    });

    testWidgets('paints the background behind the child inside the clip', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const PastelCard(
              background: ColoredBox(
                key: ValueKey('art'),
                color: Color(0x33000000),
              ),
              child: SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      );
      // The art fills the whole card (padding included), not just the content box.
      expect(
        tester.getSize(find.byKey(const ValueKey('art'))),
        tester.getSize(find.byType(PastelCard)),
      );
      expect(tester.getSize(find.byType(PastelCard)), const Size(140, 90));
      expect(
        tester
            .widget<Container>(
              find.descendant(
                of: find.byType(PastelCard),
                matching: find.byType(Container),
              ),
            )
            .clipBehavior,
        Clip.antiAlias,
      );
    });

    testWidgets('golden: every tone, with background and tappable', (
      tester,
    ) async {
      Widget sample(SynkTone tone, {Widget? background, VoidCallback? onTap}) =>
          PastelCard(
            tone: tone,
            background: background,
            onTap: onTap,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SynkText('Movie night', variant: SynkTextVariant.cardTitle),
                SizedBox(height: 4),
                SynkText(
                  'Friday, 9 pm · 4 going',
                  variant: SynkTextVariant.muted,
                ),
              ],
            ),
          );
      await expectStateSheetGolden(
        tester,
        'surfaces_pastel',
        [
          for (final tone in SynkTone.values)
            GoldenCell(tone.name, sample(tone)),
          GoldenCell('tappable ice', sample(SynkTone.ice, onTap: () {})),
          GoldenCell(
            'with background art',
            sample(
              SynkTone.blush,
              background: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: SynkIcon(
                    SynkIcons.heart,
                    size: 56,
                    color: Color(0x33000000),
                  ),
                ),
              ),
            ),
          ),
        ],
        size: const Size(420, 780),
        cellWidth: 388,
      );
    });

    testWidgets('golden: pastel card at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'surfaces_pastel_scale13',
        [
          for (final tone in [SynkTone.lavender, SynkTone.ice])
            GoldenCell(
              tone.name,
              PastelCard(
                tone: tone,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SynkText('Movie night', variant: SynkTextVariant.cardTitle),
                    SizedBox(height: 4),
                    SynkText(
                      'Friday, 9 pm · 4 going',
                      variant: SynkTextVariant.muted,
                    ),
                  ],
                ),
              ),
            ),
        ],
        size: const Size(420, 320),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });

  group('SynkBadge', () {
    ({Color bg, Color fg}) colorsOf(WidgetTester tester) {
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(SynkBadge),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(SynkBadge),
          matching: find.byType(Text),
        ),
      );
      return (bg: decoration.color!, fg: text.style!.color!);
    }

    testWidgets(
      'variants resolve to the Android colour pairs and the ink pill',
      (tester) async {
        for (final brightness in Brightness.values) {
          final c = brightness == Brightness.dark
              ? SynkColors.dark
              : SynkColors.light;
          final expected = <SynkBadgeVariant, ({Color bg, Color fg})>{
            SynkBadgeVariant.primary: (bg: c.primary, fg: c.primaryForeground),
            SynkBadgeVariant.secondary: (
              bg: c.secondary,
              fg: c.secondaryForeground,
            ),
            SynkBadgeVariant.muted: (bg: c.muted, fg: c.mutedForeground),
            SynkBadgeVariant.outline: (
              bg: Colors.transparent,
              fg: c.foreground,
            ),
            SynkBadgeVariant.ink: (bg: c.ink, fg: c.inkForeground),
          };
          for (final entry in expected.entries) {
            await tester.pumpWidget(
              synkApp(
                _top(SynkBadge(text: 'Label', variant: entry.key)),
                brightness: brightness,
              ),
            );
            final actual = colorsOf(tester);
            expect(
              actual.bg,
              entry.value.bg,
              reason: '${entry.key} $brightness bg',
            );
            expect(
              actual.fg,
              entry.value.fg,
              reason: '${entry.key} $brightness fg',
            );
          }
        }
      },
    );

    testWidgets(
      'destructive, success and amber are tinted or inverted per theme',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            _top(
              const SynkBadge(text: 'x', variant: SynkBadgeVariant.destructive),
            ),
          ),
        );
        expect(colorsOf(tester).bg, SynkColors.light.destructive);
        expect(colorsOf(tester).fg, SynkColors.light.primaryForeground);

        await tester.pumpWidget(
          synkApp(
            _top(
              const SynkBadge(text: 'x', variant: SynkBadgeVariant.destructive),
            ),
            brightness: Brightness.dark,
          ),
        );
        expect(colorsOf(tester).bg, SynkColors.dark.destructive);
        // Light destructive red in dark mode takes dark text for contrast.
        expect(colorsOf(tester).fg, SynkColors.dark.inkForeground);

        await tester.pumpWidget(
          synkApp(
            _top(const SynkBadge(text: 'x', variant: SynkBadgeVariant.success)),
          ),
        );
        expect(
          colorsOf(tester).bg,
          SynkPalette.success.withValues(alpha: 0.15),
        );
        await tester.pumpWidget(
          synkApp(
            _top(const SynkBadge(text: 'x', variant: SynkBadgeVariant.amber)),
          ),
        );
        expect(colorsOf(tester).bg, SynkPalette.amber.withValues(alpha: 0.15));
      },
    );

    testWidgets(
      'amber and success label colours stay legible (4.5:1) on their tint',
      (tester) async {
        double contrast(Color a, Color b) {
          final l1 = a.computeLuminance();
          final l2 = b.computeLuminance();
          return (l1 > l2 ? l1 + 0.05 : l2 + 0.05) /
              (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
        }

        for (final brightness in Brightness.values) {
          final page = brightness == Brightness.dark
              ? SynkColors.dark.background
              : SynkColors.light.card;
          for (final variant in [
            SynkBadgeVariant.success,
            SynkBadgeVariant.amber,
          ]) {
            await tester.pumpWidget(
              synkApp(
                _top(SynkBadge(text: 'x', variant: variant)),
                brightness: brightness,
              ),
            );
            final actual = colorsOf(tester);
            final flattened = Color.alphaBlend(actual.bg, page);
            expect(
              contrast(actual.fg, flattened),
              greaterThanOrEqualTo(4.5),
              reason: '$variant $brightness',
            );
          }
        }
      },
    );

    testWidgets('normal badges are 26dp tall pills, small ones 20dp', (
      tester,
    ) async {
      await tester.pumpWidget(synkApp(_top(const SynkBadge(text: 'Partner'))));
      expect(tester.getSize(find.byType(SynkBadge)).height, 26);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(SynkBadge),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;
      expect(decoration.shape, isA<StadiumBorder>());

      await tester.pumpWidget(
        synkApp(_top(const SynkBadge(text: 'Partner', small: true))),
      );
      expect(tester.getSize(find.byType(SynkBadge)).height, 20);
    });

    testWidgets('small renders upper-case text but reads as written', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(_top(const SynkBadge(text: 'Owner', small: true))),
      );
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('Owner'), findsNothing);
      expect(
        tester.getSemantics(find.text('OWNER')),
        isSemantics(label: 'Owner'),
      );
      final style = tester.widget<Text>(find.text('OWNER')).style!;
      expect(style.fontSize, 10);
      handle.dispose();

      await tester.pumpWidget(synkApp(_top(const SynkBadge(text: 'Owner'))));
      expect(find.text('Owner'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Owner')).style!.fontSize, 12);
    });

    testWidgets('outline draws a border, filled variants do not', (
      tester,
    ) async {
      ShapeBorder shape() =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byType(SynkBadge),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as ShapeDecoration)
              .shape;
      await tester.pumpWidget(
        synkApp(
          _top(const SynkBadge(text: 'x', variant: SynkBadgeVariant.outline)),
        ),
      );
      expect((shape() as StadiumBorder).side.color, SynkColors.light.border);
      await tester.pumpWidget(synkApp(_top(const SynkBadge(text: 'x'))));
      expect((shape() as StadiumBorder).side, BorderSide.none);
    });

    testWidgets('leading widget sits before the text', (tester) async {
      await tester.pumpWidget(
        synkApp(
          _top(
            const SynkBadge(
              text: 'Partner',
              leading: SynkIcon(SynkIcons.heart, size: 12),
            ),
          ),
        ),
      );
      expect(
        tester.getCenter(find.byType(SynkIcon)).dx,
        lessThan(tester.getCenter(find.text('Partner')).dx),
      );
      expect(tester.getSize(find.byType(SynkBadge)).height, 26);
    });

    testWidgets(
      'long text is clipped to the available width without overflow',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            _top(
              const SizedBox(
                width: 70,
                child: Row(
                  children: [
                    Flexible(
                      child: SynkBadge(text: 'A very long badge label indeed'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(SynkBadge)).width,
          lessThanOrEqualTo(70),
        );
      },
    );

    testWidgets('survives text scale 1.3 without growing out of its pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(_top(const SynkBadge(text: 'Owner')), textScale: 1.3),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SynkBadge)).height, 26);
      await tester.pumpWidget(
        synkApp(
          _top(const SynkBadge(text: 'Owner', small: true)),
          textScale: 1.3,
        ),
      );
      expect(tester.getSize(find.byType(SynkBadge)).height, 20);
    });

    testWidgets('golden: every variant, normal and small, with leading', (
      tester,
    ) async {
      await expectStateSheetGolden(
        tester,
        'surfaces_badges',
        [
          for (final variant in SynkBadgeVariant.values)
            GoldenCell(
              variant.name,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  SynkBadge(text: _badgeText(variant), variant: variant),
                  SynkBadge(
                    text: _badgeText(variant),
                    variant: variant,
                    small: true,
                  ),
                ],
              ),
            ),
          const GoldenCell(
            'leading',
            SynkBadge(
              text: 'Partner',
              leading: SynkIcon(
                SynkIcons.heart,
                size: 12,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
        size: const Size(420, 285),
        cellWidth: 88,
      );
    });

    testWidgets('golden: badges at text scale 1.3', (tester) async {
      await expectStateSheetGolden(
        tester,
        'surfaces_badges_scale13',
        [
          for (final variant in [
            SynkBadgeVariant.primary,
            SynkBadgeVariant.ink,
            SynkBadgeVariant.success,
            SynkBadgeVariant.amber,
          ])
            GoldenCell(
              variant.name,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  SynkBadge(text: _badgeText(variant), variant: variant),
                  SynkBadge(
                    text: _badgeText(variant),
                    variant: variant,
                    small: true,
                  ),
                ],
              ),
            ),
        ],
        size: const Size(420, 290),
        cellWidth: 92,
        textScale: 1.3,
      );
    });
  });

  group('SynkSeparator', () {
    testWidgets('horizontal is exactly one physical pixel at any density', (
      tester,
    ) async {
      for (final ratio in [1.0, 2.0, 3.0, 2.75]) {
        tester.view.physicalSize = Size(420 * ratio, 800 * ratio);
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(synkApp(_top(const SynkSeparator())));
        final size = tester.getSize(find.byType(SynkSeparator));
        expect(size.height * ratio, closeTo(1, 1e-9), reason: 'dpr $ratio');
        expect(size.width, 420, reason: 'fills the width');
      }
    });

    testWidgets('paints in the border colour', (tester) async {
      await tester.pumpWidget(synkApp(_top(const SynkSeparator())));
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(SynkSeparator),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        SynkColors.light.border,
      );
      await tester.pumpWidget(
        synkApp(_top(const SynkSeparator()), brightness: Brightness.dark),
      );
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(SynkSeparator),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        SynkColors.dark.border,
      );
    });

    testWidgets(
      'vertical is one pixel wide, at least 12dp tall, and stretches',
      (tester) async {
        tester.view.physicalSize = const Size(840, 1600);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          synkApp(
            _top(
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [SynkSeparator(axis: Axis.vertical)],
              ),
            ),
          ),
        );
        final loose = tester.getSize(find.byType(SynkSeparator));
        expect(loose.width, 0.5);
        expect(loose.height, greaterThanOrEqualTo(12));

        await tester.pumpWidget(
          synkApp(
            _top(
              const SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [SynkSeparator(axis: Axis.vertical)],
                ),
              ),
            ),
          ),
        );
        expect(tester.getSize(find.byType(SynkSeparator)).height, 48);
      },
    );

    testWidgets('is hidden from accessibility', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          _top(
            const Column(
              children: [SynkText('above'), SynkSeparator(), SynkText('below')],
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(SynkSeparator),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('SectionLabel', () {
    testWidgets('upper-cases, mutes and uses the section-label style', (
      tester,
    ) async {
      await tester.pumpWidget(synkApp(_top(const SectionLabel('Your groups'))));
      expect(find.text('YOUR GROUPS'), findsOneWidget);
      final text = tester.widget<Text>(find.text('YOUR GROUPS'));
      expect(text.style!.fontSize, 12);
      expect(text.style!.fontWeight, FontWeight.w600);
      expect(text.style!.letterSpacing, 1.0);
      expect(text.style!.color, SynkColors.light.mutedForeground);
      expect(text.maxLines, 1);
    });

    testWidgets('small uses the compact style', (tester) async {
      await tester.pumpWidget(
        synkApp(_top(const SectionLabel('Invitations', small: true))),
      );
      final text = tester.widget<Text>(find.text('INVITATIONS'));
      expect(text.style!.fontSize, 11);
      expect(text.style!.fontWeight, FontWeight.w700);
      expect(text.style!.letterSpacing, 0.6);
    });

    testWidgets('is a heading that reads as written', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(synkApp(_top(const SectionLabel('Your groups'))));
      expect(
        tester.getSemantics(find.byType(SectionLabel)),
        isSemantics(isHeader: true, label: 'Your groups'),
      );
      handle.dispose();
    });

    testWidgets('golden: separators and section labels', (tester) async {
      await expectStateSheetGolden(
        tester,
        'surfaces_separators_labels',
        [
          const GoldenCell('SectionLabel', SectionLabel('Your groups')),
          const GoldenCell(
            'SectionLabel small',
            SectionLabel('Invitations for you', small: true),
          ),
          const GoldenCell(
            'SynkSeparator horizontal',
            Column(
              children: [
                SynkText('above'),
                SizedBox(height: 8),
                SynkSeparator(),
                SizedBox(height: 8),
                SynkText('below'),
              ],
            ),
          ),
          const GoldenCell(
            'SynkSeparator vertical',
            SizedBox(
              height: 28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  SynkText('One'),
                  SynkSeparator(axis: Axis.vertical),
                  SynkText('Two'),
                  SynkSeparator(axis: Axis.vertical),
                  SynkText('Three'),
                ],
              ),
            ),
          ),
        ],
        size: const Size(420, 300),
        cellWidth: 388,
      );
    });
  });
}

String _badgeText(SynkBadgeVariant variant) => switch (variant) {
  SynkBadgeVariant.ink => '72% Used',
  SynkBadgeVariant.success => 'Active',
  SynkBadgeVariant.amber => 'Expiring',
  SynkBadgeVariant.destructive => 'Failed',
  _ => variant.name[0].toUpperCase() + variant.name.substring(1),
};
