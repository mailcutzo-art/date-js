import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/preferences.dart';
import '../../domain/models/profile.dart';
import 'repository_providers.dart';

enum AuthStage { signedOut, onboarding, signedIn }

class SessionState {
  const SessionState({
    this.stage = AuthStage.signedOut,
    this.phone = '',
    this.me,
    this.premium = false,
  });

  final AuthStage stage;
  final String phone;
  final Profile? me;
  final bool premium;

  SessionState copyWith({
    AuthStage? stage,
    String? phone,
    Profile? me,
    bool? premium,
  }) {
    return SessionState(
      stage: stage ?? this.stage,
      phone: phone ?? this.phone,
      me: me ?? this.me,
      premium: premium ?? this.premium,
    );
  }
}

/// Who is signed in and how far along they are. The router redirects on [SessionState.stage].
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  Future<void> requestOtp(String phone) async {
    await ref.read(authRepositoryProvider).requestOtp(phone);
    state = state.copyWith(phone: phone);
  }

  /// True (and moves on to onboarding) when [code] is accepted.
  Future<bool> verifyOtp(String code) async {
    final ok = await ref
        .read(authRepositoryProvider)
        .verifyOtp(state.phone, code);
    if (ok) state = state.copyWith(stage: AuthStage.onboarding);
    return ok;
  }

  /// Demo shortcut for "Continue with Google": skips the phone step.
  void continueWithGoogle() =>
      state = state.copyWith(stage: AuthStage.onboarding);

  void completeOnboarding(Profile me, Preferences preferences) {
    ref.read(preferencesProvider.notifier).set(preferences);
    state = state.copyWith(stage: AuthStage.signedIn, me: me);
  }

  void updateMe(Profile me) => state = state.copyWith(me: me);

  /// Demo toggle: a real build flips this from the billing flow, never from the UI.
  void setPremium({required bool value}) =>
      state = state.copyWith(premium: value);

  void signOut() => state = const SessionState();
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class PreferencesController extends Notifier<Preferences> {
  @override
  Preferences build() => const Preferences();

  void set(Preferences value) => state = value;
}

final preferencesProvider =
    NotifierProvider<PreferencesController, Preferences>(
      PreferencesController.new,
    );
