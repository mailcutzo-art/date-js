import 'package:date_js/data/mock/mock_profiles.dart';
import 'package:date_js/domain/models/message.dart';
import 'package:date_js/shared/widgets/interest_chips.dart';
import 'package:date_js/shared/widgets/main_nav_bar.dart';
import 'package:date_js/shared/widgets/match_overlay.dart';
import 'package:date_js/shared/widgets/message_bubble.dart';
import 'package:date_js/shared/widgets/otp_field.dart';
import 'package:date_js/shared/widgets/photos_grid.dart';
import 'package:date_js/shared/widgets/step_progress_header.dart';
import 'package:date_js/shared/widgets/typing_indicator.dart';
import 'package:date_js/shared/widgets/verified_badge.dart';
import 'package:date_js/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/synk_test_harness.dart';

void main() {
  group('OtpField', () {
    testWidgets('fills the boxes and completes at six digits', (tester) async {
      useGoldenViewport(tester);
      String? done;
      await tester.pumpWidget(
        synkApp(
          Padding(
            padding: const EdgeInsets.all(24),
            child: OtpField(onCompleted: (c) => done = c),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();
      expect(done, isNull);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      expect(done, '123456');
    });

    testWidgets('ignores anything that is not a digit', (tester) async {
      useGoldenViewport(tester);
      await tester.pumpWidget(
        synkApp(
          Padding(
            padding: const EdgeInsets.all(24),
            child: OtpField(onCompleted: (_) {}),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'ab12');
      await tester.pump();
      expect(find.text('a'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('MessageBubble', () {
    final at = DateTime(2026, 10, 14, 9, 41);

    testWidgets('text bubble shows the text and the time', (tester) async {
      useGoldenViewport(tester);
      await tester.pumpWidget(
        synkApp(
          MessageBubble(
            showTime: true,
            message: Message(
              id: '1',
              fromMe: false,
              kind: MessageKind.text,
              text: 'Hello there',
              sentAt: at,
            ),
          ),
        ),
      );
      expect(find.text('Hello there'), findsOneWidget);
      expect(find.text('9:41 AM'), findsOneWidget);
    });

    testWidgets(
      'your messages show a delivery tick that turns blue when read',
      (tester) async {
        useGoldenViewport(tester);
        for (final status in MessageStatus.values) {
          await tester.pumpWidget(
            synkApp(
              MessageBubble(
                message: Message(
                  id: '1',
                  fromMe: true,
                  kind: MessageKind.text,
                  text: 'Hi',
                  sentAt: at,
                  status: status,
                ),
              ),
            ),
          );
          expect(find.byType(SynkIcon), findsOneWidget, reason: '$status');
        }
      },
    );

    testWidgets('voice note toggles between play and pause', (tester) async {
      useGoldenViewport(tester);
      await tester.pumpWidget(
        synkApp(
          MessageBubble(
            message: Message(
              id: 'v',
              fromMe: false,
              kind: MessageKind.voice,
              voiceSeconds: 12,
              sentAt: at,
            ),
          ),
        ),
      );
      expect(find.text('0:12'), findsOneWidget);
      await tester.tap(find.byType(SynkPressable));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byType(SynkPressable));
      await tester.pump();
    });

    testWidgets('image bubble renders generated artwork', (tester) async {
      useGoldenViewport(tester);
      await tester.pumpWidget(
        synkApp(
          MessageBubble(
            message: Message(
              id: 'i',
              fromMe: true,
              kind: MessageKind.image,
              imageSeed: 5,
              sentAt: at,
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  testWidgets('TypingIndicator animates three dots', (tester) async {
    useGoldenViewport(tester);
    await tester.pumpWidget(synkApp(const TypingIndicator()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TypingIndicator), findsOneWidget);
  });

  testWidgets('MainNavBar reports taps and shows the unread badge', (
    tester,
  ) async {
    useGoldenViewport(tester);
    var tapped = -1;
    await tester.pumpWidget(
      synkApp(
        Align(
          alignment: Alignment.bottomCenter,
          child: MainNavBar(
            currentIndex: 0,
            onTap: (i) => tapped = i,
            items: const [
              NavItem(icon: SynkIcons.flame, label: 'Discover'),
              NavItem(icon: SynkIcons.heart, label: 'Matches'),
              NavItem(icon: SynkIcons.chat, label: 'Chats', badge: 3),
            ],
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Chats'));
    expect(tapped, 2);
  });

  testWidgets('PhotosGrid marks the main photo and reports add / remove', (
    tester,
  ) async {
    useGoldenViewport(tester);
    var added = 0;
    int? removed;
    await tester.pumpWidget(
      synkApp(
        Padding(
          padding: const EdgeInsets.all(16),
          child: PhotosGrid(
            seeds: const [1, 2],
            onAdd: () => added++,
            onRemove: (i) => removed = i,
          ),
        ),
      ),
    );
    expect(find.text('MAIN'), findsOneWidget);
    final handle = tester.ensureSemantics();
    await tester.tap(find.bySemanticsLabel('Add photo').first);
    expect(added, 1);
    await tester.tap(find.bySemanticsLabel('Remove photo').last);
    expect(removed, 1);
    handle.dispose();
  });

  testWidgets(
    'InterestChips toggles when selectable and is read-only otherwise',
    (tester) async {
      useGoldenViewport(tester);
      String? toggled;
      await tester.pumpWidget(
        synkApp(
          InterestChips(
            interests: const ['Coffee', 'Hiking'],
            selected: const {'Coffee'},
            onToggle: (i) => toggled = i,
          ),
        ),
      );
      await tester.tap(find.text('Hiking'));
      expect(toggled, 'Hiking');

      toggled = null;
      await tester.pumpWidget(
        synkApp(const InterestChips(interests: ['Coffee', 'Hiking'])),
      );
      await tester.tap(find.text('Hiking'));
      expect(toggled, isNull);
    },
  );

  testWidgets('StepProgressHeader hides back on the first step', (
    tester,
  ) async {
    useGoldenViewport(tester);
    await tester.pumpWidget(
      synkApp(const StepProgressHeader(step: 0, total: 7)),
    );
    expect(find.byType(CircleIconButton), findsNothing);
    var back = 0;
    await tester.pumpWidget(
      synkApp(StepProgressHeader(step: 2, total: 7, onBack: () => back++)),
    );
    await tester.tap(find.byType(CircleIconButton));
    expect(back, 1);
  });

  testWidgets('VerifiedBadge is announced to screen readers', (tester) async {
    useGoldenViewport(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(synkApp(const VerifiedBadge()));
    expect(find.bySemanticsLabel('Verified profile'), findsOneWidget);
    handle.dispose();
  });

  group('MatchOverlay', () {
    Future<MatchChoice?> open(WidgetTester tester, String tap) async {
      useGoldenViewport(tester);
      MatchChoice? result;
      await tester.pumpWidget(
        synkApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result = await showMatchOverlay(
                context,
                me: kDemoProfiles[1],
                other: kDemoProfiles[0],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.text('It\'s a match!'), findsOneWidget);
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('Send a message resolves to message', (tester) async {
      expect(await open(tester, 'Send a message'), MatchChoice.message);
    });

    testWidgets('Keep swiping resolves to keepSwiping', (tester) async {
      expect(await open(tester, 'Keep swiping'), MatchChoice.keepSwiping);
    });
  });
}
