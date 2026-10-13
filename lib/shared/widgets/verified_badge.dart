import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Small blue tick shown next to the name of a selfie-verified profile.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({this.size = 18, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Verified profile',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: SynkPalette.indigo,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SynkIcon(
          SynkIcons.check,
          size: size * 0.62,
          color: Colors.white,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}
