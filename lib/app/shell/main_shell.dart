import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/main_nav_bar.dart';
import '../../design_system/design_system.dart';
import '../providers/chat_providers.dart';

/// Frame of the four main tabs (Discover, Matches, Chats, Profile) with the bottom bar. Each
/// tab keeps its own navigation stack and scroll position.
class MainShell extends ConsumerWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(conversationsProvider.select((s) => s.unread));
    return Scaffold(
      backgroundColor: context.colors.background,
      body: navigationShell,
      bottomNavigationBar: MainNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          // Tapping the active tab pops it back to its first screen.
          initialLocation: i == navigationShell.currentIndex,
        ),
        items: [
          const NavItem(icon: SynkIcons.flame, label: 'Discover'),
          const NavItem(icon: SynkIcons.heart, label: 'Matches'),
          NavItem(icon: SynkIcons.chat, label: 'Chats', badge: unread),
          const NavItem(icon: SynkIcons.userCircle, label: 'Profile'),
        ],
      ),
    );
  }
}
