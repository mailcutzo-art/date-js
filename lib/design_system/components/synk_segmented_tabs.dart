import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

import '../foundation/tap_target.dart';
import '../icons/synk_icon.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';

/// One option of a [SynkSegmentedTabs].
@immutable
class SynkTabOption<T> {
  const SynkTabOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final SynkIcons? icon;
}

/// Equal-width segmented control (the Android `SynklySegmentedTabs`): a 12dp-radius track
/// (foreground at 6 %) with 4dp padding and gap, and a card-coloured, 1dp-bordered, 9dp-radius
/// pill under the selected option (lifted to `muted` in dark mode for contrast). Labels are
/// 13/600; the selected label is foreground with a primary icon, unselected ones are muted.
/// Pressed options dim to 80 %; a disabled control is dimmed to 50 % and inert.
///
/// [onChanged] only fires when a different option is tapped. The control needs a parent with
/// a bounded width (it divides it equally).
class SynkSegmentedTabs<T> extends StatelessWidget {
  const SynkSegmentedTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final List<SynkTabOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      role: SemanticsRole.tabBar,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.foreground.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: _SegmentedOption<T>(
                      option: options[i],
                      selected: options[i].value == selected,
                      enabled: enabled,
                      onTap: () {
                        if (options[i].value != selected) {
                          onChanged(options[i].value);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedOption<T> extends StatefulWidget {
  const _SegmentedOption({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final SynkTabOption<T> option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_SegmentedOption<T>> createState() => _SegmentedOptionState<T>();
}

class _SegmentedOptionState<T> extends State<_SegmentedOption<T>> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = widget.selected;
    final icon = widget.option.icon;
    // In dark mode the card colour is no lighter than the track and the dark primary has ~2:1
    // contrast on it, so the selected pill is lifted to `muted` and the icon uses the brand pink.
    final pillColor = colors.isDark ? colors.muted : colors.card;
    final iconAccent = colors.primaryText;
    final contentColor = selected ? colors.foreground : colors.mutedForeground;
    final style = SynkTypography.of(SynkTextVariant.tab)
        .copyWith(fontSize: 13, color: contentColor);

    return TapTarget(
      properties: SemanticsProperties(
        role: SemanticsRole.tab,
        selected: selected,
        enabled: widget.enabled,
        inMutuallyExclusiveGroup: true,
        label: widget.option.label,
        onTap: widget.enabled ? widget.onTap : null,
      ),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
          onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
          onTapCancel: widget.enabled ? () => _setPressed(false) : null,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedOpacity(
            opacity: _pressed && widget.enabled ? 0.8 : 1,
            duration: const Duration(milliseconds: 80),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? pillColor : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected ? colors.border : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    SynkIcon(
                      icon,
                      size: SynkIconSize.md,
                      color: selected ? iconAccent : colors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: Text(widget.option.label),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
