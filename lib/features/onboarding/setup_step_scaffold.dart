import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Shared layout of every setup step: scrolling title + content, and a pinned bottom bar with
/// the main button (and an optional skip). The bar rides above the keyboard.
class SetupStepScaffold extends StatelessWidget {
  const SetupStepScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    this.ctaLabel = 'Continue',
    this.ctaEnabled = true,
    this.loading = false,
    this.onCta,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String ctaLabel;
  final bool ctaEnabled;
  final bool loading;
  final VoidCallback? onCta;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: SynkSpace.columnMax,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SynkText(title, variant: SynkTextVariant.h1),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      SynkText(subtitle!, variant: SynkTextVariant.muted),
                    ],
                    const SizedBox(height: 28),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SynkSpace.columnMax),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SynkButton(
                    label: ctaLabel,
                    size: SynkButtonSize.lg,
                    expand: true,
                    loading: loading,
                    onPressed: ctaEnabled ? onCta : null,
                  ),
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: 4),
                    SynkButton(
                      label: secondaryLabel,
                      variant: SynkButtonVariant.ghost,
                      expand: true,
                      onPressed: onSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
