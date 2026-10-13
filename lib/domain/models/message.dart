enum MessageKind { text, image, voice }

enum MessageStatus { sending, sent, read }

class Message {
  const Message({
    required this.id,
    required this.fromMe,
    required this.kind,
    required this.sentAt,
    this.text = '',
    this.imageSeed,
    this.voiceSeconds,
    this.status = MessageStatus.sent,
  });

  final String id;
  final bool fromMe;
  final MessageKind kind;
  final DateTime sentAt;
  final String text;

  /// Seed of the generated artwork for [MessageKind.image].
  final int? imageSeed;

  /// Length of a [MessageKind.voice] note.
  final int? voiceSeconds;
  final MessageStatus status;

  Message copyWith({MessageStatus? status}) {
    return Message(
      id: id,
      fromMe: fromMe,
      kind: kind,
      sentAt: sentAt,
      text: text,
      imageSeed: imageSeed,
      voiceSeconds: voiceSeconds,
      status: status ?? this.status,
    );
  }
}
