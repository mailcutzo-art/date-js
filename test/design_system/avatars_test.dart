import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/avatar_stack.dart';
import 'package:date_js/design_system/components/bauhaus_avatar.dart';
import 'package:date_js/design_system/components/synk_avatar.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_palette.dart';

import '../support/synk_test_harness.dart';

void main() {
  group('avatarInitial', () {
    test('uses the first ASCII letter or digit, upper-cased', () {
      expect(avatarInitial('ada'), 'A');
      expect(avatarInitial('  bob  '), 'B');
      expect(avatarInitial('42 apples'), '4');
      expect(avatarInitial('7 Eleven'), '7');
    });

    test('skips leading non-ASCII characters to find an ASCII letter', () {
      expect(avatarInitial('\u{1F600} Bob'), 'B');
      expect(avatarInitial('éclair'), 'C');
      expect(avatarInitial('-_-x'), 'X');
    });

    test('falls back to the first character when there is no ASCII letter', () {
      expect(avatarInitial('-_-'), '-');
      expect(avatarInitial('李雷'), '李');
      // A whole emoji (surrogate pair, skin tone modifier) stays intact.
      expect(avatarInitial('\u{1F600}'), '\u{1F600}');
      expect(avatarInitial('\u{1F44D}\u{1F3FD} nice'), 'N');
      expect(avatarInitial('\u{1F44D}\u{1F3FD}'), '\u{1F44D}\u{1F3FD}');
    });

    test('is "?" for blank names', () {
      expect(avatarInitial(''), '?');
      expect(avatarInitial('   \n'), '?');
    });
  });

  group('InitialsAvatar', () {
    testWidgets('uses muted background and foreground text by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(const Center(child: InitialsAvatar(name: 'ada', size: 40))),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(InitialsAvatar),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).color, SynkColors.light.muted);
      expect(
        (box.decoration as BoxDecoration).shape,
        BoxShape.circle,
        reason: 'avatars are circles',
      );
      final text = tester.widget<Text>(find.text('A'));
      expect(text.style!.color, SynkColors.light.foreground);
      expect(tester.getSize(find.byType(InitialsAvatar)), const Size(40, 40));
    });

    testWidgets('a dark custom fallback colour gets light text', (
      tester,
    ) async {
      const colour = Color(0xFF8E44AD);
      await tester.pumpWidget(
        synkApp(
          const Center(
            child: InitialsAvatar(name: 'zed', fallbackColor: colour),
          ),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(InitialsAvatar),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).color, colour);
      expect(
        tester.widget<Text>(find.text('Z')).style!.color,
        kInitialsOnColor,
      );
      expect(kInitialsOnColor, const Color(0xF2FAFAFA));
    });

    testWidgets(
      'a bright custom fallback colour gets dark text (white is 2:1 on green)',
      (tester) async {
        for (final colour in const [
          Color(0xFF2ECC71),
          Color(0xFFE67E22),
          Color(0xFF3498DB),
        ]) {
          await tester.pumpWidget(
            synkApp(
              Center(
                child: InitialsAvatar(name: 'zed', fallbackColor: colour),
              ),
            ),
          );
          expect(
            tester.widget<Text>(find.text('Z')).style!.color,
            kInitialsOnLightColor,
            reason: '$colour',
          );
        }
      },
    );

    testWidgets('a fallback equal to muted keeps the foreground text', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          Center(
            child: InitialsAvatar(
              name: 'zed',
              fallbackColor: SynkColors.dark.muted,
            ),
          ),
          brightness: Brightness.dark,
        ),
      );
      expect(
        tester.widget<Text>(find.text('Z')).style!.color,
        SynkColors.dark.foreground,
      );
    });

    testWidgets('font size is size / 2, normal weight and ignores text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          const Center(child: InitialsAvatar(name: 'ada', size: 56)),
          textScale: 2,
        ),
      );
      final text = tester.widget<Text>(find.text('A'));
      expect(text.style!.fontSize, 28);
      expect(text.style!.fontWeight, FontWeight.w400);
      final paragraph = tester.renderObject<RenderParagraph>(find.text('A'));
      expect(paragraph.textScaler, TextScaler.noScaling);
      expect(tester.getSize(find.byType(InitialsAvatar)), const Size(56, 56));
    });

    testWidgets('exposes the name to accessibility, not the bare initial', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(const Center(child: InitialsAvatar(name: 'Ada Lovelace'))),
      );
      expect(find.bySemanticsLabel('Ada Lovelace'), findsOneWidget);
      expect(find.bySemanticsLabel('A'), findsNothing);
      handle.dispose();
    });
  });

  group('SynkAvatar', () {
    testWidgets('blank or missing url shows initials', (tester) async {
      for (final url in <String?>[null, '', '   ']) {
        await tester.pumpWidget(
          synkApp(
            Center(
              child: SynkAvatar(name: 'Bea', imageUrl: url),
            ),
          ),
        );
        expect(find.byType(InitialsAvatar), findsOneWidget, reason: '"$url"');
        expect(find.byType(Image), findsNothing);
        expect(find.byType(CachedNetworkImage), findsNothing);
      }
    });

    testWidgets('a loaded photo replaces the initials', (tester) async {
      final image = await _makeImage(tester);
      await tester.pumpWidget(
        synkApp(
          Center(
            child: SynkAvatar(
              name: 'Bea',
              size: 48,
              imageProvider: _UiImageProvider(image),
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('B'), findsNothing);
      expect(tester.getSize(find.byType(SynkAvatar)), const Size(48, 48));
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets(
      'a failing photo falls back to initials in the fallback colour',
      (tester) async {
        const colour = Color(0xFF8E44AD);
        await tester.pumpWidget(
          synkApp(
            const Center(
              child: SynkAvatar(
                name: 'Bea',
                fallbackColor: colour,
                imageProvider: _FailingImageProvider(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.text('B'), findsOneWidget);
        final boxes = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((b) => (b.decoration as BoxDecoration).color);
        expect(boxes, contains(colour));
      },
    );

    testWidgets('uses the network image with the given headers', (
      tester,
    ) async {
      const headers = {'Referer': 'https://synkly.app'};
      await tester.pumpWidget(
        synkApp(
          const Center(
            child: SynkAvatar(
              name: 'Bea',
              imageUrl: ' https://cdn.example.com/a.png ',
              httpHeaders: headers,
            ),
          ),
        ),
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://cdn.example.com/a.png');
      expect(image.httpHeaders, headers);
      expect(image.fadeInDuration, Duration.zero, reason: 'reduced motion');
      // The plugin-less test environment cannot load it; drain the expected failure.
      await tester.pump();
      tester.takeException();
    });

    testWidgets('labels the avatar with the name or a custom label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final image = await _makeImage(tester);
      await tester.pumpWidget(
        synkApp(
          Column(
            children: [
              SynkAvatar(name: 'Bea', imageProvider: _UiImageProvider(image)),
              SynkAvatar(
                name: 'Cy',
                semanticLabel: 'Profile photo',
                imageProvider: _UiImageProvider(image),
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Bea'), findsOneWidget);
      expect(find.bySemanticsLabel('Profile photo'), findsOneWidget);
      handle.dispose();
    });
  });

  group('BauhausAvatar.compute', () {
    test('"A" (sum 65) matches the algorithm worked by hand', () {
      // sum = 65. idx0: color 65%5=0; range 23: 65%23=19, digit(65,1)=6 even -> -19,
      // digit(65,2)=0 even -> -19; rot 65. isSquare: digit(65,2)=0 -> true.
      // idx1: color 1; 130%22=20, digit(130,1)=3 odd -> 20, digit(130,2)=1 odd -> 20; rot 130.
      // idx2: color 2; 195%21=6, digit(195,1)=9 odd, digit(195,2)=1 odd; rot 195.
      // idx3: color 3; 260%20=0 -> 0; rot 260.
      final shapes = BauhausAvatar.compute('A', 5);
      expect(shapes, hasLength(4));
      expect(shapes.map((s) => s.colorIndex), [0, 1, 2, 3]);
      expect(shapes.map((s) => s.translateX), [-19, 20, 6, 0]);
      expect(shapes.map((s) => s.translateY), [-19, 20, 6, 0]);
      expect(shapes.map((s) => s.rotation), [65, 130, 195, 260]);
      expect(shapes.every((s) => s.isSquare), isTrue);
    });

    test('"Synkly" (sum 650) matches the algorithm worked by hand', () {
      // S83 y121 n110 k107 l108 y121 = 650. digit(650,2)=6 even -> square.
      // idx0: color 650%5=0; 650%23=6, digit(650,1)=5 odd -> 6; digit(650,2)=6 even -> -6; rot 290.
      // idx1: color 1; 1300%22=2, digit(1300,1)=0 even -> -2; digit(1300,2)=3 odd -> 2; rot 220.
      // idx2: color 2; 1950%21=18, digit 5 odd -> 18; digit 9 odd -> 18; rot 150.
      // idx3: color 3; 2600%20=0; rot 80.
      final shapes = BauhausAvatar.compute('Synkly', 5);
      expect(shapes.map((s) => s.colorIndex), [0, 1, 2, 3]);
      expect(shapes.map((s) => s.translateX), [6, -2, 18, 0]);
      expect(shapes.map((s) => s.translateY), [-6, 2, 18, 0]);
      expect(shapes.map((s) => s.rotation), [290, 220, 150, 80]);
      expect(shapes.every((s) => s.isSquare), isTrue);
    });

    test('a name whose hundreds digit is odd draws the thin bar', () {
      // "d" = 100: digit(100,2) = 1 -> odd -> not a square.
      final shapes = BauhausAvatar.compute('d', 5);
      expect(shapes.every((s) => !s.isSquare), isTrue);
      // color (100+idx)%5, translate: 100%23=8, digit(100,1)=0 even -> -8; digit(100,2)=1 odd -> 8.
      expect(shapes.first.colorIndex, 0);
      expect(shapes.first.translateX, -8);
      expect(shapes.first.translateY, 8);
      expect(shapes.first.rotation, 100);
    });

    test('the empty name is the all-zero case', () {
      final shapes = BauhausAvatar.compute('', 5);
      expect(shapes.map((s) => s.colorIndex), [0, 1, 2, 3]);
      expect(
        shapes.every((s) => s.translateX == 0 && s.translateY == 0),
        isTrue,
      );
      expect(shapes.every((s) => s.rotation == 0), isTrue);
      expect(shapes.every((s) => s.isSquare), isTrue);
    });

    test(
      'sums the first UTF-16 unit of every code point, like JS Array.from',
      () {
        // U+1F600 is the pair D83D DE00 -> only 0xD83D (55357) counts: sum = 97 + 55357.
        final shapes = BauhausAvatar.compute('a\u{1F600}', 5);
        // 55454 % 5 = 4 -> colours 4, 0, 1, 2. (Counting both units would give 112286 % 5 = 1.)
        expect(shapes.map((s) => s.colorIndex), [4, 0, 1, 2]);
      },
    );

    test('the palette size drives the colour index modulo', () {
      expect(BauhausAvatar.compute('A', 3).map((s) => s.colorIndex), [
        2,
        0,
        1,
        2,
      ]);
      expect(BauhausAvatar.compute('A', 1).map((s) => s.colorIndex), [
        0,
        0,
        0,
        0,
      ]);
      expect(() => BauhausAvatar.compute('A', 0), throwsArgumentError);
    });

    test('is deterministic and name-sensitive', () {
      expect(
        BauhausAvatar.compute('Movie night', 5),
        BauhausAvatar.compute('Movie night', 5),
      );
      expect(
        BauhausAvatar.compute('Movie night', 5),
        isNot(BauhausAvatar.compute('Movie nights', 5)),
      );
    });

    test('translations stay inside the per-layer range', () {
      for (final name in ['Synkly', 'Family', 'x' * 120, '李雷', 'Zed']) {
        final shapes = BauhausAvatar.compute(name, 5);
        for (var idx = 0; idx < 4; idx++) {
          final range = 23 - idx;
          expect(shapes[idx].translateX.abs(), lessThan(range), reason: name);
          expect(shapes[idx].translateY.abs(), lessThan(range), reason: name);
          expect(shapes[idx].rotation, inInclusiveRange(0, 359));
        }
      }
    });
  });

  group('BauhausAvatar widget', () {
    testWidgets(
      'paints the circle and line layers where the algorithm puts them',
      (tester) async {
        // "A": circle (colour 2) centred at (40-19+..): translate (6, 6)? No: idx2 translate is
        // (6, 6), so the circle centre is (46, 46). Layer 3 (line, colour 3) has translate (0, 0)
        // and rotation 260 about (40, 40), so it passes through the centre pixel.
        useGoldenViewport(tester, size: const Size(200, 200));
        final key = GlobalKey();
        await tester.pumpWidget(
          synkApp(
            Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: key,
                child: const BauhausAvatar(name: 'A', size: 80),
              ),
            ),
          ),
        );
        final pixels = await _readPixels(tester, key, const [
          Offset(46, 46), // circle centre
          Offset(40, 40), // on the line
          Offset(0, 0), // clipped corner
          Offset(79, 0), // clipped corner
        ]);
        const p = SynkPalette.groupAvatarPalette;
        expect(pixels[0], _rgba(p[2]));
        expect(pixels[1], _rgba(p[3]));
        expect(pixels[2][3], 0, reason: 'the circle clip leaves corners empty');
        expect(pixels[3][3], 0);
      },
    );

    testWidgets('scales with size and is decorative by default', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(
          const Column(
            children: [
              BauhausAvatar(name: 'Synkly', size: 24),
              BauhausAvatar(
                name: 'Synkly',
                size: 72,
                semanticLabel: 'Synkly group',
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Synkly group'), findsOneWidget);
      final sizes = tester
          .widgetList<BauhausAvatar>(find.byType(BauhausAvatar))
          .map((a) => tester.getSize(find.byWidget(a)).width);
      expect(sizes, [24, 72]);
      handle.dispose();
    });

    test('painter repaints only when the shapes or colours change', () {
      final a = BauhausPainter(
        shapes: BauhausAvatar.compute('A', 5),
        colors: SynkPalette.groupAvatarPalette,
      );
      final same = BauhausPainter(
        shapes: BauhausAvatar.compute('A', 5),
        colors: SynkPalette.groupAvatarPalette,
      );
      final other = BauhausPainter(
        shapes: BauhausAvatar.compute('B', 5),
        colors: SynkPalette.groupAvatarPalette,
      );
      expect(a.shouldRepaint(same), isFalse);
      expect(a.shouldRepaint(other), isTrue);
      expect(
        a.shouldRepaint(
          BauhausPainter(
            shapes: a.shapes,
            colors: const [Colors.red, Colors.green, Colors.blue],
          ),
        ),
        isTrue,
      );
    });
  });

  group('AvatarStack', () {
    const people = [
      AvatarStackItem(name: 'Ada'),
      AvatarStackItem(name: 'Bo'),
      AvatarStackItem(name: 'Cy'),
      AvatarStackItem(name: 'Di'),
      AvatarStackItem(name: 'Ed'),
    ];

    testWidgets('shows maxVisible faces and a +N chip for the rest', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(const Center(child: AvatarStack(items: people))),
      );
      expect(find.byType(SynkAvatar), findsNWidgets(3));
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('D'), findsNothing);
    });

    testWidgets('no chip when everything fits', (tester) async {
      await tester.pumpWidget(
        synkApp(Center(child: AvatarStack(items: people.take(3).toList()))),
      );
      expect(find.byType(SynkAvatar), findsNWidgets(3));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('a single item and the maxVisible override', (tester) async {
      await tester.pumpWidget(
        synkApp(Center(child: AvatarStack(items: [people.first]))),
      );
      expect(find.byType(SynkAvatar), findsOneWidget);
      expect(tester.getSize(find.byType(AvatarStack)), const Size(24, 24));

      await tester.pumpWidget(
        synkApp(const Center(child: AvatarStack(items: people, maxVisible: 4))),
      );
      expect(find.byType(SynkAvatar), findsNWidgets(4));
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('circles overlap by the configured amount', (tester) async {
      await tester.pumpWidget(
        synkApp(
          Center(
            child: AvatarStack(
              items: people.take(3).toList(),
              size: 24,
              overlap: 8,
            ),
          ),
        ),
      );
      // Step 16: 2 steps + one full circle.
      expect(
        tester.getSize(find.byType(AvatarStack)),
        const Size(16 * 2 + 24, 24),
      );
      final positions = tester
          .widgetList<Positioned>(
            find.descendant(
              of: find.byType(AvatarStack),
              matching: find.byType(Positioned),
            ),
          )
          .map((p) => p.left)
          .toList();
      // Painted back to front, so the first item (left 0) is on top.
      expect(positions, [32, 16, 0]);
    });

    testWidgets(
      'chip width grows with the digits and the chip sits after the faces',
      (tester) async {
        final many = [
          for (var i = 0; i < 13; i++) AvatarStackItem(name: 'P$i'),
        ];
        const stack = AvatarStack(items: <AvatarStackItem>[]);
        expect(stack.totalWidth, 0);
        final wide = AvatarStack(items: many);
        expect(wide.overflowCount, 10);
        expect(wide.chipWidth, greaterThan(24));
        expect(wide.totalWidth, 3 * 16 + wide.chipWidth);
        const narrow = AvatarStack(items: people);
        expect(narrow.chipWidth, greaterThanOrEqualTo(24));
        expect(narrow.chipWidth, lessThan(wide.chipWidth));
        await tester.pumpWidget(synkApp(Center(child: wide)));
        expect(tester.getSize(find.byType(AvatarStack)).width, wide.totalWidth);
        expect(find.text('+10'), findsOneWidget);
      },
    );

    testWidgets(
      'placeholders draw three muted circles at 35% when nobody is there',
      (tester) async {
        await tester.pumpWidget(
          synkApp(
            const Center(child: AvatarStack(items: [], showPlaceholders: true)),
          ),
        );
        // One 35 % layer holding three circles (so overlaps do not darken).
        final faded = tester
            .widgetList<Opacity>(find.byType(Opacity))
            .where((o) => o.opacity == 0.35);
        expect(faded, hasLength(1));
        expect(
          find.descendant(
            of: find.byType(Opacity),
            matching: find.byType(Positioned),
          ),
          findsNWidgets(3),
        );
        expect(find.byType(SynkAvatar), findsNothing);
        expect(
          tester.getSize(find.byType(AvatarStack)),
          const Size(16 * 2 + 24, 24),
        );

        await tester.pumpWidget(
          synkApp(const Center(child: AvatarStack(items: []))),
        );
        expect(find.byType(Opacity), findsNothing);
        expect(tester.getSize(find.byType(AvatarStack)).width, 0);
      },
    );

    testWidgets('placeholders are ignored once there are faces', (
      tester,
    ) async {
      await tester.pumpWidget(
        synkApp(
          Center(
            child: AvatarStack(
              items: people.take(2).toList(),
              showPlaceholders: true,
            ),
          ),
        ),
      );
      expect(find.byType(SynkAvatar), findsNWidgets(2));
      expect(
        tester
            .widgetList<Opacity>(find.byType(Opacity))
            .where((o) => o.opacity == 0.35),
        isEmpty,
      );
    });

    testWidgets(
      'ringed items get a primary ring, others the separator colour',
      (tester) async {
        const ringColor = Color(0xFF10B981);
        await tester.pumpWidget(
          synkApp(
            const Center(
              child: AvatarStack(
                items: [
                  AvatarStackItem(name: 'Ada', ringed: true),
                  AvatarStackItem(name: 'Bo'),
                  AvatarStackItem(
                    name: 'Cy',
                    ringed: true,
                    ringColor: ringColor,
                  ),
                ],
              ),
            ),
          ),
        );
        final borders = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(AvatarStack),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((b) => b.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.border != null)
            .map((d) => (d.border! as Border).top.color)
            .toList();
        expect(borders, contains(SynkColors.light.primary));
        expect(borders, contains(ringColor));
        expect(borders, contains(SynkColors.light.card));
        expect(
          borders.where((c) => c == SynkColors.light.primary),
          hasLength(1),
        );
      },
    );

    testWidgets('the separator colour is configurable', (tester) async {
      const custom = Color(0xFF123456);
      await tester.pumpWidget(
        synkApp(
          Center(
            child: AvatarStack(
              items: people.take(2).toList(),
              borderColor: custom,
            ),
          ),
        ),
      );
      final colours = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(AvatarStack),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((b) => b.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border != null)
          .map((d) => (d.border! as Border).top.color);
      expect(colours, contains(custom));
    });

    testWidgets('announces the people as one node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        synkApp(Center(child: AvatarStack(items: people.take(3).toList()))),
      );
      expect(find.bySemanticsLabel('3 people: Ada, Bo, Cy'), findsOneWidget);
      await tester.pumpWidget(
        synkApp(
          const Center(child: AvatarStack(items: [], showPlaceholders: true)),
        ),
      );
      expect(find.bySemanticsLabel('Nobody here'), findsOneWidget);
      handle.dispose();
    });
  });

  group('golden sheets', () {
    testWidgets(
      'avatars: initials, long names, emoji, colours, sizes, image paths',
      (tester) async {
        final image = await _makeImage(tester);
        final cells = <GoldenCell>[
          for (final size in [20.0, 28.0, 40.0, 56.0, 72.0])
            GoldenCell(
              'initials ${size.toInt()}',
              InitialsAvatar(name: 'Ada Lovelace', size: size),
            ),
          const GoldenCell(
            'long name',
            SynkAvatar(name: 'Bartholomew Montgomery III', size: 48),
          ),
          const GoldenCell(
            'emoji',
            SynkAvatar(name: '\u{1F600} Smile', size: 48),
          ),
          const GoldenCell('digit', SynkAvatar(name: '7 Eleven', size: 48)),
          const GoldenCell('blank', SynkAvatar(name: '', size: 48)),
          for (final (i, colour) in SynkPalette.chatAvatarColors.indexed)
            GoldenCell(
              'chat colour $i',
              SynkAvatar(name: 'User $i', size: 40, fallbackColor: colour),
            ),
          const GoldenCell(
            'url blank',
            SynkAvatar(
              name: 'Nora',
              imageUrl: '',
              size: 48,
              fallbackColor: Color(0xFFE67E22),
            ),
          ),
          GoldenCell(
            'photo',
            SynkAvatar(
              name: 'Pia',
              size: 48,
              imageProvider: _UiImageProvider(image),
            ),
          ),
          GoldenCell(
            'photo 28',
            SynkAvatar(
              name: 'Pia',
              size: 28,
              imageProvider: _UiImageProvider(image),
            ),
          ),
          const GoldenCell(
            'load error',
            SynkAvatar(
              name: 'Err',
              size: 48,
              fallbackColor: Color(0xFF2ECC71),
              imageProvider: _FailingImageProvider(),
            ),
          ),
        ];
        await expectStateSheetGolden(
          tester,
          'avatars',
          cells,
          size: const Size(420, 520),
          cellWidth: 84,
        );
      },
    );

    testWidgets('bauhaus: twelve names and several sizes', (tester) async {
      // (label, name): the labels stay ASCII because the test fonts have no emoji/CJK glyphs.
      const names = <(String, String)>[
        ('Synkly', 'Synkly'),
        ('Movie Night', 'Movie Night'),
        ('Family', 'Family'),
        ('Us', 'Us'),
        ('Weekend Crew', 'Weekend Crew'),
        ('Ada', 'Ada'),
        ('Anime Club', 'Anime Club'),
        ('emoji name', 'Date night \u{1F37F}'),
        ('Cyrillic', 'Горячий'),
        ('CJK', '李雷'),
        ('d (thin bar)', 'd'),
        ('(empty)', ''),
      ];
      final cells = <GoldenCell>[
        for (final (label, name) in names)
          GoldenCell(label, BauhausAvatar(name: name, size: 64)),
        for (final size in [20.0, 32.0, 50.0, 80.0, 112.0])
          GoldenCell(
            'Synkly ${size.toInt()}',
            BauhausAvatar(name: 'Synkly', size: size),
          ),
      ];
      await expectStateSheetGolden(
        tester,
        'bauhaus_avatars',
        cells,
        size: const Size(420, 700),
        cellWidth: 112,
      );
    });

    testWidgets('avatar stack: counts, placeholders, ringed, sizes', (
      tester,
    ) async {
      final image = await _makeImage(tester);
      AvatarStackItem item(
        String name, {
        Color? color,
        bool ringed = false,
        bool photo = false,
      }) => AvatarStackItem(
        name: name,
        color: color,
        ringed: ringed,
        imageProvider: photo ? _UiImageProvider(image) : null,
      );
      final cells = <GoldenCell>[
        GoldenCell(
          '1 item',
          AvatarStack(
            items: [item('Ada', color: SynkPalette.chatAvatarColors[0])],
          ),
        ),
        GoldenCell(
          '3 items',
          AvatarStack(
            items: [
              item('Ada', color: SynkPalette.chatAvatarColors[0]),
              item('Bo', color: SynkPalette.chatAvatarColors[2]),
              item('Cy', photo: true),
            ],
          ),
        ),
        GoldenCell(
          '5 items (+2)',
          AvatarStack(
            items: [
              for (final (i, n) in ['Ada', 'Bo', 'Cy', 'Di', 'Ed'].indexed)
                item(n, color: SynkPalette.chatAvatarColors[i]),
            ],
          ),
        ),
        GoldenCell(
          '15 items (+12)',
          AvatarStack(
            items: [
              for (var i = 0; i < 15; i++)
                item('P$i', color: SynkPalette.chatAvatarColors[i % 7]),
            ],
          ),
        ),
        const GoldenCell(
          'nobody online',
          AvatarStack(items: [], showPlaceholders: true),
        ),
        GoldenCell(
          'ringed (speaking)',
          AvatarStack(
            items: [
              item('Ada', color: SynkPalette.chatAvatarColors[0], ringed: true),
              item('Bo', color: SynkPalette.chatAvatarColors[2]),
              item('Cy', color: SynkPalette.chatAvatarColors[3]),
            ],
          ),
        ),
        GoldenCell(
          'size 40 overlap 12',
          AvatarStack(
            size: 40,
            overlap: 12,
            maxVisible: 4,
            items: [
              for (final (i, n) in [
                'Ada',
                'Bo',
                'Cy',
                'Di',
                'Ed',
                'Flo',
              ].indexed)
                item(n, color: SynkPalette.chatAvatarColors[i], photo: i == 1),
            ],
          ),
        ),
        GoldenCell(
          'tinted border',
          AvatarStack(
            size: 32,
            borderColor: const Color(0xFFF2F5FF),
            items: [
              item('Ada', color: SynkPalette.chatAvatarColors[1]),
              item('Bo', color: SynkPalette.chatAvatarColors[4]),
              item('Cy', color: SynkPalette.chatAvatarColors[5]),
              item('Di', color: SynkPalette.chatAvatarColors[6]),
            ],
          ),
        ),
      ];
      await expectStateSheetGolden(
        tester,
        'avatar_stack',
        cells,
        size: const Size(420, 360),
        cellWidth: 150,
      );
    });
  });
}

/// A synchronously available photo made of paint (no codec, no network).
class _UiImageProvider extends ImageProvider<_UiImageProvider> {
  const _UiImageProvider(this.image);

  final ui.Image image;

  @override
  Future<_UiImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_UiImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _UiImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
  );

  @override
  bool operator ==(Object other) =>
      other is _UiImageProvider && identical(other.image, image);

  @override
  int get hashCode => identityHashCode(image);
}

/// Always fails to load.
class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  const _FailingImageProvider();

  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FailingImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(StateError('image failed to load')),
  );

  @override
  bool operator ==(Object other) => other is _FailingImageProvider;

  @override
  int get hashCode => 0;
}

Future<ui.Image> _makeImage(WidgetTester tester) async {
  final image = await tester.runAsync(() async {
    const side = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas
      ..drawRect(
        const Rect.fromLTWH(0, 0, side, side),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            const Offset(side, side),
            const [Color(0xFF6366F1), Color(0xFFF60669)],
          ),
      )
      ..drawCircle(
        const Offset(side * 0.5, side * 0.4),
        side * 0.18,
        Paint()..color = const Color(0xCCFFFFFF),
      )
      ..drawOval(
        Rect.fromCenter(
          center: const Offset(side * 0.5, side * 0.98),
          width: side * 0.8,
          height: side * 0.55,
        ),
        Paint()..color = const Color(0xCCFFFFFF),
      );
    return recorder.endRecording().toImage(64, 64);
  });
  return image!;
}

List<int> _rgba(Color c) => [
  (c.r * 255).round(),
  (c.g * 255).round(),
  (c.b * 255).round(),
  (c.a * 255).round(),
];

/// Reads RGBA pixels at logical [points] of the repaint boundary with [key] (pixel ratio 1).
Future<List<List<int>>> _readPixels(
  WidgetTester tester,
  GlobalKey key,
  List<Offset> points,
) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final data = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData();
    final width = image.width;
    image.dispose();
    return (bytes!, width);
  });
  final ByteData bytes = data!.$1;
  final width = data.$2;
  return [
    for (final p in points)
      [
        for (var channel = 0; channel < 4; channel++)
          bytes.getUint8((p.dy.toInt() * width + p.dx.toInt()) * 4 + channel),
      ],
  ];
}
