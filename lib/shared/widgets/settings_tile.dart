import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Titled group of [SettingsTile]s inside one rounded card.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: SectionLabel(title),
        ),
        SynkCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SynkSeparator(),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One settings row: icon, title, optional subtitle and a trailing control. Give it [onTap] for
/// a navigation row (chevron shown) or a [trailing] switch for a toggle.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    super.key,
  });

  final SynkIcons icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = destructive ? colors.destructive : colors.foreground;
    return SynkPressable(
      onTap: onTap,
      semanticLabel: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SynkIcon(icon, size: 20, color: tint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SynkText(title, variant: SynkTextVariant.p, color: tint),
                  if (subtitle != null)
                    SynkText(subtitle!, variant: SynkTextVariant.muted),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              SynkIcon(
                SynkIcons.forward,
                size: 18,
                color: colors.mutedForeground,
              ),
          ],
        ),
      ),
    );
  }
}
