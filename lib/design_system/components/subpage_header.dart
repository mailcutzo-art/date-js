import 'package:flutter/material.dart';

import '../foundation/hairline.dart';
import '../icons/synk_icon.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Header of detail / profile screens: a 36dp circular back button (muted fill while pressed),
/// a 17/600 one-line [title] with an optional 12sp muted one-line [subtitle], then the
/// [trailing] widget or a 36dp spacer. A hairline border closes the header.
///
/// [onBack] null hides the back button (its slot stays, so titles line up across screens).
/// The back button is announced as a button named [backLabel]; the title block is a heading.
class SubpageHeader extends StatelessWidget {
  const SubpageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.backLabel = 'Back',
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final String backLabel;
  final Widget? trailing;

  /// Diameter of the back button and of the trailing spacer.
  static const double buttonSize = 36;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border, width: hairline(context)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          spacing: 8,
          children: [
            if (onBack != null)
              _BackButton(onTap: onBack!, label: backLabel)
            else
              const SizedBox.square(dimension: buttonSize),
            Expanded(
              child: Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SynkText(
                      title,
                      variant: SynkTextVariant.buttonLarge,
                      maxLines: 1,
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: SynkText(
                          subtitle!,
                          variant: SynkTextVariant.caption,
                          style: const TextStyle(letterSpacing: 0),
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            trailing ?? const SizedBox.square(dimension: buttonSize),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  const _BackButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: true,
      label: widget.label,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: ExcludeSemantics(
          child: Container(
            width: SubpageHeader.buttonSize,
            height: SubpageHeader.buttonSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _pressed ? colors.muted : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: SynkIcon(
              SynkIcons.back,
              size: 22,
              color: colors.foreground,
              strokeWidth: 2.25,
            ),
          ),
        ),
      ),
    );
  }
}
