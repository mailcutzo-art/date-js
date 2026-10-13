import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/session_providers.dart';
import '../../app/router/app_routes.dart';
import '../../app/shell/root_shell.dart';
import '../../design_system/design_system.dart';

/// Phone number entry. The "Send code" button enables at 10 digits.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  bool get _valid => _controller.text.length == 10;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_valid || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(sessionProvider.notifier)
          .requestOtp('+91${_controller.text}');
      if (mounted) await context.push(AppRoutes.otp);
    } on Object {
      if (mounted) {
        ref
            .read(toastControllerProvider)
            .show(
              'Could not send the code',
              description: 'Check your connection and try again.',
              variant: ToastVariant.destructive,
            );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            SubpageHeader(title: 'Sign in', onBack: context.pop),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SynkText(
                      'What\'s your number?',
                      variant: SynkTextVariant.h1,
                    ),
                    const SizedBox(height: 8),
                    const SynkText(
                      'We\'ll text you a code to confirm it\'s you. '
                      'Message and data rates may apply.',
                      variant: SynkTextVariant.muted,
                    ),
                    const SizedBox(height: 28),
                    SynkTextField(
                      controller: _controller,
                      hint: 'Phone number',
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      maxLength: 10,
                      leading: const Padding(
                        padding: EdgeInsets.only(left: 14, right: 4),
                        child: SynkText('+91', variant: SynkTextVariant.input),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) => _send(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SynkButton(
                label: 'Send code',
                size: SynkButtonSize.lg,
                expand: true,
                loading: _sending,
                onPressed: _valid ? _send : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
