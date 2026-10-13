import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../foundation/contrast.dart';
import '../foundation/hairline.dart';
import '../tokens/synk_motion.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Initial shown by an avatar without a photo (RN `UiAvatar`): the first ASCII letter or digit of
/// the trimmed [name] upper-cased; otherwise its first character (so emoji and non-Latin scripts
/// still show something recognisable); otherwise `?`.
String avatarInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  for (final unit in trimmed.codeUnits) {
    final isDigit = unit >= 0x30 && unit <= 0x39;
    final isUpper = unit >= 0x41 && unit <= 0x5A;
    final isLower = unit >= 0x61 && unit <= 0x7A;
    if (isDigit || isUpper || isLower) {
      return String.fromCharCode(unit).toUpperCase();
    }
  }
  // First user-perceived character (an emoji with modifiers stays whole).
  return trimmed.characters.first.toUpperCase();
}

/// Circular user photo (`UiAvatar`): crops to a circle on the card colour with a 2 px hairline
/// border, cross-fades the photo in over 120 ms and falls back to [InitialsAvatar] when
/// [imageUrl] is blank or the load fails.
///
/// Photos load through `CachedNetworkImage` (so [httpHeaders], e.g. a CDN `Referer`, apply).
/// [imageProvider] bypasses the network and exists so tests can inject pixels or failures.
class SynkAvatar extends StatelessWidget {
  const SynkAvatar({
    required this.name,
    this.imageUrl,
    this.size = 28,
    this.fallbackColor,
    this.httpHeaders,
    this.imageProvider,
    this.semanticLabel,
    super.key,
  });

  final String? imageUrl;
  final String name;
  final double size;

  /// Background of the initials fallback (the member / user colour).
  final Color? fallbackColor;
  final Map<String, String>? httpHeaders;

  /// Test override: used instead of [imageUrl] when set.
  final ImageProvider? imageProvider;

  /// Accessibility label; defaults to [name].
  final String? semanticLabel;

  bool get _hasImage =>
      imageProvider != null ||
      (imageUrl != null && imageUrl!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (!_hasImage) {
      return InitialsAvatar(
        name: name,
        size: size,
        fallbackColor: fallbackColor,
        semanticLabel: semanticLabel,
      );
    }
    final label = semanticLabel ?? name;
    return Semantics(
      image: true,
      label: label.isEmpty ? null : label,
      excludeSemantics: true,
      child: _AvatarPhoto(
        name: name,
        size: size,
        fallbackColor: fallbackColor,
        imageUrl: imageUrl?.trim(),
        httpHeaders: httpHeaders,
        imageProvider: imageProvider,
      ),
    );
  }
}

/// The photo with its card background and hairline border. A failed load swaps in the plain
/// initials circle (without the border), like the Android avatar.
class _AvatarPhoto extends StatefulWidget {
  const _AvatarPhoto({
    required this.name,
    required this.size,
    required this.fallbackColor,
    required this.imageUrl,
    required this.httpHeaders,
    required this.imageProvider,
  });

  final String name;
  final double size;
  final Color? fallbackColor;
  final String? imageUrl;
  final Map<String, String>? httpHeaders;
  final ImageProvider? imageProvider;

  @override
  State<_AvatarPhoto> createState() => _AvatarPhotoState();
}

class _AvatarPhotoState extends State<_AvatarPhoto> {
  bool _failed = false;

  @override
  void didUpdateWidget(_AvatarPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageProvider != widget.imageProvider) {
      _failed = false;
    }
  }

  void _markFailed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_failed) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final fallback = _InitialsFace(
      name: widget.name,
      size: size,
      fallbackColor: widget.fallbackColor,
    );
    if (_failed) return fallback;

    final colors = context.colors;
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : SynkMotion.avatarFade;

    final Widget photo;
    if (widget.imageProvider != null) {
      photo = Image(
        image: widget.imageProvider!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: fade,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          _markFailed();
          return fallback;
        },
      );
    } else {
      photo = CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        httpHeaders: widget.httpHeaders,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: fade,
        fadeOutDuration: fade,
        errorWidget: (context, url, error) {
          _markFailed();
          return fallback;
        },
      );
    }

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.card),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.border, width: hairline2(context)),
          ),
          child: ClipOval(child: photo),
        ),
      ),
    );
  }
}

/// Coloured circle with the name's initial. Text size is `size / 2` and deliberately ignores the
/// system text scale (the circle never grows), weight normal.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.name,
    this.size = 28,
    this.fallbackColor,
    this.semanticLabel,
    super.key,
  });

  final String name;
  final double size;

  /// Circle colour; defaults to `muted`.
  final Color? fallbackColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? name;
    return Semantics(
      image: true,
      label: label.isEmpty ? null : label,
      excludeSemantics: true,
      child: _InitialsFace(
        name: name,
        size: size,
        fallbackColor: fallbackColor,
      ),
    );
  }
}

/// Foreground colour of initials drawn on a custom fallback colour (`0xF2FAFAFA`).
const Color kInitialsOnColor = Color(0xF2FAFAFA);

/// Foreground of initials on a light custom colour (used when [kInitialsOnColor] would not be
/// readable on it).
const Color kInitialsOnLightColor = Color(0xFF0A0A0A);

/// The circle and the initial for an avatar on [picked], a colour the user chose (their member
/// colour): the light initial (Android's `0xF2FAFAFA`) when it reads on it, the dark one when
/// that reads better (the light one is 2:1 on a green or orange circle). When neither reaches
/// 4.5:1 (an indigo or a mid blue sits right between them) the circle is deepened or lightened
/// just enough, so every initial is readable and the colour stays recognisably the user's.
({Color circle, Color initial}) initialsOn(Color picked) {
  const target = 4.6;
  final light = Color.alphaBlend(kInitialsOnColor, picked);
  final lightRatio = contrastBetween(light, picked);
  final darkRatio = contrastBetween(kInitialsOnLightColor, picked);
  if (lightRatio >= target) {
    return (circle: picked, initial: kInitialsOnColor);
  }
  if (darkRatio >= target) {
    return (circle: picked, initial: kInitialsOnLightColor);
  }
  if (lightRatio >= darkRatio) {
    return (
      circle: atLeastContrast(picked, const Color(0xFFFAFAFA), ratio: target),
      initial: kInitialsOnColor,
    );
  }
  return (
    circle: atLeastContrast(picked, kInitialsOnLightColor, ratio: target),
    initial: kInitialsOnLightColor,
  );
}

class _InitialsFace extends StatelessWidget {
  const _InitialsFace({
    required this.name,
    required this.size,
    required this.fallbackColor,
  });

  final String name;
  final double size;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final picked = fallbackColor != null && fallbackColor != colors.muted;
    final face = picked ? initialsOn(fallbackColor!) : null;
    final bg = face?.circle ?? fallbackColor ?? colors.muted;
    final fg = face?.initial ?? colors.foreground;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Center(
          child: MediaQuery.withNoTextScaling(
            child: SynkText(
              avatarInitial(name),
              variant: SynkTextVariant.p,
              color: fg,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: size / 2,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
