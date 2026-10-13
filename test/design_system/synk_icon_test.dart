import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/icons/google_glyph.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';

import '../support/synk_test_harness.dart';

void main() {
  group('SynkIcons', () {
    test(
      'every glyph parses into a non-empty path inside the 24x24 viewport',
      () {
        for (final icon in SynkIcons.values) {
          expect(icon.glyph.parts, isNotEmpty, reason: icon.name);
          for (final part in icon.glyph.parts) {
            final bounds = part.path.getBounds();
            // Lines (e.g. the dot of the info icon) have a zero-size axis but still draw.
            expect(
              bounds.width + bounds.height,
              greaterThan(0),
              reason: '${icon.name} part is empty',
            );
            expect(bounds.left, greaterThanOrEqualTo(-0.5), reason: icon.name);
            expect(bounds.top, greaterThanOrEqualTo(-0.5), reason: icon.name);
            expect(bounds.right, lessThanOrEqualTo(24.5), reason: icon.name);
            expect(bounds.bottom, lessThanOrEqualTo(24.5), reason: icon.name);
          }
        }
      },
    );

    test('mirrors the Android semantic icon set', () {
      expect(SynkIcons.values.length, 96);
      expect(
        SynkIcons.values.map((e) => e.name),
        containsAll(<String>[
          'home',
          'close',
          'back',
          'users',
          'crown',
          'heart',
          'spark',
          'lock',
          'tvPlay',
          'cake',
          'calendarAdd',
          'hardDrive',
          'micOff',
          'fullscreenExit',
          'discover',
          'chats',
          'cards',
          'gem',
        ]),
      );
    });

    test('glyphs keep the cap/join of the source (butt/miter parts exist)', () {
      final caps = {
        for (final icon in SynkIcons.values)
          for (final part in icon.glyph.parts) part.cap,
      };
      expect(caps, containsAll(<StrokeCap>[StrokeCap.round, StrokeCap.butt]));
    });

    testWidgets('golden sheet: sizes, tints and the Google glyph', (
      tester,
    ) async {
      await expectStateSheetGolden(
        tester,
        'synk_icons',
        [
          for (final icon in [
            SynkIcons.home,
            SynkIcons.users,
            SynkIcons.heart,
            SynkIcons.crown,
            SynkIcons.tvPlay,
            SynkIcons.calendarAdd,
            SynkIcons.cake,
            SynkIcons.hardDrive,
            SynkIcons.mic,
            SynkIcons.fullscreen,
            SynkIcons.settings,
            SynkIcons.trash,
            SynkIcons.discover,
            SynkIcons.chats,
            SynkIcons.cards,
            SynkIcons.gem,
          ])
            GoldenCell(icon.name, SynkIcon(icon, size: 28)),
          const GoldenCell('size 12', SynkIcon(SynkIcons.heart, size: 12)),
          const GoldenCell('size 18', SynkIcon(SynkIcons.heart, size: 18)),
          const GoldenCell('size 28', SynkIcon(SynkIcons.heart, size: 28)),
          const GoldenCell(
            'primary tint',
            SynkIcon(SynkIcons.spark, size: 28, color: Color(0xFFC6005C)),
          ),
          const GoldenCell('google', GoogleGlyph(size: 28)),
        ],
        size: const Size(420, 300),
        cellWidth: 56,
      );
    });
  });
}
