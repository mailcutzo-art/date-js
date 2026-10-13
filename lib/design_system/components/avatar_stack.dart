import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_avatar.dart';
import 'synk_text.dart';

/// One face of an [AvatarStack].
@immutable
class AvatarStackItem {
  const AvatarStackItem({
    required this.name,
    this.imageUrl,
    this.color,
    this.ringed = false,
    this.ringColor,
    this.httpHeaders,
    this.imageProvider,
  });

  final String name;
  final String? imageUrl;

  /// Background of the initials fallback (the member colour).
  final Color? color;

  /// Draws a ring around the face (e.g. the member is speaking).
  final bool ringed;

  /// Ring colour; defaults to `primary`.
  final Color? ringColor;
  final Map<String, String>? httpHeaders;

  /// Test override for the photo (see `SynkAvatar.imageProvider`).
  final ImageProvider? imageProvider;
}

/// Overlapping circular avatars with a card-coloured separator ring and an overflow chip.
///
/// The first item is frontmost. Items past [maxVisible] collapse into a `+N` chip.
/// With no items and [showPlaceholders] it draws three muted placeholders at 35 % alpha
/// ("nobody online").
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    required this.items,
    this.maxVisible = 3,
    this.size = 24,
    this.overlap = 8,
    this.showPlaceholders = false,
    this.borderColor,
    this.semanticLabel,
    super.key,
  }) : assert(maxVisible >= 0, 'maxVisible must not be negative');

  final List<AvatarStackItem> items;
  final int maxVisible;

  /// Outer diameter of each circle, separator ring included.
  final double size;

  /// How far each circle tucks under its predecessor.
  final double overlap;
  final bool showPlaceholders;

  /// Separator ring colour; defaults to the card colour.
  final Color? borderColor;

  /// Defaults to a summary of the names ("3 people: Ada, Bo, Cy").
  final String? semanticLabel;

  /// Width of the separator ring.
  static const double ringWidth = 2;

  /// Number of placeholders drawn when nobody is there.
  static const int placeholderCount = 3;

  /// Items that fit before the `+N` chip.
  int get visibleCount => math.min(items.length, maxVisible);

  /// The `N` of the overflow chip (0 when everything fits).
  int get overflowCount => math.max(0, items.length - maxVisible);

  /// Distance between the left edges of two neighbouring circles.
  double get step => math.max(1, size - overlap);

  /// Width of the overflow chip. Its first [overlap] pixels hide under the last face, so the
  /// text is centred in the rest; the chip is never narrower than a circle.
  double get chipWidth {
    final glyphs = '+$overflowCount'.length;
    final glyphWidth = glyphs * _chipFontSize * 0.62;
    return math.max(size, overlap + glyphWidth + ringWidth * 2 + 4);
  }

  double get _chipFontSize => math.max(9, size * 0.4);

  /// Total width of the laid-out stack.
  double get totalWidth {
    if (items.isEmpty) {
      return showPlaceholders ? step * (placeholderCount - 1) + size : 0;
    }
    final avatars = visibleCount;
    if (overflowCount > 0) return avatars * step + chipWidth;
    return (avatars - 1) * step + size;
  }

  String _label() {
    if (semanticLabel != null) return semanticLabel!;
    if (items.isEmpty) return showPlaceholders ? 'Nobody here' : '';
    final names = items
        .map((e) => e.name.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');
    final count = items.length;
    final head = '$count ${count == 1 ? 'person' : 'people'}';
    return names.isEmpty ? head : '$head: $names';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final separator = borderColor ?? colors.card;
    final children = <Widget>[];

    if (items.isEmpty) {
      if (showPlaceholders) {
        // One shared 35 % layer, so where the circles overlap there is no darker lens.
        children.add(
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = placeholderCount - 1; i >= 0; i--)
                    Positioned(
                      left: i * step,
                      top: 0,
                      child: _Ring(
                        size: size,
                        ring: separator,
                        child: _PlaceholderFace(size: size - ringWidth * 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      if (overflowCount > 0) {
        children.add(
          Positioned(
            left: visibleCount * step,
            top: 0,
            child: _OverflowChip(
              label: '+$overflowCount',
              size: size,
              width: chipWidth,
              fontSize: _chipFontSize,
              hidden: overlap,
              ring: separator,
            ),
          ),
        );
      }
      // Later items first so that the first item ends up on top.
      for (var i = visibleCount - 1; i >= 0; i--) {
        final item = items[i];
        children.add(
          Positioned(
            left: i * step,
            top: 0,
            child: _StackFace(item: item, size: size, separator: separator),
          ),
        );
      }
    }

    final label = _label();
    return Semantics(
      container: true,
      label: label.isEmpty ? null : label,
      excludeSemantics: true,
      child: SizedBox(
        width: totalWidth,
        height: size,
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.ring, required this.child});

  final double size;
  final Color ring;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: AvatarStack.ringWidth),
      ),
      child: child,
    );
  }
}

class _StackFace extends StatelessWidget {
  const _StackFace({
    required this.item,
    required this.size,
    required this.separator,
  });

  final AvatarStackItem item;
  final double size;
  final Color separator;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const ring = AvatarStack.ringWidth;
    if (item.ringed) {
      // Primary ring, a 1 px card gap, then the face.
      const gap = 1.0;
      final face = size - (ring + gap) * 2;
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: separator,
          border: Border.all(
            color: item.ringColor ?? colors.primary,
            width: ring,
          ),
        ),
        child: _face(face),
      );
    }
    return _Ring(size: size, ring: separator, child: _face(size - ring * 2));
  }

  Widget _face(double dimension) => SynkAvatar(
    name: item.name,
    imageUrl: item.imageUrl,
    size: dimension,
    fallbackColor: item.color,
    httpHeaders: item.httpHeaders,
    imageProvider: item.imageProvider,
  );
}

class _PlaceholderFace extends StatelessWidget {
  const _PlaceholderFace({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.mutedForeground,
        ),
      ),
    );
  }
}

class _OverflowChip extends StatelessWidget {
  const _OverflowChip({
    required this.label,
    required this.size,
    required this.width,
    required this.fontSize,
    required this.hidden,
    required this.ring,
  });

  final String label;
  final double size;
  final double width;
  final double fontSize;

  /// Width tucked under the previous face.
  final double hidden;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: width,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: BorderRadius.circular(size),
          border: Border.all(color: ring, width: AvatarStack.ringWidth),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: hidden),
          child: Center(
            child: MediaQuery.withNoTextScaling(
              child: SynkText(
                label,
                variant: SynkTextVariant.badge,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
