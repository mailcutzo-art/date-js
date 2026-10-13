import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_profiles.dart';
import '../../domain/models/profile.dart';
import 'session_providers.dart';

/// Finds a profile by id: the signed-in user, then the demo directory. A real build replaces
/// the directory lookup with a repository call.
final profileByIdProvider = Provider.family<Profile?, String>((ref, id) {
  final me = ref.watch(sessionProvider).me;
  if (me != null && me.id == id) return me;
  for (final p in kDemoProfiles) {
    if (p.id == id) return p;
  }
  return null;
});
