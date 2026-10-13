import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/session_providers.dart';
import '../../app/shell/root_shell.dart';
import '../../design_system/design_system.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../shared/widgets/otp_field.dart';

/// Six-digit code entry with a resend countdown. A wrong code shakes the boxes.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({this.resendAfter = 30, super.key});

  final int resendAfter;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpKey = GlobalKey<State<OtpField>>();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  Timer? _ticker;
  late int _left = widget.resendAfter;
  bool _verifying = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _shake.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _ticker?.cancel();
    setState(() => _left = widget.resendAfter);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left = math.max(0, _left - 1));
      if (_left == 0) t.cancel();
    });
  }

  Future<void> _verify(String code) async {
    setState(() {
      _verifying = true;
      _error = false;
    });
    final ok = await ref.read(sessionProvider.notifier).verifyOtp(code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (!ok) {
      setState(() => _error = true);
      SynkHapticsScope.of(context).play(SynkHaptic.warning);
      unawaited(_shake.forward(from: 0));
    }
    // On success the session moves to onboarding and the router takes over.
  }

  Future<void> _resend() async {
    await ref
        .read(sessionProvider.notifier)
        .requestOtp(ref.read(sessionProvider).phone);
    if (!mounted) return;
    _startCountdown();
    ref.read(toastControllerProvider).show('Code sent');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final phone = ref.watch(sessionProvider).phone;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            SubpageHeader(title: 'Verify', onBack: context.pop),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SynkText(
                      'Enter the code',
                      variant: SynkTextVariant.h1,
                    ),
                    const SizedBox(height: 8),
                    SynkText(
                      'We sent a 6-digit code to $phone.',
                      variant: SynkTextVariant.muted,
                    ),
                    const SizedBox(height: 28),
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(
                          math.sin(_shake.value * math.pi * 6) *
                              10 *
                              (1 - _shake.value),
                          0,
                        ),
                        child: child,
                      ),
                      child: OtpField(
                        key: _otpKey,
                        hasError: _error,
                        onChanged: (_) {
                          if (_error) setState(() => _error = false);
                        },
                        onCompleted: _verify,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_error)
                      SynkText(
                        'That code is not right. Try again.',
                        variant: SynkTextVariant.small,
                        color: colors.destructive,
                      ),
                    if (_verifying)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: SynkSpinner(),
                      ),
                    const SizedBox(height: 24),
                    Center(
                      child: _left > 0
                          ? SynkText(
                              'Resend code in ${_left}s',
                              variant: SynkTextVariant.muted,
                            )
                          : SynkButton(
                              label: 'Resend code',
                              variant: SynkButtonVariant.ghost,
                              onPressed: _resend,
                            ),
                    ),
                    const SizedBox(height: 32),
                    const SynkBadge(
                      text: 'Demo build: use code $kDemoOtp',
                      variant: SynkBadgeVariant.amber,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
