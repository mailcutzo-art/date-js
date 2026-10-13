import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/report_reason.dart';
import 'repository_providers.dart';

class ConversationsState {
  const ConversationsState({this.items = const [], this.loading = true});

  /// Most recent activity first.
  final List<Conversation> items;
  final bool loading;

  int get unread => items.fold(0, (sum, c) => sum + c.unread);
}

class ConversationsController extends Notifier<ConversationsState> {
  String? _openId;
  int _nextId = 0;

  @override
  ConversationsState build() {
    unawaited(Future<void>.microtask(load));
    return const ConversationsState();
  }

  Future<void> load() async {
    final items = await ref.read(chatRepositoryProvider).loadConversations();
    state = ConversationsState(items: _sorted(items), loading: false);
  }

  List<Conversation> _sorted(List<Conversation> items) {
    final copy = [...items];
    DateTime activity(Conversation c) => c.last?.sentAt ?? c.matchedAt;
    copy.sort((a, b) => activity(b).compareTo(activity(a)));
    return copy;
  }

  void _replace(Conversation updated) {
    state = ConversationsState(
      items: _sorted([
        for (final c in state.items) c.id == updated.id ? updated : c,
      ]),
      loading: false,
    );
  }

  Conversation? byId(String id) {
    for (final c in state.items) {
      if (c.id == id) return c;
    }
    return null;
  }

  void addMatch(Profile profile) {
    final id = 'c-${profile.id}';
    if (byId(id) != null) return;
    state = ConversationsState(
      items: _sorted([
        Conversation(id: id, other: profile, matchedAt: DateTime.now()),
        ...state.items,
      ]),
      loading: false,
    );
  }

  /// The chat screen tells the list which conversation is on screen, so replies that arrive
  /// meanwhile do not count as unread.
  void setOpen(String? id) {
    _openId = id;
    if (id != null) markRead(id);
  }

  void markRead(String id) {
    final c = byId(id);
    if (c == null || c.unread == 0) return;
    _replace(c.copyWith(unread: 0));
  }

  Future<void> sendText(String id, String text) => _send(
    id,
    Message(
      id: 'o-${_nextId++}',
      fromMe: true,
      kind: MessageKind.text,
      text: text.trim(),
      sentAt: DateTime.now(),
    ),
  );

  Future<void> sendImage(String id, int seed) => _send(
    id,
    Message(
      id: 'o-${_nextId++}',
      fromMe: true,
      kind: MessageKind.image,
      imageSeed: seed,
      sentAt: DateTime.now(),
    ),
  );

  Future<void> sendVoice(String id, int seconds) => _send(
    id,
    Message(
      id: 'o-${_nextId++}',
      fromMe: true,
      kind: MessageKind.voice,
      voiceSeconds: seconds,
      sentAt: DateTime.now(),
    ),
  );

  Future<void> _send(String id, Message message) async {
    final conversation = byId(id);
    if (conversation == null) return;
    if (message.kind == MessageKind.text && message.text.isEmpty) return;
    _replace(
      conversation.copyWith(
        messages: [...conversation.messages, message],
        typing: true,
      ),
    );
    final reply = await ref
        .read(chatRepositoryProvider)
        .replyTo(conversation, message);
    final current = byId(id);
    if (current == null) return; // unmatched or blocked while waiting
    final messages = [
      for (final m in current.messages)
        m.id == message.id ? m.copyWith(status: MessageStatus.read) : m,
      ?reply,
    ];
    _replace(
      current.copyWith(
        messages: messages,
        typing: false,
        unread: reply != null && _openId != id
            ? current.unread + 1
            : current.unread,
      ),
    );
  }

  Future<void> report(String id, ReportReason reason) async {
    final c = byId(id);
    if (c == null) return;
    await ref.read(chatRepositoryProvider).report(c.other.id, reason);
  }

  Future<void> block(String id) async {
    final c = byId(id);
    if (c == null) return;
    await ref.read(chatRepositoryProvider).block(c.other.id);
    _remove(id);
  }

  Future<void> unmatch(String id) async {
    final c = byId(id);
    if (c == null) return;
    await ref.read(chatRepositoryProvider).unmatch(c.other.id);
    _remove(id);
  }

  void _remove(String id) {
    state = ConversationsState(
      items: [
        for (final c in state.items)
          if (c.id != id) c,
      ],
      loading: false,
    );
  }
}

final conversationsProvider =
    NotifierProvider<ConversationsController, ConversationsState>(
      ConversationsController.new,
    );

final conversationProvider = Provider.family<Conversation?, String>((ref, id) {
  final items = ref.watch(conversationsProvider).items;
  for (final c in items) {
    if (c.id == id) return c;
  }
  return null;
});
