import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_bottom_sheet.dart';
import 'synk_button.dart' show SynkButtonSpinner;
import 'synk_text.dart';

/// Asks the user to confirm an action in a bottom sheet (spec 3.5: "Leave group?", "Remove
/// member?", ...). Completes with `true` when confirmed and `false` when dismissed.
///
/// With [onConfirm] the confirm button shows a spinner while the action runs and the sheet
/// stays open (it cannot be dismissed meanwhile) until the action completes. If the action
/// throws, the error is reported, the button returns to normal and the sheet stays open.
/// Without [onConfirm] the sheet closes as soon as the user confirms.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String cancelLabel,
  required String confirmLabel,
  bool destructive = true,
  Future<void> Function()? onConfirm,
}) async {
  final busy = _BusyProbe();
  final confirmed = await showSynkBottomSheet<bool>(
    context,
    semanticLabel: title,
    canDismiss: () => !busy.isBusy,
    builder: (context) => _ConfirmSheetBody(
      probe: busy,
      title: title,
      description: description,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      destructive: destructive,
      onConfirm: onConfirm,
    ),
  );
  return confirmed ?? false;
}

/// Lets `canDismiss` (outside the sheet) ask the sheet body whether it is busy.
class _BusyProbe {
  bool Function()? _isBusy;

  bool get isBusy => _isBusy?.call() ?? false;
}

class _ConfirmSheetBody extends StatefulWidget {
  const _ConfirmSheetBody({
    required this.probe,
    required this.title,
    required this.description,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.destructive,
    required this.onConfirm,
  });

  final _BusyProbe probe;
  final String title;
  final String description;
  final String cancelLabel;
  final String confirmLabel;
  final bool destructive;
  final Future<void> Function()? onConfirm;

  @override
  State<_ConfirmSheetBody> createState() => _ConfirmSheetBodyState();
}

class _ConfirmSheetBodyState extends State<_ConfirmSheetBody> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.probe._isBusy = () => _busy;
  }

  @override
  void dispose() {
    widget.probe._isBusy = null;
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final action = widget.onConfirm;
    if (action == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'synkly design system',
          context: ErrorDescription('while running a confirm sheet action'),
        ),
      );
      if (mounted) setState(() => _busy = false);
      return;
    }
    // Stay busy after success: the sheet is closing and must not take another tap.
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmSheetContent(
      title: widget.title,
      description: widget.description,
      cancelLabel: widget.cancelLabel,
      confirmLabel: widget.confirmLabel,
      destructive: widget.destructive,
      busy: _busy,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: _confirm,
    );
  }
}

/// The body of a confirm sheet: title, description and an outline cancel button next to a
/// destructive (or primary) confirm button. While [busy] the confirm button shows a spinner
/// and both buttons ignore taps.
///
/// At large text scales the buttons stack instead of squeezing their labels.
class ConfirmSheetContent extends StatelessWidget {
  const ConfirmSheetContent({
    required this.title,
    required this.description,
    required this.cancelLabel,
    required this.confirmLabel,
    this.destructive = true,
    this.busy = false,
    this.onCancel,
    this.onConfirm,
    super.key,
  });

  final String title;
  final String description;
  final String cancelLabel;
  final String confirmLabel;
  final bool destructive;
  final bool busy;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  /// Text scale from which the two buttons no longer fit side by side.
  static const double _stackFromScale = 1.15;

  @override
  Widget build(BuildContext context) {
    final stacked =
        MediaQuery.textScalerOf(context).scale(15) / 15 >= _stackFromScale;
    final cancel = _OverlayButton(
      label: cancelLabel,
      style: _OverlayButtonStyle.outline,
      onPressed: busy ? null : onCancel,
    );
    final confirm = _OverlayButton(
      label: confirmLabel,
      style: destructive
          ? _OverlayButtonStyle.destructive
          : _OverlayButtonStyle.filled,
      onPressed: busy ? null : onConfirm,
      loading: busy,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          children: [SheetTitle(title), SheetDescription(description)],
        ),
        if (stacked)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [confirm, const SizedBox(height: 10), cancel],
            ),
          )
        else
          SheetFooter(
            children: [
              Expanded(child: cancel),
              Expanded(child: confirm),
            ],
          ),
      ],
    );
  }
}

enum _OverlayButtonStyle { filled, destructive, outline }

/// 44 dp pill button used by the overlay footers (this design-system file must not depend on
/// `SynkButton`). Disabled and loading buttons are drawn at 50 % and ignore input.
class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.label,
    required this.style,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final _OverlayButtonStyle style;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground, ripple, borderColor) = switch (style) {
      _OverlayButtonStyle.filled => (
        colors.primary,
        colors.primaryForeground,
        const Color(0x38FFFFFF),
        null,
      ),
      _OverlayButtonStyle.destructive => (
        colors.destructive,
        // The light destructive red of the dark theme needs dark text for contrast.
        colors.isDark ? colors.inkForeground : const Color(0xFFFFFFFF),
        colors.isDark ? const Color(0x290A0A0A) : const Color(0x38FFFFFF),
        null,
      ),
      _OverlayButtonStyle.outline => (
        Colors.transparent,
        colors.foreground,
        colors.primary.withValues(alpha: 0.20),
        colors.border,
      ),
    };
    final enabled = onPressed != null && !loading;
    final shape = StadiumBorder(
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor),
    );
    final textStyle = SynkTypography.of(SynkTextVariant.buttonDefault);
    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? '$label, loading' : label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null || loading ? 0.5 : 1,
        child: Material(
          color: background,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            customBorder: shape,
            splashColor: ripple,
            highlightColor: ripple,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  widthFactor: 1,
                  child: loading
                      ? SizedBox.square(
                          dimension: 20,
                          // Still with "remove animations" on, like every spinner of the app.
                          child: MediaQuery.disableAnimationsOf(context)
                              ? SynkButtonSpinner(size: 20, color: foreground)
                              : CircularProgressIndicator(
                                  strokeWidth: 2,
                                  strokeCap: StrokeCap.round,
                                  color: foreground,
                                  backgroundColor: Colors.transparent,
                                ),
                        )
                      : SynkText(
                          label,
                          color: foreground,
                          style: textStyle,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
