import 'message.dart';
import 'profile.dart';

/// A match and the messages exchanged with that person.
class Conversation {
  const Conversation({
    required this.id,
    required this.other,
    required this.matchedAt,
    this.messages = const [],
    this.unread = 0,
    this.typing = false,
  });

  final String id;

  /// The other person.
  final Profile other;
  final DateTime matchedAt;
  final List<Message> messages;
  final int unread;
  final bool typing;

  Message? get last => messages.isEmpty ? null : messages.last;

  bool get hasMessages => messages.isNotEmpty;

  Conversation copyWith({List<Message>? messages, int? unread, bool? typing}) {
    return Conversation(
      id: id,
      other: other,
      matchedAt: matchedAt,
      messages: messages ?? this.messages,
      unread: unread ?? this.unread,
      typing: typing ?? this.typing,
    );
  }
}
