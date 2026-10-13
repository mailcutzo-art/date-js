import 'package:date_js/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  testWidgets('splash hands over to the welcome screen', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Meet someone worth meeting.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Dating that starts with a real hello.'), findsOneWidget);
  });

  testWidgets('phone number then wrong and right code reaches the setup', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with phone'));
    await tester.pumpAndSettle();
    expect(find.text('What\'s your number?'), findsOneWidget);

    SynkButton sendButton() =>
        tester.widget<SynkButton>(find.widgetWithText(SynkButton, 'Send code'));
    expect(sendButton().onPressed, isNull, reason: 'empty number');
    await tester.enterText(find.byType(TextField), '98765');
    await tester.pump();
    expect(sendButton().onPressed, isNull, reason: 'too short');
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    expect(sendButton().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(SynkButton, 'Send code'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the code'), findsOneWidget);
    expect(
      find.text('We sent a 6-digit code to +919876543210.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '111111');
    await tester.pumpAndSettle();
    expect(find.text('That code is not right. Try again.'), findsOneWidget);
    expect(find.text('Enter the code'), findsOneWidget, reason: 'still on OTP');

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('Let\'s start with you'), findsOneWidget);
  });

  testWidgets('Continue with Google skips straight to the setup', (
    tester,
  ) async {
    usePhone(tester);
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Let\'s start with you'), findsOneWidget);
  });

  testWidgets('resend appears after the countdown', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(testApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with phone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.widgetWithText(SynkButton, 'Send code'));
    await tester.pumpAndSettle();
    expect(find.text('Resend code in 30s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Resend code'), findsOneWidget);
  });
}
