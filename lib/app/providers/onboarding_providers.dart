import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gender.dart';
import '../../domain/models/interest.dart';
import '../../domain/models/preferences.dart';
import '../../domain/models/profile.dart';

/// Everything the user types during profile setup, kept while they move between steps.
class OnboardingDraft {
  const OnboardingDraft({
    this.name = '',
    this.birthday,
    this.gender,
    this.interestedIn = const {},
    this.photoSeeds = const [],
    this.bio = '',
    this.interests = const {},
    this.city = '',
    this.verified = false,
  });

  final String name;
  final DateTime? birthday;
  final Gender? gender;
  final Set<Gender> interestedIn;
  final List<int> photoSeeds;
  final String bio;
  final Set<String> interests;
  final String city;
  final bool verified;

  int? ageAt(DateTime now) {
    final b = birthday;
    if (b == null) return null;
    var age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      age--;
    }
    return age;
  }

  OnboardingDraft copyWith({
    String? name,
    DateTime? birthday,
    Gender? gender,
    Set<Gender>? interestedIn,
    List<int>? photoSeeds,
    String? bio,
    Set<String>? interests,
    String? city,
    bool? verified,
  }) {
    return OnboardingDraft(
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      photoSeeds: photoSeeds ?? this.photoSeeds,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      city: city ?? this.city,
      verified: verified ?? this.verified,
    );
  }

  Profile toProfile(DateTime now) {
    return Profile(
      id: 'me',
      name: name.trim(),
      age: ageAt(now) ?? 18,
      gender: gender ?? Gender.woman,
      photos: [
        for (var i = 0; i < photoSeeds.length; i++)
          ProfilePhoto(id: 'me-$i', seed: photoSeeds[i]),
      ],
      bio: bio.trim(),
      city: city,
      interests: interests.take(kMaxInterests).toList(),
      verified: verified,
    );
  }

  Preferences toPreferences() {
    return Preferences(
      interestedIn: interestedIn.isEmpty ? Gender.values.toSet() : interestedIn,
    );
  }
}

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void update(OnboardingDraft Function(OnboardingDraft current) change) =>
      state = change(state);

  void reset() => state = const OnboardingDraft();
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
      OnboardingController.new,
    );
