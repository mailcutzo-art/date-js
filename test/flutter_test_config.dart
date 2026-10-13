import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts so text renders identically in widget and golden tests
/// (flutter_test otherwise substitutes the blocky "Ahem" font for custom families).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Manrope');
  for (final weight in const [
    '300Light',
    '400Regular',
    '500Medium',
    '600SemiBold',
    '700Bold',
    '800ExtraBold',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/manrope/Manrope_$weight.ttf'));
  }
  await loader.load();
  await (FontLoader('PermanentMarker')..addFont(
        rootBundle.load(
          'assets/fonts/permanent_marker/PermanentMarker-Regular.ttf',
        ),
      ))
      .load();
  await (FontLoader('YoungSerif')..addFont(
        rootBundle.load('assets/fonts/young_serif/YoungSerif-Regular.ttf'),
      ))
      .load();
  await testMain();
}
