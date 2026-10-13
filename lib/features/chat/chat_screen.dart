import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/chat_providers.dart';
import '../../app/router/app_routes.dart';
import '../../design_system/design_system.dart';
import '../../domain/models/conversation.dart';
import '../../shared/widgets/message_bubble.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../../shared/widgets/typing_indicator.dart';
import '../../shared/widgets/verified_badge.dart';
import 'composer.dart';
import 'safety_actions.dart';

const List<String> _openers = [
  'What\'s the best thing you ate this week?',
  'Coffee person or chai person?',
  'What would your perfect Sunday look like?',
];

/// One conversation: header with safety menu, the message list (newest at the bottom) and the
/// composer. A fresh match shows suggested openers.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _draft = TextEditingController();
  late final ConversationsController _chats = ref.read(
    conversationsProvider.notifier,
  );

  @override
  void initState() {
    super.initState();
    // Not during build: marking read changes provider state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chats.setOpen(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _chats.setOpen(null);
    _draft.dispose();
    super.dispose();
  }

  Future<void> _menu(Conversation c) async {
    final choice = await showSynkBottomSheet<String>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(children: [SheetTitle(c.other.name)]),
          const SizedBox(height: 8),
          SynkButton(
            label: 'View profile',
            variant: SynkButtonVariant.secondary,
            leadingIcon: SynkIcons.user,
            onPressed: () => Navigator.of(sheet).pop('profile'),
          ),
          const SizedBox(height: 8),
          SynkButton(
            label: 'Report',
            variant: SynkButtonVariant.secondary,
            leadingIcon: SynkIcons.alert,
            onPressed: () => Navigator.of(sheet).pop('report'),
          ),
          const SizedBox(height: 8),
          SynkButton(
            label: 'Block',
            variant: SynkButtonVariant.secondary,
            leadingIcon: SynkIcons.blocked,
            onPressed: () => Navigator.of(sheet).pop('block'),
          ),
          const SizedBox(height: 8),
          SynkButton(
            label: 'Unmatch',
            variant: SynkButtonVariant.destructive,
            leadingIcon: SynkIcons.userMinus,
            onPressed: () => Navigator.of(sheet).pop('unmatch'),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'profile') {
      await context.push(AppRoutes.profile(c.other.id));
      return;
    }
    final bool left;
    if (choice == 'report') {
      left = await SafetyActions.report(context, ref, c.other);
    } else if (choice == 'block') {
      left = await SafetyActions.block(context, ref, c.other);
    } else {
      left = await SafetyActions.unmatch(context, ref, c.other);
    }
    if (left && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(conversationProvider(widget.conversationId));
    final colors = context.colors;
    if (c == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SubpageHeader(title: 'Chat', onBack: context.pop),
              const Expanded(
                child: EmptyState(
                  title: 'Conversation not found',
                  body: 'It may have been removed.',
                ),
              ),
            ],
          ),
        ),
      );
    }
    final messages = c.messages.reversed.toList();
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(conversation: c, onMenu: () => _menu(c)),
            Expanded(
              child: c.hasMessages || c.typing
                  ? ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: messages.length + (c.typing ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (c.typing && i == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TypingIndicator(),
                            ),
                          );
                        }
                        final index = c.typing ? i - 1 : i;
                        final m = messages[index];
                        // Newest first: "next" in time is index - 1.
                        final newer = index > 0 ? messages[index - 1] : null;
                        final showTime =
                            newer == null ||
                            newer.fromMe != m.fromMe ||
                            newer.sentAt.difference(m.sentAt).inMinutes >= 5;
                        return Padding(
                          padding: EdgeInsets.only(top: showTime ? 10 : 3),
                          child: MessageBubble(message: m, showTime: showTime),
                        );
                      },
                    )
                  : _Intro(
                      conversation: c,
                      onPick: (text) => _draft.text = text,
                    ),
            ),
            Composer(
              controller: _draft,
              onSendText: (t) => _chats.sendText(c.id, t),
              onSendPhoto: () =>
                  _chats.sendImage(c.id, 300 + c.messages.length * 7),
              onSendVoice: (s) => _chats.sendVoice(c.id, s),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.conversation, required this.onMenu});

  final Conversation conversation;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final other = conversation.other;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          CircleIconButton(
            icon: SynkIcons.arrowLeft,
            semanticLabel: 'Back',
            tone: CircleButtonTone.soft,
            diameter: 40,
            onPressed: context.pop,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SynkPressable(
              semanticLabel: 'Open ${other.name}\'s profile',
              onTap: () => context.push(AppRoutes.profile(other.id)),
              child: Row(
                children: [
                  ProfileAvatar(profile: other, size: 40),
                  const SizedBox(width: 10),
                  Flexible(
                    child: SynkText(
                      other.name,
                      variant: SynkTextVariant.large,
                      maxLines: 1,
                    ),
                  ),
                  if (other.verified) ...[
                    const SizedBox(width: 6),
                    const VerifiedBadge(size: 16),
                  ],
                ],
              ),
            ),
          ),
          CircleIconButton(
            icon: SynkIcons.more,
            semanticLabel: 'Chat options',
            tone: CircleButtonTone.soft,
            diameter: 40,
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.conversation, required this.onPick});

  final Conversation conversation;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(profile: conversation.other, size: 96, ring: true),
            const SizedBox(height: 16),
            SynkText(
              'You matched with ${conversation.other.name}',
              variant: SynkTextVariant.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const SynkText(
              'Break the ice with one of these, or write your own.',
              variant: SynkTextVariant.muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            for (final o in _openers)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SynkChip(label: o, onTap: () => onPick(o)),
              ),
          ],
        ),
      ),
    );
  }
}
