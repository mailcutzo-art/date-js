import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/chat_providers.dart';
import '../../app/providers/discover_providers.dart';
import '../../app/providers/repository_providers.dart';
import '../../app/shell/root_shell.dart';
import '../../design_system/design_system.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/report_reason.dart';

/// Report, block and unmatch flows, shared by the chat and the profile detail. Each returns
/// true when the person is gone from the user's lists (so the caller can leave the screen).
abstract final class SafetyActions {
  static String _conversationId(Profile p) => 'c-${p.id}';

  static Future<bool> report(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final reason = await showSynkBottomSheet<ReportReason>(
      context,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            children: [
              SheetTitle('Report ${profile.name}'),
              const SheetDescription(
                'Tell us what is wrong. Reports are anonymous.',
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final r in ReportReason.values)
            SynkPressable(
              onTap: () => Navigator.of(context).pop(r),
              semanticLabel: r.label,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(child: SynkText(r.label)),
                    SynkIcon(
                      SynkIcons.forward,
                      size: 18,
                      color: context.colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return false;
    await ref.read(chatRepositoryProvider).report(profile.id, reason);
    ref
        .read(toastControllerProvider)
        .show(
          'Report sent',
          description: 'Thanks, our team will take a look.',
          variant: ToastVariant.success,
        );
    return false;
  }

  static Future<bool> block(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Block ${profile.name}?',
      description:
          'They will not see your profile or be able to message you. '
          'You can unblock them later in Privacy and safety.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Block',
    );
    if (!confirmed) return false;
    final chats = ref.read(conversationsProvider.notifier);
    if (chats.byId(_conversationId(profile)) != null) {
      await chats.block(_conversationId(profile));
    } else {
      await ref.read(chatRepositoryProvider).block(profile.id);
    }
    ref.read(discoverProvider.notifier).hide(profile.id);
    ref.read(toastControllerProvider).show('${profile.name} blocked');
    return true;
  }

  static Future<bool> unmatch(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Unmatch with ${profile.name}?',
      description: 'Your conversation will be deleted for both of you.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Unmatch',
    );
    if (!confirmed) return false;
    await ref
        .read(conversationsProvider.notifier)
        .unmatch(_conversationId(profile));
    ref.read(toastControllerProvider).show('Unmatched');
    return true;
  }
}
