import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../core/config/app_info.dart';
import '../../design_system/design_system.dart';

/// Brand splash: the logo pops in, the name and tagline fade up, then it hands over to the
/// welcome screen (the router sends signed-in users straight to discovery instead).
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    this.hold = const Duration(milliseconds: 1500),
    super.key,
  });

  final Duration hold;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.hold, () {
      if (mounted) context.go(AppRoutes.welcome);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logo = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
    );
    final text = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.45, 1, curve: Curves.easeOut),
    );
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: DotGridBackground()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: logo,
                  child: DotLogo(
                    text: kAppName,
                    color: colors.foreground,
                    semanticLabel: kAppName,
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: text,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(text),
                    child: const SynkText(
                      kAppTagline,
                      variant: SynkTextVariant.lead,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
