import 'package:date_js/data/mock/mock_profiles.dart';
import 'package:date_js/domain/models/profile.dart';
import 'package:date_js/domain/models/swipe.dart';
import 'package:date_js/shared/widgets/swipe_deck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synk_test_harness.dart';

void main() {
  late List<(Profile, SwipeAction)> swiped;
  late SwipeDeckController controller;

  Future<void> pumpDeck(WidgetTester tester) async {
    useGoldenViewport(tester);
    swiped = [];
    controller = SwipeDeckController();
    await tester.pumpWidget(
      synkApp(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SwipeDeck(
            controller: controller,
            profiles: kDemoProfiles.take(4).toList(),
            onSwiped: (p, a) => swiped.add((p, a)),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the top profile with its name and age', (tester) async {
    await pumpDeck(tester);
    expect(find.text('Aria, 27'), findsOneWidget);
  });

  testWidgets('dragging right past the threshold likes', (tester) async {
    await pumpDeck(tester);
    await tester.drag(find.text('Aria, 27'), const Offset(260, 10));
    await tester.pumpAndSettle();
    expect(swiped, hasLength(1));
    expect(swiped.single.$1.id, 'p1');
    expect(swiped.single.$2, SwipeAction.like);
  });

  testWidgets('dragging left past the threshold passes', (tester) async {
    await pumpDeck(tester);
    await tester.drag(find.text('Aria, 27'), const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(swiped.single.$2, SwipeAction.pass);
  });

  testWidgets('dragging up past the threshold super-likes', (tester) async {
    await pumpDeck(tester);
    await tester.drag(find.text('Aria, 27'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(swiped.single.$2, SwipeAction.superLike);
  });

  testWidgets('a short drag springs back and swipes nothing', (tester) async {
    await pumpDeck(tester);
    final before = tester.getTopLeft(find.text('Aria, 27'));
    await tester.drag(find.text('Aria, 27'), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(swiped, isEmpty);
    expect(
      (tester.getTopLeft(find.text('Aria, 27')) - before).distance,
      lessThan(0.5),
    );
  });

  testWidgets('a fast fling commits even over a short distance', (
    tester,
  ) async {
    await pumpDeck(tester);
    await tester.fling(find.text('Aria, 27'), const Offset(80, 0), 1500);
    await tester.pumpAndSettle();
    expect(swiped.single.$2, SwipeAction.like);
  });

  testWidgets('the stamp fades in while dragging', (tester) async {
    await pumpDeck(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Aria, 27')),
    );
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    expect(find.text('LIKE'), findsOneWidget);
    expect(find.text('NOPE'), findsNothing);
    await gesture.moveBy(const Offset(-240, 0));
    await tester.pump();
    expect(find.text('NOPE'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the controller drives the deck programmatically', (
    tester,
  ) async {
    await pumpDeck(tester);
    controller.swipe(SwipeAction.pass);
    await tester.pumpAndSettle();
    expect(swiped.single.$2, SwipeAction.pass);
  });

  testWidgets('tapping the right side of the card shows the next photo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDeck(tester);
    // Aria has three photos: the progress bars exist.
    expect(find.bySemanticsLabel(RegExp('Photo 1 of 3')), findsOneWidget);
    await tester.tapAt(
      tester.getCenter(find.byType(SwipeDeck)) + const Offset(100, 0),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Photo 2 of 3')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('exposes like / pass / super like as accessibility actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDeck(tester);
    final node = tester.getSemantics(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.customSemanticsActions?.length ?? 0) == 3,
      ),
    );
    expect(node.getSemanticsData().customSemanticsActionIds, hasLength(3));
    handle.dispose();
  });
}
