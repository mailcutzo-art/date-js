import '../models/preferences.dart';
import '../models/profile.dart';
import '../models/swipe.dart';

abstract interface class DiscoveryRepository {
  /// People matching [prefs], best first.
  Future<List<Profile>> fetchDeck(Preferences prefs);

  /// People who already liked the user (a premium feature to see).
  Future<List<Profile>> fetchLikesYou();

  Future<SwipeOutcome> swipe(
    Profile profile,
    SwipeAction action, {
    required bool premium,
  });
}
