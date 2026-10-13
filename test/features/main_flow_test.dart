import 'package:date_js/app/providers/chat_providers.dart';
import 'package:date_js/app/providers/session_providers.dart';
import 'package:date_js/design_system/design_system.dart';
import 'package:date_js/shared/widgets/main_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

Future<ProviderContainer> pumpSignedIn(
  WidgetTester tester, {
  bool premium = false,
}) async {
  usePhone(tester);
  await tester.pumpWidget(testApp(session: signedIn(premium: premium)));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MainNavBar)));
}

Future<void> tapLabel(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(label).first);
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey('nav-$label')));
  await tester.pumpAndSettle();
}

void main() {
  group('Discover', () {
    testWidgets('shows the first profile and advances on Pass', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      expect(find.text('Aria, 27'), findsOneWidget);
      await tapLabel(tester, 'Pass');
      expect(find.text('Rohan, 29'), findsOneWidget);
      expect(find.text('Aria, 27'), findsNothing);
      handle.dispose();
    });

    testWidgets('liking someone who likes you shows the match overlay', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final container = await pumpSignedIn(tester);
      await tapLabel(tester, 'Like'); // Aria likes the demo user
      expect(find.text('It\'s a match!'), findsOneWidget);
      expect(find.text('You and Aria like each other.'), findsOneWidget);
      expect(
        container.read(conversationsProvider).items.map((c) => c.id),
        contains('c-p1'),
      );

      await tester.tap(find.text('Keep swiping'));
      await tester.pumpAndSettle();
      expect(find.text('It\'s a match!'), findsNothing);
      expect(find.text('Rohan, 29'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a match can jump straight into the chat', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await tapLabel(tester, 'Like');
      await tester.tap(find.text('Send a message'));
      await tester.pumpAndSettle();
      expect(find.text('You matched with Aria'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('liking someone who has not liked you back does not match', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await tapLabel(tester, 'Pass'); // Aria
      await tapLabel(tester, 'Like'); // Rohan: likesYou false
      expect(find.text('It\'s a match!'), findsNothing);
      expect(find.text('Meera, 25'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the info button opens the full profile and back returns', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await tapLabel(tester, 'View Aria\'s profile');
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.textContaining('Sunday market regular'), findsOneWidget);
      expect(find.text('Hiking'), findsOneWidget);
      await tapLabel(tester, 'Back');
      expect(find.text('Aria, 27'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a free account gets one Super Like, then the Premium prompt', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await tapLabel(tester, 'Super like'); // Aria: matches, overlay
      await tester.tap(find.text('Keep swiping'));
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Super like'); // Rohan: limit reached
      expect(find.text('Out of Super Likes'), findsOneWidget);
      expect(find.text('Rohan, 29'), findsOneWidget, reason: 'card put back');
      handle.dispose();
    });

    testWidgets('filters narrow the deck', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await tapLabel(tester, 'Filters');
      // Show only men.
      await tester.tap(find.widgetWithText(SynkChip, 'Woman'));
      await tester.pump();
      await tester.tap(find.widgetWithText(SynkChip, 'Non-binary'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Rohan, 29'), findsOneWidget);
      expect(find.text('Aria, 27'), findsNothing);
      handle.dispose();
    });

    testWidgets('verified-only is a Premium filter', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await tapLabel(tester, 'Filters');
      await tester.tap(find.bySemanticsLabel('Verified profiles only').last);
      await tester.pumpAndSettle();
      expect(find.text('Verified-only is a Premium filter'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an empty deck offers to adjust the filters', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      for (var i = 0; i < 10; i++) {
        if (find.text('You\'ve seen everyone nearby').evaluate().isNotEmpty) {
          break;
        }
        await tapLabel(tester, 'Pass');
      }
      expect(find.text('You\'ve seen everyone nearby'), findsOneWidget);
      expect(find.text('Adjust filters'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Chats', () {
    testWidgets('lists conversations with unread badges and opens one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await openTab(tester, 'Chats');
      expect(find.text('Tara'), findsOneWidget);
      expect(find.text('Vikram'), findsOneWidget);
      expect(find.text('Bring snacks.'), findsOneWidget);
      expect(find.text('You: Ha! Okay, Friday it is.'), findsOneWidget);

      await tester.tap(find.text('Tara'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nandi Hills at sunrise. You should come next time.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('opening a chat clears its unread count', (tester) async {
      final container = await pumpSignedIn(tester);
      expect(container.read(conversationsProvider).unread, 2);
      await openTab(tester, 'Chats');
      await tester.tap(find.text('Tara'));
      await tester.pumpAndSettle();
      expect(container.read(conversationsProvider).unread, 0);
    });

    testWidgets('sending a message shows it and the reply arrives', (
      tester,
    ) async {
      final container = await pumpSignedIn(tester);
      await openTab(tester, 'Chats');
      await tester.tap(find.text('Tara'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Saturday works for me');
      await tester.pump();
      await tester.tap(
        find.bySemanticsLabel('Send').first,
        warnIfMissed: false,
      );
      // Fallback when semantics are off: the send button is the last CircleIconButton.
      if (find.text('Saturday works for me').evaluate().isEmpty) {
        await tester.tap(find.byType(CircleIconButton).last);
      }
      await tester.pumpAndSettle();
      expect(find.text('Saturday works for me'), findsOneWidget);
      final tara = container.read(conversationProvider('c-p11'))!;
      expect(tara.messages.last.fromMe, isFalse, reason: 'a reply followed');
      expect(tara.unread, 0, reason: 'chat is open');
    });

    testWidgets('blocking removes the conversation', (tester) async {
      final handle = tester.ensureSemantics();
      final container = await pumpSignedIn(tester);
      await openTab(tester, 'Chats');
      await tester.tap(find.text('Vikram'));
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Chat options');
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block').last);
      await tester.pumpAndSettle();
      expect(container.read(conversationProvider('c-p12')), isNull);
      expect(find.text('Vikram'), findsNothing);
      handle.dispose();
    });

    testWidgets('reporting asks for a reason and confirms', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await openTab(tester, 'Chats');
      await tester.tap(find.text('Vikram'));
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Chat options');
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(find.text('Report Vikram'), findsOneWidget);
      await tester.tap(find.text('Scam or asking for money'));
      await tester.pumpAndSettle();
      expect(find.text('Report sent'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      handle.dispose();
    });
  });

  group('Premium', () {
    testWidgets('Likes you is locked until Premium is unlocked', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final container = await pumpSignedIn(tester);
      await openTab(tester, 'Matches');
      await tester.tap(find.textContaining('Likes you'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Locked profile, Premium'), findsWidgets);
      expect(find.text('Aria, 27'), findsNothing);

      await tester.tap(
        find.text('3 people like you. Unlock them with Premium.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Go Premium'), findsWidgets);
      await tester.tap(find.text('Continue with 3 months'));
      await tester.pumpAndSettle();
      expect(find.text('Billing is not connected'), findsOneWidget);
      await tester.tap(find.text('Unlock for demo'));
      await tester.pumpAndSettle();
      expect(container.read(sessionProvider).premium, isTrue);

      expect(find.text('Aria, 27'), findsOneWidget, reason: 'now visible');
      await tester.pump(const Duration(seconds: 4));
      handle.dispose();
    });
  });

  group('Profile tab', () {
    testWidgets('edit profile saves only after a change', (tester) async {
      final handle = tester.ensureSemantics();
      final container = await pumpSignedIn(tester);
      await openTab(tester, 'Profile');
      await tester.tap(find.text('Edit profile').last);
      await tester.pumpAndSettle();

      SynkButton save() =>
          tester.widget<SynkButton>(find.widgetWithText(SynkButton, 'Save'));
      expect(save().onPressed, isNull);
      await tester.enterText(
        find.widgetWithText(TextField, 'Test bio'),
        'New bio',
      );
      await tester.pump();
      expect(save().onPressed, isNotNull);
      await tester.tap(find.widgetWithText(SynkButton, 'Save'));
      await tester.pumpAndSettle();
      expect(container.read(sessionProvider).me!.bio, 'New bio');
      await tester.pump(const Duration(seconds: 4));
      handle.dispose();
    });

    testWidgets('signing out returns to the welcome screen', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await openTab(tester, 'Profile');
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Dating that starts with a real hello.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('privacy toggles flip and Incognito needs Premium', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSignedIn(tester);
      await openTab(tester, 'Profile');
      await tester.tap(find.text('Privacy and safety').last);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Show my distance'));
      await tester.pumpAndSettle();
      expect(find.text('WHAT OTHERS SEE'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Incognito mode'));
      await tester.pumpAndSettle();
      expect(find.text('Browse privately'), findsOneWidget);
      handle.dispose();
    });
  });
}
