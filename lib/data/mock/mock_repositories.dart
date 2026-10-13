import 'dart:math';

import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/preferences.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/report_reason.dart';
import '../../domain/models/swipe.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/discovery_repository.dart';
import 'mock_profiles.dart';

/// DEMO IMPLEMENTATIONS. They keep everything in memory and wait [latency] to feel like a network.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;

  @override
  Future<void> requestOtp(String phone) => Future<void>.delayed(latency);

  @override
  Future<bool> verifyOtp(String phone, String code) async {
    await Future<void>.delayed(latency);
    return code == kDemoOtp;
  }
}

class MockDiscoveryRepository implements DiscoveryRepository {
  MockDiscoveryRepository({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;
  int _superLikesUsed = 0;
  static const int freeSuperLikes = 1;

  @override
  Future<List<Profile>> fetchDeck(Preferences prefs) async {
    await Future<void>.delayed(latency);
    return kDemoProfiles.where((p) {
      if (kSeededMatchIds.contains(p.id)) return false;
      if (!prefs.interestedIn.contains(p.gender)) return false;
      if (p.age < prefs.minAge || p.age > prefs.maxAge) return false;
      if (p.distanceKm > prefs.maxDistanceKm) return false;
      if (prefs.verifiedOnly && !p.verified) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<Profile>> fetchLikesYou() async {
    await Future<void>.delayed(latency);
    return kDemoProfiles.where((p) => p.likesYou).toList();
  }

  @override
  Future<SwipeOutcome> swipe(
    Profile profile,
    SwipeAction action, {
    required bool premium,
  }) async {
    if (action == SwipeAction.superLike && !premium) {
      if (_superLikesUsed >= freeSuperLikes) {
        return const SwipeOutcome(matched: false, limitReached: true);
      }
      _superLikesUsed++;
    }
    final liked = action != SwipeAction.pass;
    return SwipeOutcome(matched: liked && profile.likesYou);
  }
}

class MockChatRepository implements ChatRepository {
  MockChatRepository({
    this.latency = const Duration(milliseconds: 900),
    Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? Random(7),
       _clock = clock ?? DateTime.now;

  final Duration latency;
  final DateTime Function() _clock;
  final Random _random;

  static const List<String> _replies = [
    'Haha, I like that. Tell me more?',
    'Okay you have my attention.',
    'We should definitely get coffee this week.',
    'That is such a good answer.',
    'Honestly same.',
  ];

  @override
  Future<List<Conversation>> loadConversations() async {
    final now = _clock();
    final tara = kDemoProfiles[10]; // Tara
    final vikram = kDemoProfiles[11]; // Vikram
    return [
      Conversation(
        id: 'c-${tara.id}',
        other: tara,
        matchedAt: now.subtract(const Duration(days: 1)),
        unread: 2,
        messages: [
          Message(
            id: 'm1',
            fromMe: true,
            kind: MessageKind.text,
            text: 'Your hiking photo is unfair. Where was that?',
            sentAt: now.subtract(const Duration(hours: 5)),
            status: MessageStatus.read,
          ),
          Message(
            id: 'm2',
            fromMe: false,
            kind: MessageKind.text,
            text: 'Nandi Hills at sunrise. You should come next time.',
            sentAt: now.subtract(const Duration(hours: 4, minutes: 20)),
          ),
          Message(
            id: 'm3',
            fromMe: false,
            kind: MessageKind.text,
            text: 'Bring snacks.',
            sentAt: now.subtract(const Duration(hours: 4, minutes: 19)),
          ),
        ],
      ),
      Conversation(
        id: 'c-${vikram.id}',
        other: vikram,
        matchedAt: now.subtract(const Duration(days: 3)),
        messages: [
          Message(
            id: 'm4',
            fromMe: false,
            kind: MessageKind.voice,
            voiceSeconds: 12,
            sentAt: now.subtract(const Duration(days: 2)),
          ),
          Message(
            id: 'm5',
            fromMe: true,
            kind: MessageKind.text,
            text: 'Ha! Okay, Friday it is.',
            sentAt: now.subtract(const Duration(days: 2, minutes: -3)),
            status: MessageStatus.read,
          ),
        ],
      ),
    ];
  }

  @override
  Future<Message?> replyTo(Conversation conversation, Message sent) async {
    await Future<void>.delayed(latency);
    if (sent.kind != MessageKind.text && _random.nextBool()) return null;
    return Message(
      id: 'r-${DateTime.now().microsecondsSinceEpoch}',
      fromMe: false,
      kind: MessageKind.text,
      text: _replies[_random.nextInt(_replies.length)],
      sentAt: DateTime.now(),
    );
  }

  @override
  Future<void> report(String profileId, ReportReason reason) =>
      Future<void>.delayed(latency ~/ 3);

  @override
  Future<void> block(String profileId) => Future<void>.delayed(latency ~/ 3);

  @override
  Future<void> unmatch(String profileId) => Future<void>.delayed(latency ~/ 3);
}
