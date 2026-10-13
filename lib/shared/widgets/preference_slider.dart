import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Label + current value above a themed slider.
class PreferenceSlider extends StatelessWidget {
  const PreferenceSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    super.key,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SliderFrame(
      label: label,
      valueText: valueText,
      slider: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        semanticFormatterCallback: (v) => v.round().toString(),
      ),
    );
  }
}

/// Same as [PreferenceSlider] with two thumbs (for example an age range).
class PreferenceRangeSlider extends StatelessWidget {
  const PreferenceRangeSlider({
    required this.label,
    required this.valueText,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    super.key,
  });

  final String label;
  final String valueText;
  final RangeValues values;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SliderFrame(
      label: label,
      valueText: valueText,
      slider: RangeSlider(
        values: values,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        semanticFormatterCallback: (v) => v.round().toString(),
      ),
    );
  }
}

class _SliderFrame extends StatelessWidget {
  const _SliderFrame({
    required this.label,
    required this.valueText,
    required this.slider,
  });

  final String label;
  final String valueText;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SynkText(label, variant: SynkTextVariant.small)),
            SynkText(valueText, variant: SynkTextVariant.small),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.border,
            thumbColor: colors.primary,
            overlayColor: colors.primary.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: slider,
        ),
      ],
    );
  }
}
