import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/hairline.dart';
import '../foundation/tap_target.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

/// Look of a [SynkTextField].
enum SynkInputVariant {
  /// Radius 8, solid input fill, 1dp border that darkens when focused.
  solid,

  /// Radius 14, translucent glass fill with a 2px border.
  glass,
}

/// Text input (the Android `SynklyInput`).
///
/// * [maxLength] truncates input and never shows a counter.
/// * Disabled (`enabled: false`) looks identical to enabled; it only refuses focus.
/// * [errorText] switches the border to the destructive colour and shows the message below;
///   [helperText] shows a muted hint below (the error replaces it).
/// * Multi-line fields grow from [minLines] to [maxLines] and scroll with the caret after that.
class SynkTextField extends StatefulWidget {
  const SynkTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.variant = SynkInputVariant.solid,
    this.leading,
    this.trailing,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final SynkInputVariant variant;
  final Widget? leading;
  final Widget? trailing;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  /// Accessibility label announced before the visible [hint].
  final String? semanticLabel;

  @override
  State<SynkTextField> createState() => _SynkTextFieldState();
}

class _SynkTextFieldState extends State<SynkTextField> {
  FocusNode? _ownedFocusNode;
  bool _focused = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _focused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(SynkTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(_onFocusChanged);
      if (oldWidget.focusNode == null && widget.focusNode != null) {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
      _focusNode.addListener(_onFocusChanged);
      _focused = _focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (focused != _focused && mounted) setState(() => _focused = focused);
  }

  bool get _hasError => (widget.errorText ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glass = widget.variant == SynkInputVariant.glass;
    final radius = glass ? SynkRadius.mdAll : SynkRadius.smAll;

    final textStyle = SynkTypography.of(SynkTextVariant.input)
        .copyWith(color: colors.foreground);
    final hintStyle = textStyle.copyWith(color: colors.mutedForeground);

    final Color borderColor;
    if (_hasError) {
      borderColor = colors.destructive;
    } else if (_focused) {
      borderColor = colors.solidInputFocusedBorder;
    } else {
      borderColor = glass ? colors.glassBorder : Colors.transparent;
    }
    final borderWidth = glass ? hairline2(context) : 1.0;
    final multiline = widget.maxLines != 1 && !widget.obscureText;
    // The field is named by [semanticLabel], else by its placeholder; the drawn placeholder is
    // left out of the semantics (it would repeat the name, and it vanishes with the first
    // typed letter, taking the name with it). A placeholder that says more than the name (an
    // example) is read as the field's hint.
    final label = widget.semanticLabel ?? widget.hint;
    final placeholderHint = widget.hint != null && widget.hint != label
        ? widget.hint
        : null;
    // The field's node spans 48 dp whatever its drawn height (a 46 dp box, a 21 dp line): the
    // layout stays as designed, the node is what TalkBack focuses and Switch Access taps.
    final field = TapTarget(
      container: true,
      properties: SemanticsProperties(
        label: label,
        // The error is also part of the field's own node (besides the live region below, which
        // announces it when it appears), so focusing the field again reads what is wrong.
        hint: _hasError ? widget.errorText : placeholderHint,
        validationResult: _hasError
            ? SemanticsValidationResult.invalid
            : SemanticsValidationResult.none,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          style: textStyle,
          cursorColor: colors.primary,
          cursorWidth: 2,
          keyboardAppearance: colors.brightness,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autocorrect: widget.autocorrect,
          obscureText: widget.obscureText,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.obscureText ? null : widget.minLines,
          maxLength: widget.maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          // The counter is never shown: input is simply truncated.
          buildCounter: (
            context, {
            required int currentLength,
            required bool isFocused,
            required int? maxLength,
          }) => null,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            hint: widget.hint == null
                ? null
                : ExcludeSemantics(
                    // Styled as the field styles its own hint: the Material base under ours.
                    child: Text(
                      widget.hint!,
                      style: Theme.of(context).textTheme.bodyLarge!
                          .merge(hintStyle),
                    ),
                  ),
          ),
        ),
      ),
    );

    final box = Container(
      decoration: BoxDecoration(
        color: glass ? colors.glassOverlay : colors.solidInputBackground,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (widget.leading != null) ...[
            _slot(widget.leading!, multiline),
            const SizedBox(width: 10),
          ],
          Expanded(child: field),
          if (widget.trailing != null) ...[
            const SizedBox(width: 10),
            _slot(widget.trailing!, multiline),
          ],
        ],
      ),
    );

    final tappable = GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: box,
    );

    final error = widget.errorText;
    final helper = widget.helperText;
    final Widget? message = (error != null && error.isNotEmpty)
        ? Semantics(
            liveRegion: true,
            child: SynkText(
              error,
              variant: SynkTextVariant.caption,
              color: colors.destructive,
            ),
          )
        : (helper != null && helper.isNotEmpty)
        ? SynkText(helper, variant: SynkTextVariant.listDescription)
        : null;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        tappable,
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
            child: message,
          ),
      ],
    );

    return column;
  }

  /// Aligns a slot with the first text line of a multi-line field.
  Widget _slot(Widget slot, bool multiline) {
    if (!multiline) return slot;
    return Padding(padding: const EdgeInsets.only(top: 12), child: slot);
  }
}
