import 'package:flutter/material.dart';

import '../icons/synk_icon.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_button.dart';
import 'synk_text.dart';

/// Inline empty / error state used inside screens: a centred column with a muted 28dp icon,
/// a medium [title], an optional muted [body] and an optional full-width action button.
///
/// Padding is vertical 40 / horizontal 20 (vertical 20 / horizontal 16 when [compact], which
/// also tightens the gaps and shrinks the icon). The action only renders when both
/// [actionLabel] and [onAction] are given; it is a primary pill-ish button unless
/// [outlineAction] is set. The icon is decorative; title and body read as one node.
class InlineState extends StatelessWidget {
  const InlineState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.outlineAction = false,
    this.announce = false,
  });

  final SynkIcons icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final bool outlineAction;

  /// A live region: a screen reader reads the state out when it appears (a failure that
  /// replaces a list the person was waiting for).
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasAction = actionLabel != null && onAction != null;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: compact
            ? const EdgeInsets.symmetric(vertical: 20, horizontal: 16)
            : const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MergeSemantics(
              child: Semantics(
                liveRegion: announce ? true : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: SynkIcon(
                        icon,
                        size: compact ? 24 : 28,
                        color: colors.mutedForeground,
                        strokeWidth: 1.5,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    SynkText(
                      title,
                      variant: SynkTextVariant.small,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 4),
                      SynkText(
                        body!,
                        variant: SynkTextVariant.muted,
                        style: const TextStyle(fontSize: 12, height: 20 / 12),
                        color: colors.mutedForeground,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (hasAction) ...[
              SizedBox(height: compact ? 12 : 16),
              SynkButton(
                label: actionLabel,
                size: SynkButtonSize.sm,
                variant: outlineAction
                    ? SynkButtonVariant.outline
                    : SynkButtonVariant.primary,
                expand: true,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Nothing here yet" state: [InlineState] with the users icon by default.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.icon = SynkIcons.users,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? body;
  final SynkIcons icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) => InlineState(
    icon: icon,
    title: title,
    body: body,
    actionLabel: actionLabel,
    onAction: onAction,
    compact: compact,
  );
}

/// Failure state: [InlineState] with the alert icon and a retry action. The retry button shows
/// when [onRetry] (or the generic [onAction]) is given; [actionLabel] overrides [retryLabel].
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.body,
    this.icon = SynkIcons.alert,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? body;
  final SynkIcons icon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) => InlineState(
    icon: icon,
    title: title,
    body: body,
    actionLabel: actionLabel ?? retryLabel,
    onAction: onAction ?? onRetry,
    compact: compact,
    outlineAction: true,
    announce: true,
  );
}
