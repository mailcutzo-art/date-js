import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../design_system/design_system.dart';

/// Small upsell sheet shown when a free account hits a premium limit (extra super likes, who
/// likes you, verified-only filter...). "See Premium" opens the paywall.
Future<void> showPremiumPrompt(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final open = await showSynkBottomSheet<bool>(
    context,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: SynkPalette.amber.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const SynkIcon(
              SynkIcons.crown,
              size: 28,
              color: SynkPalette.amber,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SheetHeader(children: [SheetTitle(title), SheetDescription(body)]),
        const SizedBox(height: 18),
        SynkButton(
          label: 'See Premium',
          expand: true,
          size: SynkButtonSize.lg,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
        const SizedBox(height: 6),
        SynkButton(
          label: 'Maybe later',
          variant: SynkButtonVariant.ghost,
          expand: true,
          onPressed: () => Navigator.of(sheetContext).pop(false),
        ),
      ],
    ),
  );
  if (open == true && context.mounted) await context.push(AppRoutes.premium);
}
