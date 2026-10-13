/// Bundled illustrations carried over from the previous app (transparent WebPs that sit on a
/// coloured hero).
abstract final class SynkImages {
  /// Sign-in: two friends back to back watching on their phones.
  static const String welcome = 'assets/images/img_welcome.webp';

  /// Onboarding step 1: name, photo and birthday.
  static const String profileSetup = 'assets/images/img_profile_setup.webp';

  /// Onboarding step 2: colour.
  static const String colorSelection = 'assets/images/img_color_selection.webp';

  /// Onboarding step 3: the Pro plan.
  static const String planSelection = 'assets/images/img_plan_selection.webp';

  /// The YouTube mark of the YouTube tab.
  static const String youtubeLogo = 'assets/images/img_youtube_logo.webp';

  /// Onboarding heroes by step (profile, colour, plan).
  static const List<String> onboardingHeroes = [
    profileSetup,
    colorSelection,
    planSelection,
  ];
}
