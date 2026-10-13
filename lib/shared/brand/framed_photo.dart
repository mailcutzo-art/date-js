import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../widgets/photo_art.dart';

/// A photo in a thick cream frame with an optional name tag in the bottom-left corner
/// ("Michelle, 28"), the brand's polaroid-like card.
class FramedPhoto extends StatelessWidget {
  const FramedPhoto({
    this.seed,
    this.photo,
    this.label,
    this.frame = 5,
    this.radius = 16,
    this.frameColor = SynkPalette.cream,
    super.key,
  }) : assert(
         seed != null || photo != null,
         'FramedPhoto needs a seed or a photo',
       );

  /// Generated [PhotoArt] seed; ignored when [photo] is given.
  final int? seed;
  final Widget? photo;
  final String? label;
  final double frame;
  final double radius;
  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    final inner = radius - frame * 0.6;
    final text = label;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(frame),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(inner),
          child: Stack(
            fit: StackFit.expand,
            children: [
              photo ?? PhotoArt(seed: seed!),
              if (text != null)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: frameColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(inner),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 5, 10, 2),
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SynkTypography.of(SynkTextVariant.badge)
                            .copyWith(color: SynkPalette.nightInk),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
