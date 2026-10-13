import '../models/conversation.dart';
import '../models/message.dart';
import '../models/report_reason.dart';

abstract interface class ChatRepository {
  Future<List<Conversation>> loadConversations();

  /// The other person's answer to [sent] (null when they stay silent).
  Future<Message?> replyTo(Conversation conversation, Message sent);

  Future<void> report(String profileId, ReportReason reason);

  Future<void> block(String profileId);

  Future<void> unmatch(String profileId);
}
