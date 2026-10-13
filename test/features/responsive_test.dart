import 'package:date_js/app/providers/onboarding_providers.dart';
import 'package:date_js/app/providers/session_providers.dart';
import 'package:date_js/design_system/design_system.dart';
import 'package:date_js/domain/models/gender.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

/// Every main screen on a very small phone, a normal phone and a tablet, at normal and large
/// text: a RenderFlex overflow or any other build error fails the test.
void main() {
  const sizes = <String, Size>{
    'small phone 320x568': Size(320, 568),
    'phone 360x740': Size(360, 740),
    'large phone 412x915': Size(412, 915),
    'tablet 800x1280': Size(800, 1280),
  };

  for (final entry in sizes.entries) {
    for (final scale in const [1.0, 1.4]) {
      testWidgets('${entry.key} at text ${scale}x: tabs and detail screens', (
        tester,
      ) async {
        usePhone(tester, size: entry.value);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(testApp(session: signedIn()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'discover');

        Future<void> tab(String label) async {
          await tester.tap(find.byKey(ValueKey('nav-$label')));
          await tester.pumpAndSettle();
        }

        await tab('Matches');
        expect(tester.takeException(), isNull, reason: 'matches');
        await tester.tap(find.textContaining('Likes you'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'likes you');

        await tab('Chats');
        expect(tester.takeException(), isNull, reason: 'chats');
        await tester.tap(find.text('Tara'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'chat');
        await tester.tap(find.bySemanticsLabel('Back').first);
        await tester.pumpAndSettle();

        await tab('Profile');
        expect(tester.takeException(), isNull, reason: 'me');
        await tester.ensureVisible(find.text('Go Premium'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Go Premium'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'premium');
        await tester.tap(find.bySemanticsLabel('Close').first);
        await tester.pumpAndSettle();

        for (final label in [
          'Edit profile',
          'Privacy and safety',
          'Settings',
        ]) {
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
          await tester.tap(find.bySemanticsLabel('Back').first);
          await tester.pumpAndSettle();
        }

        await tab('Discover');
        await tester.tap(find.bySemanticsLabel('View Aria\'s profile'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'profile detail');

        handle.dispose();
      });

      testWidgets('${entry.key} at text ${scale}x: sign-in and setup', (
        tester,
      ) async {
        usePhone(tester, size: entry.value);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(testApp());
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'welcome');
        await tester.tap(find.text('Continue with phone'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'sign in');
        await tester.enterText(find.byType(TextField), '9876543210');
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'sign in, keyboard-like input',
        );
        await tester.tap(find.widgetWithText(SynkButton, 'Send code'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'otp');
      });

      testWidgets('${entry.key} at text ${scale}x: setup steps', (
        tester,
      ) async {
        usePhone(tester, size: entry.value);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        // A draft that lets every step through.
        final now = DateTime.now();
        await tester.pumpWidget(
          testApp(
            session: const SessionState(stage: AuthStage.onboarding),
            draft: OnboardingDraft(
              name: 'Sam',
              birthday: DateTime(now.year - 28, now.month, now.day),
              gender: Gender.man,
              interestedIn: {Gender.woman},
              photoSeeds: [1, 2],
              interests: {'Coffee', 'Hiking', 'Books'},
              city: 'Bengaluru',
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var step = 0; step < 5; step++) {
          expect(tester.takeException(), isNull, reason: 'setup step $step');
          await tester.tap(find.widgetWithText(SynkButton, 'Continue'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull, reason: 'verification step');
        await tester.tap(find.text('Skip for now'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'setup done');
      });
    }
  }
}
