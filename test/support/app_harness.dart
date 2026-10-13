import 'dart:ui' show AccessibilityFeatures;

import 'package:date_js/app.dart';
import 'package:date_js/app/providers/clock_provider.dart';
import 'package:date_js/app/providers/onboarding_providers.dart';
import 'package:date_js/app/providers/repository_providers.dart';
import 'package:date_js/app/providers/session_providers.dart';
import 'package:date_js/data/mock/mock_repositories.dart';
import 'package:date_js/domain/models/gender.dart';
import 'package:date_js/domain/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// The fixed "now" of every test app: seeded chat times and "time ago" labels are stable.
final DateTime kTestNow = DateTime(2026, 10, 14, 15, 30);

/// A signed-in user for tests that start inside the app.
const Profile kTestMe = Profile(
  id: 'me',
  name: 'Sam',
  age: 28,
  gender: Gender.man,
  photos: [
    ProfilePhoto(id: 'me-0', seed: 201),
    ProfilePhoto(id: 'me-1', seed: 202),
  ],
  bio: 'Test bio',
  city: 'Bengaluru',
  interests: ['Coffee', 'Hiking', 'Books'],
);

class SeededSession extends SessionController {
  SeededSession(this._initial);

  final SessionState _initial;

  @override
  SessionState build() => _initial;
}

class SeededDraft extends OnboardingController {
  SeededDraft(this._initial);

  final OnboardingDraft _initial;

  @override
  OnboardingDraft build() => _initial;
}

SessionState signedIn({bool premium = false}) =>
    SessionState(stage: AuthStage.signedIn, me: kTestMe, premium: premium);

/// The whole app with zero-latency demo repositories.
Widget testApp({
  SessionState? session,
  OnboardingDraft? draft,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        MockAuthRepository(latency: Duration.zero),
      ),
      discoveryRepositoryProvider.overrideWithValue(
        MockDiscoveryRepository(latency: Duration.zero),
      ),
      clockProvider.overrideWithValue(() => kTestNow),
      chatRepositoryProvider.overrideWithValue(
        MockChatRepository(latency: Duration.zero, clock: () => kTestNow),
      ),
      if (session != null)
        sessionProvider.overrideWith(() => SeededSession(session)),
      if (draft != null)
        onboardingProvider.overrideWith(() => SeededDraft(draft)),
      ...overrides,
    ],
    child: const DateJsApp(),
  );
}

/// Phone-sized view, and reduced motion so the endless decorative loops (logo, floating
/// cards, confetti) stop and `pumpAndSettle` can finish.
void usePhone(WidgetTester tester, {Size size = const Size(420, 900)}) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const _ReducedMotion();
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

class _ReducedMotion implements AccessibilityFeatures {
  const _ReducedMotion();

  @override
  bool get disableAnimations => true;

  @override
  bool get accessibleNavigation => false;
  @override
  bool get boldText => false;
  @override
  bool get highContrast => false;
  @override
  bool get invertColors => false;
  @override
  bool get onOffSwitchLabels => false;
  @override
  bool get reduceMotion => true;
  @override
  bool get supportsAnnounce => true;
  @override
  bool get autoPlayAnimatedImages => false;
  @override
  bool get autoPlayVideos => false;
  @override
  bool get deterministicCursor => false;
}

/// Pumps [steps] frames of [step] each: for screens whose animations never settle.
Future<void> pumpFrames(
  WidgetTester tester, {
  int steps = 10,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}
