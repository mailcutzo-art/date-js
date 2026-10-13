/// Phone sign-in. The demo implementation accepts [kDemoOtp]; a real one talks to the backend.
abstract interface class AuthRepository {
  Future<void> requestOtp(String phone);

  /// True when [code] is valid for [phone].
  Future<bool> verifyOtp(String phone, String code);
}

const String kDemoOtp = '123456';
