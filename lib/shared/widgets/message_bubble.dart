import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/models/message.dart';
import 'photo_art.dart';

/// One chat message: text, image or voice note, with a delivery tick on your own messages.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    this.showTime = false,
    super.key,
  });

  final Message message;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fromMe = message.fromMe;
    final background = fromMe ? colors.primary : colors.muted;
    final foreground = fromMe ? colors.primaryForeground : colors.foreground;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(fromMe ? 20 : 6),
      bottomRight: Radius.circular(fromMe ? 6 : 20),
    );

    final Widget content = switch (message.kind) {
      MessageKind.text => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SynkText(
          message.text,
          color: foreground,
          variant: SynkTextVariant.p,
        ),
      ),
      MessageKind.image => SizedBox(
        width: 220,
        height: 260,
        child: PhotoArt(seed: message.imageSeed ?? 0),
      ),
      MessageKind.voice => _VoiceNote(
        seconds: message.voiceSeconds ?? 0,
        color: foreground,
        seed: message.id.hashCode,
      ),
    };

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: fromMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Semantics(
              label: switch (message.kind) {
                MessageKind.text => null,
                MessageKind.image => 'Photo',
                MessageKind.voice => 'Voice message, ${message.voiceSeconds}s',
              },
              child: ClipRRect(
                borderRadius: radius,
                child: ColoredBox(
                  color: message.kind == MessageKind.image
                      ? Colors.transparent
                      : background,
                  child: content,
                ),
              ),
            ),
            if (showTime || fromMe)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showTime)
                      SynkText(
                        _time(message.sentAt),
                        variant: SynkTextVariant.listDescription,
                      ),
                    if (fromMe) ...[
                      if (showTime) const SizedBox(width: 4),
                      _Tick(status: message.status),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: switch (status) {
        MessageStatus.sending => 'Sending',
        MessageStatus.sent => 'Sent',
        MessageStatus.read => 'Read',
      },
      child: ExcludeSemantics(
        child: SynkIcon(
          status == MessageStatus.sent || status == MessageStatus.sending
              ? SynkIcons.check
              : SynkIcons.checkDouble,
          size: 14,
          color: status == MessageStatus.read
              ? SynkPalette.indigo
              : colors.mutedForeground,
        ),
      ),
    );
  }
}

class _VoiceNote extends StatefulWidget {
  const _VoiceNote({
    required this.seconds,
    required this.color,
    required this.seed,
  });

  final int seconds;
  final Color color;
  final int seed;

  @override
  State<_VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends State<_VoiceNote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds.clamp(1, 60)),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_c.isAnimating) {
      _c.stop();
    } else {
      _c.value = _c.isCompleted ? 0 : _c.value;
      _c.forward();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bars = List<double>.generate(
      24,
      (i) => 0.25 + ((widget.seed.abs() * (i + 3) * 2654435761) % 100) / 133,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SynkPressable(
            semanticLabel: _c.isAnimating ? 'Pause' : 'Play voice message',
            onTap: _toggle,
            child: SizedBox.square(
              dimension: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SynkIcon(
                    _c.isAnimating ? SynkIcons.pause : SynkIcons.play,
                    size: 16,
                    color: widget.color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Row(
              children: [
                for (var i = 0; i < bars.length; i++)
                  Container(
                    width: 3,
                    height: 8 + 18 * bars[i].clamp(0.0, 1.0),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(
                        alpha: i / bars.length <= _c.value ? 1 : 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SynkText(
            '0:${widget.seconds.toString().padLeft(2, '0')}',
            variant: SynkTextVariant.small,
            color: widget.color,
          ),
        ],
      ),
    );
  }
}
