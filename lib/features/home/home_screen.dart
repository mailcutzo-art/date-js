import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell/root_shell.dart';
import '../../design_system/design_system.dart';

/// Placeholder landing screen that exercises the design system (theme, text, button, toast).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SynkText('date-js', variant: SynkTextVariant.h1),
              const SizedBox(height: 8),
              const SynkText(
                'The app shell is ready. Build your first screen here.',
                variant: SynkTextVariant.muted,
              ),
              const SizedBox(height: 24),
              SynkButton(
                label: 'Say hello',
                expand: true,
                onPressed: () => ref
                    .read(toastControllerProvider)
                    .show('Hello from date-js'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
