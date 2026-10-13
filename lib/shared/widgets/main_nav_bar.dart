import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../brand_colors.dart';

class NavItem {
  const NavItem({required this.icon, required this.label, this.badge = 0});

  final SynkIcons icon;
  final String label;

  /// Unread count shown as a dot with a number (0 hides it).
  final int badge;
}

/// Bottom navigation: icons with a sliding pill behind the selected one.
class MainNavBar extends StatelessWidget {
  const MainNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: item.badge > 0
          ? '${item.label}, ${item.badge} unread'
          : item.label,
      child: ExcludeSemantics(
        child: SynkPressable(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: SynkMotion.progress,
                      curve: SynkMotion.fastOutSlowIn,
                      width: selected ? 56 : 36,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primary.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: SynkRadius.fullAll,
                      ),
                      alignment: Alignment.center,
                      child: SynkIcon(
                        item.icon,
                        size: 22,
                        color: selected
                            ? colors.brandText
                            : colors.mutedForeground,
                      ),
                    ),
                    if (item.badge > 0)
                      Positioned(
                        right: selected ? 4 : -2,
                        top: -2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: SynkRadius.fullAll,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${item.badge}',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryForeground,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                SynkText(
                  item.label,
                  variant: SynkTextVariant.listDescription,
                  color: selected ? colors.brandText : colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
