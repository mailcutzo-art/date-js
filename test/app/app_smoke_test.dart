import 'package:date_js/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots to the home screen and shows a toast', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DateJsApp()));
    await tester.pumpAndSettle();

    expect(find.text('date-js'), findsOneWidget);

    await tester.tap(find.text('Say hello'));
    await tester.pump();
    expect(find.text('Hello from date-js'), findsOneWidget);

    // Let the toast dismiss itself so no timer outlives the test.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
