import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/chat_providers.dart';
import '../../app/router/app_routes.dart';
import '../../core/utils/chat_time.dart';
import '../../design_system/design_system.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../shared/widgets/profile_avatar.dart';

/// Chats tab: a row of new matches to say hello to, then the conversations, latest first.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsProvider);
    final fresh = [
      for (final c in state.items)
        if (!c.hasMessages) c,
    ];
    final active = [
      for (final c in state.items)
        if (c.hasMessages) c,
    ];
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: state.loading && state.items.isEmpty
            ? const _ListSkeleton()
            : state.items.isEmpty
            ? EmptyState(
                icon: SynkIcons.chat,
                title: 'No conversations yet',
                body: 'Match with someone and your chats will appear here.',
                actionLabel: 'Go to Discover',
                onAction: () => context.go(AppRoutes.discover),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: SynkText('Messages', variant: SynkTextVariant.h2),
                  ),
                  if (fresh.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: SectionLabel('New matches'),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: fresh.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (context, i) =>
                            _NewMatch(conversation: fresh[i]),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (active.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                      child: SectionLabel('Conversations'),
                    ),
                    for (final c in active) _ConversationTile(conversation: c),
                  ],
                ],
              ),
      ),
    );
  }
}

class _NewMatch extends StatelessWidget {
  const _NewMatch({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return SynkPressable(
      semanticLabel: 'New match ${conversation.other.name}',
      onTap: () => context.push(AppRoutes.chat(conversation.id)),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            ProfileAvatar(profile: conversation.other, size: 64, ring: true),
            const SizedBox(height: 6),
            SynkText(
              conversation.other.name,
              variant: SynkTextVariant.small,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  String get _preview {
    final last = conversation.last!;
    final prefix = last.fromMe ? 'You: ' : '';
    return switch (last.kind) {
      MessageKind.text => '$prefix${last.text}',
      MessageKind.image => '${prefix}Sent a photo',
      MessageKind.voice => '${prefix}Voice message',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unread = conversation.unread > 0;
    final last = conversation.last!;
    return SynkPressable(
      semanticLabel:
          '${conversation.other.name}, ${unread ? '${conversation.unread} unread, ' : ''}$_preview',
      onTap: () => context.push(AppRoutes.chat(conversation.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            ProfileAvatar(profile: conversation.other, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SynkText(
                    conversation.other.name,
                    variant: SynkTextVariant.large,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  conversation.typing
                      ? SynkText(
                          'typing…',
                          variant: SynkTextVariant.small,
                          color: colors.primary,
                        )
                      : SynkText(
                          _preview,
                          variant: SynkTextVariant.muted,
                          maxLines: 1,
                          color: unread ? colors.foreground : null,
                        ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SynkText(
                  formatChatTime(last.sentAt, DateTime.now()),
                  variant: SynkTextVariant.listDescription,
                ),
                const SizedBox(height: 6),
                if (unread)
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: SynkRadius.fullAll,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${conversation.unread}',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryForeground,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 5; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Row(
              children: [
                Skeleton(width: 56, height: 56, radius: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 120, height: 14),
                      SizedBox(height: 8),
                      Skeleton(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
