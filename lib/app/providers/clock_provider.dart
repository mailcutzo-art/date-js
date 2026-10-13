import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's notion of "now". Tests override it so timestamps (and screenshots) are stable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
