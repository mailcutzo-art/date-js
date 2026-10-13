import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';

/// Six-box one-time-code input backed by a single hidden text field, so paste, autofill and
/// the keyboard all work. [onCompleted] fires once all [length] digits are in.
class OtpField extends StatefulWidget {
  const OtpField({
    required this.onCompleted,
    this.length = 6,
    this.hasError = false,
    this.onChanged,
    super.key,
  });

  final int length;
  final bool hasError;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String value) {
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted(value);
  }

  /// Clears the boxes and refocuses, e.g. after a wrong code.
  void clear() {
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final code = _controller.text;
    return Semantics(
      label: 'Verification code, ${code.length} of ${widget.length} digits',
      textField: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focus.requestFocus,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < widget.length; i++)
                  _Box(
                    char: i < code.length ? code[i] : '',
                    active: _focus.hasFocus && i == code.length,
                    error: widget.hasError,
                    colors: colors,
                  ),
              ],
            ),
            // The real input sits invisibly on top of the boxes.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _changed,
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.char,
    required this.active,
    required this.error,
    required this.colors,
  });

  final String char;
  final bool active;
  final bool error;
  final SynkColors colors;

  @override
  Widget build(BuildContext context) {
    final border = error
        ? colors.destructive
        : active
        ? colors.primary
        : colors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 46,
      height: 56,
      decoration: BoxDecoration(
        color: colors.solidInputBackground,
        borderRadius: SynkRadius.mdAll,
        border: Border.all(color: border, width: active || error ? 2 : 1),
      ),
      alignment: Alignment.center,
      child: SynkText(char, variant: SynkTextVariant.h2),
    );
  }
}
