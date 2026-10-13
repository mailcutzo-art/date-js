import 'gender.dart';

/// One photo of a profile. The demo build has no image backend, so a photo is a [seed] that the
/// UI turns into generated artwork (see `PhotoArt`); a real build swaps this for a URL.
class ProfilePhoto {
  const ProfilePhoto({required this.id, required this.seed});

  final String id;
  final int seed;

  @override
  bool operator ==(Object other) =>
      other is ProfilePhoto && other.id == id && other.seed == seed;

  @override
  int get hashCode => Object.hash(id, seed);
}

/// A person shown in discovery, in matches or in chat.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.photos,
    this.bio = '',
    this.city = '',
    this.distanceKm = 0,
    this.interests = const [],
    this.verified = false,
    this.likesYou = false,
    this.job,
  });

  final String id;
  final String name;
  final int age;
  final Gender gender;
  final List<ProfilePhoto> photos;
  final String bio;
  final String city;
  final int distanceKm;
  final List<String> interests;
  final bool verified;

  /// Demo flag: liking this profile creates a match.
  final bool likesYou;
  final String? job;

  Profile copyWith({
    String? name,
    int? age,
    Gender? gender,
    List<ProfilePhoto>? photos,
    String? bio,
    String? city,
    int? distanceKm,
    List<String>? interests,
    bool? verified,
    String? job,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      photos: photos ?? this.photos,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      distanceKm: distanceKm ?? this.distanceKm,
      interests: interests ?? this.interests,
      verified: verified ?? this.verified,
      likesYou: likesYou,
      job: job ?? this.job,
    );
  }
}
