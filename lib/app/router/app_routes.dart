/// Route paths, kept in one place so screens never build path strings by hand.
abstract final class AppRoutes {
  // Signed out
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';
  static const String otp = '/otp';

  // Signed in, profile not finished
  static const String setup = '/setup';

  // Main tabs
  static const String discover = '/discover';
  static const String matches = '/matches';
  static const String chats = '/chats';
  static const String me = '/me';

  // Pushed on top of the tabs
  static String chat(String id) => '/chats/$id';
  static const String chatPattern = '/chats/:id';
  static String profile(String id) => '/profile/$id';
  static const String profilePattern = '/profile/:id';
  static const String editProfile = '/me/edit';
  static const String settings = '/me/settings';
  static const String privacy = '/me/privacy';
  static const String notifications = '/me/notifications';
  static const String premium = '/premium';
}
