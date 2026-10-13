import 'gender.dart';

/// Who the user wants to see, edited in onboarding and in the discovery filters.
class Preferences {
  const Preferences({
    this.interestedIn = const {Gender.woman, Gender.man, Gender.nonBinary},
    this.minAge = 21,
    this.maxAge = 40,
    this.maxDistanceKm = 50,
    this.verifiedOnly = false,
  });

  final Set<Gender> interestedIn;
  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final bool verifiedOnly;

  Preferences copyWith({
    Set<Gender>? interestedIn,
    int? minAge,
    int? maxAge,
    int? maxDistanceKm,
    bool? verifiedOnly,
  }) {
    return Preferences(
      interestedIn: interestedIn ?? this.interestedIn,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }
}
