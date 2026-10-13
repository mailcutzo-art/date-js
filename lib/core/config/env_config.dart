import 'package:flutter/foundation.dart';

enum AppEnvironment {
  development,
  production;

  static AppEnvironment fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'production':
      case 'prod':
      case 'release':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }
}

/// Immutable build configuration, overridden at build time with `--dart-define`:
///
/// | define         | purpose                                      |
/// |----------------|----------------------------------------------|
/// | `APP_ENV`      | `production` / `development`                 |
/// | `API_BASE_URL` | REST base URL (empty until a backend exists) |
class EnvConfig {
  const EnvConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableVerboseLogging,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableVerboseLogging;

  bool get isProduction => environment == AppEnvironment.production;

  /// Builds configuration from compile-time `--dart-define` flags.
  factory EnvConfig.fromEnvironment() {
    const rawEnv = String.fromEnvironment('APP_ENV');
    final environment = rawEnv.isEmpty
        ? (kReleaseMode
              ? AppEnvironment.production
              : AppEnvironment.development)
        : AppEnvironment.fromString(rawEnv);
    return EnvConfig(
      environment: environment,
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL').trim(),
      enableVerboseLogging: kDebugMode,
    );
  }

  static EnvConfig _current = EnvConfig.fromEnvironment();
  static EnvConfig get current => _current;

  @visibleForTesting
  static void setForTesting(EnvConfig config) {
    _current = config;
  }

  @visibleForTesting
  static void resetForTesting() {
    _current = EnvConfig.fromEnvironment();
  }
}
