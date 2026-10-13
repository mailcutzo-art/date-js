import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Buttons are one family (`SynkButton`, `SynkIconButton`, `CircleIconButton`): every text button
/// is a full pill and every icon button a circle. Stock Material buttons bring their own corner
/// radius and would make neighbouring buttons look unrelated, so they stay out of `lib/`.
void main() {
  test('lib/ never uses stock Material buttons', () {
    final stock = RegExp(
      r'\b(ElevatedButton|FilledButton|OutlinedButton|TextButton|FloatingActionButton)\b|(?<![A-Za-z])IconButton\(',
    );
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (stock.hasMatch(line)) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'use SynkButton / SynkIconButton');
  });
}
