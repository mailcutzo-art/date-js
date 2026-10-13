import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'core/utils/app_logger.dart';

/// Installs the global error hooks, locks the orientation, then runs the app inside a
/// [ProviderScope] container. Crash reporting, session restore and push hook in here later.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLogger.error(
      'Uncaught Flutter Framework Error [type: ${details.exception.runtimeType}]',
      tag: 'Bootstrap',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      'Uncaught Asynchronous Error [type: ${error.runtimeType}]',
      tag: 'Bootstrap',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  AppLogger.info(
    'Starting [Env: ${EnvConfig.current.environment.name}]',
    tag: 'Bootstrap',
  );

  final container = ProviderContainer();
  runApp(
    UncontrolledProviderScope(container: container, child: await builder()),
  );
}
