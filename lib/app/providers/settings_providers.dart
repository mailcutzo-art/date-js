import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  const SettingsState({
    this.pushMatches = true,
    this.pushMessages = true,
    this.pushLikes = false,
    this.showDistance = true,
    this.showAge = true,
    this.readReceipts = true,
    this.incognito = false,
  });

  final bool pushMatches;
  final bool pushMessages;
  final bool pushLikes;
  final bool showDistance;
  final bool showAge;
  final bool readReceipts;
  final bool incognito;

  SettingsState copyWith({
    bool? pushMatches,
    bool? pushMessages,
    bool? pushLikes,
    bool? showDistance,
    bool? showAge,
    bool? readReceipts,
    bool? incognito,
  }) {
    return SettingsState(
      pushMatches: pushMatches ?? this.pushMatches,
      pushMessages: pushMessages ?? this.pushMessages,
      pushLikes: pushLikes ?? this.pushLikes,
      showDistance: showDistance ?? this.showDistance,
      showAge: showAge ?? this.showAge,
      readReceipts: readReceipts ?? this.readReceipts,
      incognito: incognito ?? this.incognito,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void update(SettingsState Function(SettingsState current) change) =>
      state = change(state);
}

final settingsProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
