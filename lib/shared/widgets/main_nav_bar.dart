import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

class NavItem {
  const NavItem({required this.icon, required this.label, this.badge = 0});

  final SynkIcons icon;
  final String label;

  /// Unread count shown as a dot with a number (0 hides it).
  final int badge;
}

/// Bottom navigation: outline icons only (labels are for screen readers), the selected one
/// drawn in the foreground colour with a magenta dot underneath.
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
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    key: ValueKey('nav-${items[i].label}'),
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
    super.key,
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
                    AnimatedScale(
                      scale: selected ? 1.08 : 1,
                      duration: SynkMotion.progress,
                      curve: SynkMotion.fastOutSlowIn,
                      child: SynkIcon(
                        item.icon,
                        size: 26,
                        strokeWidth: selected ? 2.1 : 1.6,
                        color: selected
                            ? colors.foreground
                            : colors.mutedForeground,
                      ),
                    ),
                    if (item.badge > 0)
                      Positioned(
                        right: -8,
                        top: -5,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 17,
                            minHeight: 17,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: SynkPalette.hotMagenta,
                            borderRadius: SynkRadius.fullAll,
                            border: Border.all(
                              color: colors.background,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${item.badge}',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: SynkPalette.nightInk,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: SynkMotion.progress,
                  curve: SynkMotion.fastOutSlowIn,
                  width: selected ? 6 : 0,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: SynkPalette.hotMagenta,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
