import 'package:date_js/app/providers/onboarding_providers.dart';
import 'package:date_js/app/providers/session_providers.dart';
import 'package:date_js/design_system/design_system.dart';
import 'package:date_js/domain/models/gender.dart';
import 'package:date_js/shared/widgets/verified_badge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

SessionState get _onboarding =>
    const SessionState(stage: AuthStage.onboarding, phone: '+919876543210');

void main() {
  testWidgets('the age gate blocks anyone under 18', (tester) async {
    usePhone(tester);
    final now = DateTime.now();
    await tester.pumpWidget(
      testApp(
        session: _onboarding,
        draft: OnboardingDraft(
          name: 'Kid',
          birthday: DateTime(now.year - 16, now.month, now.day),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('You must be 18 or older to use date-js.'),
      findsOneWidget,
    );
    final cta = tester.widget<SynkButton>(
      find.widgetWithText(SynkButton, 'Continue'),
    );
    expect(cta.onPressed, isNull);
  });

  testWidgets('walks all seven steps and lands on Discover', (tester) async {
    usePhone(tester);
    final now = DateTime.now();
    await tester.pumpWidget(
      testApp(
        session: _onboarding,
        draft: OnboardingDraft(
          name: 'Sam',
          birthday: DateTime(now.year - 28, now.month, now.day),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tapCta(String label) async {
      final finder = find.widgetWithText(SynkButton, label);
      expect(
        tester.widget<SynkButton>(finder).onPressed,
        isNotNull,
        reason: label,
      );
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    // 1. name + birthday are prefilled by the seeded draft
    expect(find.text('Let\'s start with you'), findsOneWidget);
    await tapCta('Continue');

    // 2. gender: Continue stays disabled until both choices are made
    expect(find.text('About you'), findsOneWidget);
    expect(
      tester
          .widget<SynkButton>(find.widgetWithText(SynkButton, 'Continue'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Man').first);
    await tester.pump();
    await tester.tap(find.widgetWithText(SynkChip, 'Woman'));
    await tester.pumpAndSettle();
    await tapCta('Continue');

    // 3. photos: need two
    expect(find.text('Add your photos'), findsOneWidget);
    expect(
      tester
          .widget<SynkButton>(find.widgetWithText(SynkButton, 'Continue'))
          .onPressed,
      isNull,
    );
    for (var i = 0; i < 2; i++) {
      await tester.tap(
        find.bySemanticsLabel('Add photo').first,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      if (find.text('Take a photo').evaluate().isEmpty) {
        await tester.tap(find.byTooltip('Add photo').first);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();
    }
    expect(find.text('2 of 6 added'), findsOneWidget);
    await tapCta('Continue');

    // 4. about: three interests
    expect(find.text('What are you into?'), findsOneWidget);
    for (final i in ['Coffee', 'Hiking', 'Books']) {
      await tester.tap(find.widgetWithText(SynkChip, i));
      await tester.pump();
    }
    expect(find.text('3/6'), findsOneWidget);
    await tapCta('Continue');

    // 5. location through the permission sheet
    expect(find.text('Where are you?'), findsOneWidget);
    expect(
      tester
          .widget<SynkButton>(find.widgetWithText(SynkButton, 'Continue'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow while using the app'));
    await tester.pumpAndSettle();
    await tapCta('Continue');

    // 6. verification can be skipped
    expect(find.text('Get verified'), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    // 7. done
    expect(find.text('You\'re all set, Sam!'), findsOneWidget);
    await tester.tap(find.widgetWithText(SynkButton, 'Start discovering'));
    await tester.pumpAndSettle();

    expect(find.text('date-js'), findsWidgets, reason: 'Discover header');
    expect(find.text('Discover'), findsOneWidget, reason: 'nav bar');
  });

  testWidgets('verification plays the scan and marks the profile verified', (
    tester,
  ) async {
    usePhone(tester);
    final now = DateTime.now();
    await tester.pumpWidget(
      testApp(
        session: _onboarding,
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
    // Jump forward through the filled steps.
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.widgetWithText(SynkButton, 'Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Get verified'), findsOneWidget);
    await tester.tap(find.text('Start verification'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('Skip for now'),
      findsNothing,
      reason: 'hidden while scanning',
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SynkButton, 'Continue'), findsOneWidget);
    await tester.tap(find.widgetWithText(SynkButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(
      find.byType(VerifiedBadge),
      findsOneWidget,
      reason: 'recap shows the tick',
    );
    expect(find.text('You\'re all set, Sam!'), findsOneWidget);
  });
}
