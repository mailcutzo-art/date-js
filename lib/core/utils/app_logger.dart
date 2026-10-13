import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../config/env_config.dart';

/// Where warnings and errors go besides the console (crash reporting); set once at start-up.
abstract interface class LogSink {
  void warning(String message, {String? tag, Object? error});

  void breadcrumb(String category, String message, {Map<String, Object?> data});

  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  });
}

/// Centralized logger.
/// Restricts verbose/debug output to debug sessions.
/// Strictly forwards only the error class type name to developer.log to avoid
/// leaking sensitive exception contents or raw error objects.
abstract final class AppLogger {
  /// Receives every warning and error (the crash reporter in release builds).
  static LogSink? sink;

  static void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode || !EnvConfig.current.enableVerboseLogging) return;
    _log('DEBUG', message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag);
  }

  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('WARN', message, tag: tag, error: error, stackTrace: stackTrace);
    sink?.warning(message, tag: tag, error: error);
  }

  /// [report] false keeps an error out of the crash reporter (the uncaught-error hooks, which
  /// the reporter's own integrations already capture, would otherwise be sent twice).
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    bool report = true,
  }) {
    _log('ERROR', message, tag: tag, error: error, stackTrace: stackTrace);
    if (report) {
      sink?.error(message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }

  static void _log(
    String level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logTag = tag != null ? 'DateJs[$tag]' : 'DateJs';
    // Pass only the error type name to developer.log, never raw error instances
    final errorTypeOnly = error?.runtimeType.toString();

    developer.log(
      '[$level] $message',
      name: logTag,
      error: errorTypeOnly,
      stackTrace: stackTrace,
      level: _levelToInt(level),
    );
  }

  static int _levelToInt(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 700;
    }
  }
}
