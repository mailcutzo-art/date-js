import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/profile.dart';
import '../../domain/models/swipe.dart';
import 'chat_providers.dart';
import 'repository_providers.dart';
import 'session_providers.dart';

enum DiscoverNotice { none, superLikeLimit }

class DiscoverState {
  const DiscoverState({
    this.deck = const [],
    this.loading = true,
    this.failed = false,
    this.newMatch,
    this.notice = DiscoverNotice.none,
  });

  final List<Profile> deck;
  final bool loading;
  final bool failed;

  /// Set when the last swipe produced a match; the UI shows the overlay then calls
  /// [DiscoverController.clearMatch].
  final Profile? newMatch;
  final DiscoverNotice notice;

  DiscoverState copyWith({
    List<Profile>? deck,
    bool? loading,
    bool? failed,
    Profile? newMatch,
    bool clearMatch = false,
    DiscoverNotice? notice,
  }) {
    return DiscoverState(
      deck: deck ?? this.deck,
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
      newMatch: clearMatch ? null : (newMatch ?? this.newMatch),
      notice: notice ?? this.notice,
    );
  }
}

class DiscoverController extends Notifier<DiscoverState> {
  @override
  DiscoverState build() {
    ref.listen(preferencesProvider, (_, _) => unawaited(load()));
    unawaited(Future<void>.microtask(load));
    return const DiscoverState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, failed: false);
    try {
      final deck = await ref
          .read(discoveryRepositoryProvider)
          .fetchDeck(ref.read(preferencesProvider));
      state = state.copyWith(deck: deck, loading: false);
    } on Object {
      state = state.copyWith(loading: false, failed: true);
    }
  }

  /// Removes [profile] from the deck and records the swipe. A match is surfaced through
  /// [DiscoverState.newMatch]; a refused super like puts the card back.
  Future<void> swipe(Profile profile, SwipeAction action) async {
    state = state.copyWith(
      deck: state.deck.where((p) => p.id != profile.id).toList(),
    );
    final outcome = await ref
        .read(discoveryRepositoryProvider)
        .swipe(profile, action, premium: ref.read(sessionProvider).premium);
    if (outcome.limitReached) {
      state = state.copyWith(
        deck: [profile, ...state.deck],
        notice: DiscoverNotice.superLikeLimit,
      );
      return;
    }
    if (outcome.matched) {
      ref.read(conversationsProvider.notifier).addMatch(profile);
      state = state.copyWith(newMatch: profile);
    }
  }

  /// Drops [profileId] from the deck (blocked or reported people).
  void hide(String profileId) => state = state.copyWith(
    deck: state.deck.where((p) => p.id != profileId).toList(),
  );

  void clearMatch() => state = state.copyWith(clearMatch: true);

  void clearNotice() => state = state.copyWith(notice: DiscoverNotice.none);
}

final discoverProvider = NotifierProvider<DiscoverController, DiscoverState>(
  DiscoverController.new,
);

final likesYouProvider = FutureProvider<List<Profile>>(
  (ref) => ref.watch(discoveryRepositoryProvider).fetchLikesYou(),
);
