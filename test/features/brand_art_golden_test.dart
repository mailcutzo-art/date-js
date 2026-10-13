import 'package:date_js/design_system/design_system.dart';
import 'package:date_js/features/auth/welcome_slides.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// All five welcome poster slides side by side, at a phone-sized frame each.
void main() {
  testWidgets('welcome poster slides', (tester) async {
    tester.view.physicalSize = const Size(5 * 300, 600) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SynkThemeData.light,
        home: RepaintBoundary(
          key: const ValueKey('slides'),
          child: Material(
            child: Row(
              children: [
                for (var i = 0; i < WelcomeSlide.count; i++)
                  SizedBox(
                    width: 300,
                    height: 600,
                    child: WelcomeSlide(index: i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('slides')),
      matchesGoldenFile('goldens/welcome_slides.png'),
    );
  });
}
