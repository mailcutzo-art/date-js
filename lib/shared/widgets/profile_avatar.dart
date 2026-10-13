import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/models/profile.dart';
import 'photo_art.dart';

/// Round avatar made from a profile's first photo (generated artwork in the demo build).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.profile,
    this.size = 48,
    this.ring = false,
    super.key,
  });

  final Profile profile;
  final double size;

  /// Draws a brand-coloured ring, e.g. for a new match.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final seed = profile.photos.isEmpty
        ? profile.name.hashCode
        : profile.photos.first.seed;
    final avatar = ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: PhotoArt(seed: seed),
      ),
    );
    return Semantics(
      label: profile.name,
      image: true,
      child: ExcludeSemantics(
        child: ring
            ? Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 2),
                ),
                child: avatar,
              )
            : avatar,
      ),
    );
  }
}
