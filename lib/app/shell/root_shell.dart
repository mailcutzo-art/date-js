import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/design_system.dart';

/// App-wide toast queue; the root shell mounts it above every route and dialog.
final toastControllerProvider = Provider<ToastController>((ref) {
  final controller = ToastController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Wraps the navigator: toasts above everything. Session, connectivity and lifecycle hooks
/// belong here as the app grows.
class RootShell extends ConsumerWidget {
  const RootShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ToastHost(
      controller: ref.watch(toastControllerProvider),
      child: child,
    );
  }
}
