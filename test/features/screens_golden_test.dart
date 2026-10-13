import 'package:date_js/app/providers/onboarding_providers.dart';
import 'package:date_js/app/providers/session_providers.dart';
import 'package:date_js/design_system/design_system.dart';
import 'package:date_js/domain/models/gender.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

/// Screenshots of the real screens, light and dark, at 420x900. They are the visual regression
/// net for the UI: review a diff, then refresh with `flutter test --update-goldens`.
void main() {
  Future<void> shoot(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required Future<void> Function() setUp,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await setUp();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/${name}_${brightness.name}.png'),
    );
  }

  for (final brightness in Brightness.values) {
    group(brightness.name, () {
      testWidgets('welcome', (tester) async {
        usePhone(tester);
        await shoot(
          tester,
          'welcome',
          brightness: brightness,
          setUp: () async {
            await tester.pumpWidget(testApp());
            await tester.pump(const Duration(seconds: 2));
            await tester.pumpAndSettle();
          },
        );
      });

      testWidgets('sign in', (tester) async {
        usePhone(tester);
        await shoot(
          tester,
          'sign_in',
          brightness: brightness,
          setUp: () async {
            await tester.pumpWidget(testApp());
            await tester.pump(const Duration(seconds: 2));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Continue with phone'));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField), '9876543210');
            await tester.pumpAndSettle();
          },
        );
      });

      testWidgets('setup: about you', (tester) async {
        usePhone(tester);
        await shoot(
          tester,
          'setup_gender',
          brightness: brightness,
          setUp: () async {
            final now = DateTime.now();
            await tester.pumpWidget(
              testApp(
                session: const SessionState(stage: AuthStage.onboarding),
                draft: OnboardingDraft(
                  name: 'Sam',
                  birthday: DateTime(now.year - 28, now.month, now.day),
                  gender: Gender.man,
                  interestedIn: {Gender.woman},
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.widgetWithText(SynkButton, 'Continue'));
            await tester.pumpAndSettle();
          },
        );
      });

      testWidgets('discover', (tester) async {
        usePhone(tester);
        await shoot(
          tester,
          'discover',
          brightness: brightness,
          setUp: () async {
            await tester.pumpWidget(testApp(session: signedIn()));
            await tester.pumpAndSettle();
          },
        );
      });

      testWidgets('profile detail', (tester) async {
        usePhone(tester);
        final handle = tester.ensureSemantics();
        await shoot(
          tester,
          'profile_detail',
          brightness: brightness,
          setUp: () async {
            await tester.pumpWidget(testApp(session: signedIn()));
            await tester.pumpAndSettle();
            await tester.tap(find.bySemanticsLabel('View Aria\'s profile'));
            await tester.pumpAndSettle();
          },
        );
        handle.dispose();
      });

      testWidgets('matches', (tester) async {
        usePhone(tester);
        await shoot(
          tester,
          'matches',
          brightness: brightness,
          setUp: () async {
            await tester.pumpWidget(testApp(session: signedIn()));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('nav-Matches')));
            await tester.pumpAndSettle();
          },
        );
      });

      testWidgets('chats', (tester) async {
        usePhone(tester);
        await shoot(
          tester,
          'chats',
          brightness: brightness,
          setUp: () async {
            await tester.pumpWidget(testApp(session: signedIn()));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('nav-Chats')));
            await tester.pumpAndSettle();
          },
        );
      });

      testWidgets('chat', (tester) async {
        usePhone(tester);
        await shoot(
          tester,
          'chat',
          brightness: brightness,
          setUp: () async {
            await tester.pumpWidget(testApp(session: signedIn()));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('nav-Chats')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Tara'));
            await tester.pumpAndSettle();
          },
        );
      });

      testWidgets('my profile', (tester) async {
        usePhone(tester);
        await shoot(
          tester,
          'me',
          brightness: brightness,
          setUp: () async {
            await tester.pumpWidget(testApp(session: signedIn()));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('nav-Profile')));
            await tester.pumpAndSettle();
          },
        );
      });

      testWidgets('premium', (tester) async {
        usePhone(tester);
        await shoot(
          tester,
          'premium',
          brightness: brightness,
          setUp: () async {
            await tester.pumpWidget(testApp(session: signedIn()));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('nav-Profile')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Go Premium'));
            await tester.pumpAndSettle();
          },
        );
      });
    });
  }
}
