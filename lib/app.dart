import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/shell/root_shell.dart';
import 'design_system/design_system.dart';

/// Root widget: theme (follows the system), router and the app-wide shell.
class DateJsApp extends ConsumerWidget {
  const DateJsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'date-js',
      debugShowCheckedModeBanner: false,
      theme: SynkThemeData.light,
      darkTheme: SynkThemeData.dark,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => RootShell(child: child ?? const SizedBox()),
    );
  }
}
