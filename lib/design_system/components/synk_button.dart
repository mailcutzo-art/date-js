import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/tap_target.dart';
import '../icons/synk_icon.dart';
import '../tokens/synk_colors.dart';
import '../tokens/synk_palette.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';

/// Visual variants of [SynkButton] (the six Android variants plus the pill `ink` / `soft`
/// variants of the refreshed UI).
enum SynkButtonVariant {
  primary,
  destructive,
  secondary,
  outline,
  ghost,
  glass,

  /// Near-black full pill with light text (the reference's black button).
  ink,

  /// Muted / pastel full pill with foreground text.
  soft,
}

/// Height and horizontal padding presets: md 44/20, sm 36/14, lg 50/24, icon 40x40 circle.
enum SynkButtonSize {
  sm(height: 36, horizontalPadding: 14),
  md(height: 44, horizontalPadding: 20),
  lg(height: 50, horizontalPadding: 24),
  icon(height: 40, horizontalPadding: 0);

  const SynkButtonSize({required this.height, required this.horizontalPadding});

  final double height;
  final double horizontalPadding;
}

/// Fill of the quiet "soft" surfaces (the `soft` button, unselected pill tabs): `muted` with a
/// touch of the foreground so the shape stays visible on the page background, where plain
/// `muted` (0xFFF5F5F5 on 0xFFFAFAFA) nearly disappears.
Color synkSoftFill(SynkColors c) =>
    Color.alphaBlend(c.foreground.withValues(alpha: 0.04), c.muted);

/// Resolved colours of a [SynkButtonVariant] (fill, content, border, ripple and spinner).
@immutable
class SynkButtonColors {
  const SynkButtonColors({
    required this.background,
    required this.foreground,
    required this.ripple,
    required this.spinner,
    this.border,
  });

  /// Fill colour, `null` for transparent variants.
  final Color? background;
  final Color foreground;

  /// Border colour (outline only), `null` for no border.
  final Color? border;
  final Color ripple;
  final Color spinner;

  static const Color _white22 = Color(0x38FFFFFF);
  static const Color _white15 = Color(0x26FFFFFF);

  static SynkButtonColors resolve(SynkColors c, SynkButtonVariant variant) {
    final primaryRipple = c.primary.withValues(alpha: 0.20);
    // The dark primary (0xFFA3004C) is nearly invisible as a thin spinner on a dark surface.
    final accentSpinner = c.isDark ? SynkPalette.brandPink : c.primary;
    return switch (variant) {
      SynkButtonVariant.primary => SynkButtonColors(
        background: c.primary,
        foreground: c.primaryForeground,
        ripple: _white22,
        spinner: c.primaryForeground,
      ),
      SynkButtonVariant.destructive => SynkButtonColors(
        background: c.destructive,
        foreground: c.primaryForeground,
        ripple: _white22,
        spinner: c.primaryForeground,
      ),
      SynkButtonVariant.secondary => SynkButtonColors(
        background: c.secondary,
        foreground: c.secondaryForeground,
        ripple: primaryRipple,
        spinner: accentSpinner,
      ),
      SynkButtonVariant.outline => SynkButtonColors(
        background: null,
        border: c.border,
        foreground: c.foreground,
        ripple: primaryRipple,
        spinner: accentSpinner,
      ),
      SynkButtonVariant.ghost => SynkButtonColors(
        background: null,
        foreground: c.foreground,
        ripple: primaryRipple,
        spinner: accentSpinner,
      ),
      SynkButtonVariant.glass => SynkButtonColors(
        background: c.glassOverlay,
        foreground: c.foreground,
        ripple: _white15,
        spinner: c.foreground,
      ),
      SynkButtonVariant.ink => SynkButtonColors(
        background: c.ink,
        foreground: c.inkForeground,
        ripple: c.inkForeground.withValues(alpha: 0.18),
        spinner: c.inkForeground,
      ),
      SynkButtonVariant.soft => SynkButtonColors(
        background: synkSoftFill(c),
        foreground: c.foreground,
        ripple: primaryRipple,
        spinner: accentSpinner,
      ),
    };
  }
}

/// A button. Pass a [label] (optionally with a [leadingIcon]) or a custom [child].
///
/// Disabled (`onPressed == null`) and [loading] buttons are drawn at 50 % opacity and ignore
/// taps; while loading the content stays laid out (so the width does not jump) but is hidden
/// behind a 20dp spinner. [semanticLabel] replaces [label] for accessibility.
///
/// With [expand] the button fills the available width, so it needs a bounded-width parent.
class SynkButton extends StatelessWidget {
  const SynkButton({
    super.key,
    this.label,
    this.child,
    this.leadingIcon,
    this.variant = SynkButtonVariant.primary,
    this.size = SynkButtonSize.md,
    this.onPressed,
    this.loading = false,
    this.expand = false,
    this.contentColor,
    this.semanticLabel,
  }) : assert(
         label != null || child != null || leadingIcon != null,
         'SynkButton needs a label, a child or a leadingIcon',
       ),
       assert(
         label != null || child != null || semanticLabel != null,
         'An icon-only SynkButton needs a semanticLabel',
       );

  final String? label;

  /// Custom content; wins over [label] when both are given.
  final Widget? child;
  final SynkIcons? leadingIcon;
  final SynkButtonVariant variant;
  final SynkButtonSize size;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  /// Overrides the colour of the label, the icon and a custom [child].
  final Color? contentColor;
  final String? semanticLabel;

  bool get _isCircle => size == SynkButtonSize.icon;

  /// One shape for every button of the app: a full pill, or a circle for icon buttons. (The
  /// variants only differ in colour; mixing 14 dp corners with pills made neighbouring buttons
  /// look unrelated.)
  static OutlinedBorder shapeFor(SynkButtonVariant variant, bool circle) =>
      circle ? const CircleBorder() : const StadiumBorder();

  TextStyle _textStyle() => SynkTypography.of(switch (size) {
    SynkButtonSize.sm => SynkTextVariant.buttonSmall,
    SynkButtonSize.lg => SynkTextVariant.buttonLarge,
    SynkButtonSize.md || SynkButtonSize.icon => SynkTextVariant.buttonDefault,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SynkButtonColors.resolve(context.colors, variant);
    final fg = contentColor ?? palette.foreground;
    final text = label;
    final iconOnly = leadingIcon != null && text == null && child == null;

    final Widget body;
    if (child != null) {
      body = child!;
    } else {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null)
            SynkIcon(
              leadingIcon!,
              size: iconOnly ? SynkIconSize.base : SynkIconSize.md,
              color: fg,
            ),
          if (leadingIcon != null && text != null) const SizedBox(width: 8),
          if (text != null)
            Flexible(
              child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      );
    }

    // A loose `Flexible` inside a `mainAxisSize.min` Row lets the label ellipsize when the
    // width is bounded and simply hug the text when it is not (plain Row, horizontal list).
    final content = DefaultTextStyle(
      style: _textStyle().copyWith(color: fg),
      textAlign: TextAlign.center,
      child: IconTheme(
        data: IconThemeData(color: fg, size: SynkIconSize.md),
        child: body,
      ),
    );

    return SynkButtonChrome(
      variant: variant,
      shape: shapeFor(variant, _isCircle),
      constraints: _isCircle
          ? BoxConstraints.tightFor(width: size.height, height: size.height)
          : BoxConstraints(
              minHeight: size.height,
              minWidth: expand ? double.infinity : 0,
            ),
      padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
      onPressed: onPressed,
      loading: loading,
      semanticLabel: semanticLabel ?? label,
      child: content,
    );
  }
}

/// Shared chrome of the button family ([SynkButton], `SynkIconButton`, `CircleIconButton`):
/// fill, border, shape clip, ink ripple, 50 % dimming when disabled or loading, the spinner
/// overlay and the button semantics.
///
/// Internal building block: screens should use the concrete buttons.
class SynkButtonChrome extends StatelessWidget {
  const SynkButtonChrome({
    super.key,
    required this.variant,
    required this.shape,
    required this.child,
    required this.onPressed,
    this.loading = false,
    this.semanticLabel,
    this.constraints = const BoxConstraints(),
    this.padding = EdgeInsets.zero,
    this.spinnerSize = 20,
  });

  final SynkButtonVariant variant;
  final OutlinedBorder shape;
  final Widget child;
  final VoidCallback? onPressed;
  final bool loading;

  /// Accessibility label. When non-null the [child]'s own semantics are dropped.
  final String? semanticLabel;
  final BoxConstraints constraints;
  final EdgeInsetsGeometry padding;
  final double spinnerSize;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final palette = SynkButtonColors.resolve(context.colors, variant);
    final border = palette.border;
    final surfaceShape = border == null
        ? shape
        : shape.copyWith(side: BorderSide(color: border));

    final hidden = ExcludeSemantics(
      excluding: semanticLabel != null,
      child: Opacity(opacity: loading ? 0 : 1, child: child),
    );
    final Widget content = Stack(
      alignment: Alignment.center,
      children: [
        hidden,
        if (loading)
          ExcludeSemantics(
            child: SynkButtonSpinner(size: spinnerSize, color: palette.spinner),
          ),
      ],
    );

    // A 36 / 40 / 44 dp button keeps its size and look; its semantics and touch area span 48 dp.
    return TapTarget(
      container: true,
      properties: SemanticsProperties(
        button: true,
        enabled: _enabled,
        label: semanticLabel,
        onTap: _enabled ? onPressed : null,
      ),
      child: Opacity(
        opacity: _enabled ? 1 : 0.5,
        child: Material(
          color: palette.background ?? Colors.transparent,
          shape: surfaceShape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            customBorder: surfaceShape,
            splashColor: palette.ripple,
            highlightColor: Colors.transparent,
            hoverColor: palette.ripple.withValues(alpha: 0.08),
            focusColor: palette.ripple.withValues(alpha: 0.12),
            excludeFromSemantics: true,
            child: ConstrainedBox(
              constraints: constraints,
              child: Padding(
                padding: padding,
                child: Align(widthFactor: 1, heightFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 2dp round-cap indeterminate arc (the Android spinner) used inside the buttons.
///
/// Honours the platform "remove animations" setting by drawing a still arc.
class SynkButtonSpinner extends StatefulWidget {
  const SynkButtonSpinner({super.key, this.size = 20, required this.color});

  final double size;
  final Color color;

  @override
  State<SynkButtonSpinner> createState() => _SynkButtonSpinnerState();
}

class _SynkButtonSpinnerState extends State<SynkButtonSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.38;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _SpinnerPainter(_controller, widget.color),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.progress, this.color) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  static const double _stroke = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    // Two turns per cycle keep the loop seamless; the arc breathes between 27 and 270 degrees.
    final start = -math.pi / 2 + 4 * math.pi * t;
    final sweep =
        math.pi * 0.15 +
        math.pi * 1.35 * (0.5 - 0.5 * math.cos(2 * math.pi * t));
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(_stroke / 2),
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.color != color || old.progress != progress;
}
