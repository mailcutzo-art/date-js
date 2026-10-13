import 'dart:async';

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Message input bar: attach, text field and a send / mic button. Holding the mic is replaced
/// by tap-to-record: the bar switches to a recording strip with a timer, cancel and send.
class Composer extends StatefulWidget {
  const Composer({
    required this.onSendText,
    required this.onSendPhoto,
    required this.onSendVoice,
    this.controller,
    super.key,
  });

  final ValueChanged<String> onSendText;
  final VoidCallback onSendPhoto;
  final ValueChanged<int> onSendVoice;

  /// Lets the chat prefill the field (suggested openers).
  final TextEditingController? controller;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  late final TextEditingController _text =
      widget.controller ?? TextEditingController();
  Timer? _ticker;
  int _seconds = 0;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (widget.controller == null) _text.dispose();
    super.dispose();
  }

  void _send() {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    widget.onSendText(value);
    _text.clear();
  }

  void _startRecording() {
    SynkHapticsScope.of(context).play(SynkHaptic.impactMedium);
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= 60) _finishRecording(send: true);
    });
  }

  void _finishRecording({required bool send}) {
    _ticker?.cancel();
    final seconds = _seconds;
    setState(() => _recording = false);
    if (send) widget.onSendVoice(seconds < 1 ? 1 : seconds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: _recording ? _recordingBar(colors) : _inputBar(),
        ),
      ),
    );
  }

  Widget _inputBar() {
    final hasText = _text.text.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleIconButton(
          icon: SynkIcons.image,
          semanticLabel: 'Send a photo',
          tone: CircleButtonTone.soft,
          onPressed: widget.onSendPhoto,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SynkTextField(
            controller: _text,
            hint: 'Message',
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
          ),
        ),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: hasText ? SynkIcons.send : SynkIcons.mic,
          semanticLabel: hasText ? 'Send' : 'Record a voice message',
          onPressed: hasText ? _send : _startRecording,
        ),
      ],
    );
  }

  Widget _recordingBar(SynkColors colors) {
    return Row(
      children: [
        CircleIconButton(
          icon: SynkIcons.trash,
          semanticLabel: 'Cancel recording',
          tone: CircleButtonTone.soft,
          onPressed: () => _finishRecording(send: false),
        ),
        const SizedBox(width: 12),
        const _RecDot(),
        const SizedBox(width: 8),
        Expanded(
          child: SynkText(
            '0:${_seconds.toString().padLeft(2, '0')}',
            variant: SynkTextVariant.large,
          ),
        ),
        CircleIconButton(
          icon: SynkIcons.send,
          semanticLabel: 'Send voice message',
          onPressed: () => _finishRecording(send: true),
        ),
      ],
    );
  }
}

class _RecDot extends StatefulWidget {
  const _RecDot();

  @override
  State<_RecDot> createState() => _RecDotState();
}

class _RecDotState extends State<_RecDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: SynkPalette.youtubeRed,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
