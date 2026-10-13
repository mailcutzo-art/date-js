import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/otp_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat/chats_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/discover/profile_detail_screen.dart';
import '../../features/matches/matches_screen.dart';
import '../../features/onboarding/setup_screen.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/me_screen.dart';
import '../../features/profile/notifications_screen.dart';
import '../../features/profile/privacy_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../providers/session_providers.dart';
import '../shell/main_shell.dart';
import 'app_routes.dart';
import 'redirect.dart';
import 'transitions.dart';

/// The app's router: a stage machine driven by the session (signed out -> setup -> tabs), the
/// four main tabs as an indexed stack, and detail screens pushed over the tabs.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider.select((s) => s.stage), (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        redirectFor(ref.read(sessionProvider).stage, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            stagePage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) =>
            stagePage(state: state, child: const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        pageBuilder: (context, state) =>
            stackPage(state: state, child: const SignInScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (context, state) =>
            stackPage(state: state, child: const OtpScreen()),
      ),
      GoRoute(
        path: AppRoutes.setup,
        pageBuilder: (context, state) =>
            stagePage(state: state, child: const SetupScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.discover,
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.matches,
                builder: (context, state) => const MatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chats,
                builder: (context, state) => const ChatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.me,
                builder: (context, state) => const MeScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.chatPattern,
        pageBuilder: (context, state) => stackPage(
          state: state,
          child: ChatScreen(conversationId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.profilePattern,
        pageBuilder: (context, state) => stackPage(
          state: state,
          child: ProfileDetailScreen(profileId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) =>
            stackPage(state: state, child: const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            stackPage(state: state, child: const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        pageBuilder: (context, state) =>
            stackPage(state: state, child: const PrivacyScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            stackPage(state: state, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.premium,
        pageBuilder: (context, state) =>
            risePage(state: state, child: const PremiumScreen()),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
