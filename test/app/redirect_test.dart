import 'package:date_js/app/providers/session_providers.dart';
import 'package:date_js/app/router/app_routes.dart';
import 'package:date_js/app/router/redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redirectFor', () {
    test(
      'signed-out users stay on the auth screens and are sent there otherwise',
      () {
        for (final p in [
          AppRoutes.splash,
          AppRoutes.welcome,
          AppRoutes.signIn,
          AppRoutes.otp,
        ]) {
          expect(redirectFor(AuthStage.signedOut, p), isNull, reason: p);
        }
        expect(
          redirectFor(AuthStage.signedOut, AppRoutes.discover),
          AppRoutes.welcome,
        );
        expect(
          redirectFor(AuthStage.signedOut, AppRoutes.setup),
          AppRoutes.welcome,
        );
        expect(
          redirectFor(AuthStage.signedOut, AppRoutes.chat('c-p1')),
          AppRoutes.welcome,
        );
      },
    );

    test('users in onboarding can only see the setup', () {
      expect(redirectFor(AuthStage.onboarding, AppRoutes.setup), isNull);
      expect(
        redirectFor(AuthStage.onboarding, AppRoutes.welcome),
        AppRoutes.setup,
      );
      expect(
        redirectFor(AuthStage.onboarding, AppRoutes.discover),
        AppRoutes.setup,
      );
    });

    test('signed-in users skip the auth screens', () {
      for (final p in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.otp,
        AppRoutes.setup,
      ]) {
        expect(
          redirectFor(AuthStage.signedIn, p),
          AppRoutes.discover,
          reason: p,
        );
      }
      expect(redirectFor(AuthStage.signedIn, AppRoutes.chats), isNull);
      expect(redirectFor(AuthStage.signedIn, AppRoutes.premium), isNull);
    });
  });
}
