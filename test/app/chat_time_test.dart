import 'package:date_js/core/utils/chat_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 14, 15, 30);

  test('under a minute is "Now"', () {
    expect(
      formatChatTime(now.subtract(const Duration(seconds: 20)), now),
      'Now',
    );
  });

  test('same day shows the clock time', () {
    expect(formatChatTime(DateTime(2026, 10, 14, 9, 5), now), '9:05 AM');
    expect(formatChatTime(DateTime(2026, 10, 14, 0, 10), now), '12:10 AM');
    expect(formatChatTime(DateTime(2026, 10, 14, 13, 0), now), '1:00 PM');
  });

  test('yesterday, weekday within a week, then a date', () {
    expect(formatChatTime(DateTime(2026, 10, 13, 22), now), 'Yesterday');
    expect(formatChatTime(DateTime(2026, 10, 11, 8), now), 'Sun');
    expect(formatChatTime(DateTime(2026, 9, 2, 8), now), '2 Sep');
  });
}
