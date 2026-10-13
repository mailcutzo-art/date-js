import '../providers/session_providers.dart';
import 'app_routes.dart';

const _signedOutPaths = {
  AppRoutes.splash,
  AppRoutes.welcome,
  AppRoutes.signIn,
  AppRoutes.otp,
};

/// Where a user in [stage] may be. Returns null to stay, or the path to go to instead.
String? redirectFor(AuthStage stage, String location) {
  switch (stage) {
    case AuthStage.signedOut:
      return _signedOutPaths.contains(location) ? null : AppRoutes.welcome;
    case AuthStage.onboarding:
      return location == AppRoutes.setup ? null : AppRoutes.setup;
    case AuthStage.signedIn:
      final isAuthPath =
          _signedOutPaths.contains(location) || location == AppRoutes.setup;
      return isAuthPath ? AppRoutes.discover : null;
  }
}
