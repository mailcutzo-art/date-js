import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/preferences.dart';
import '../../shared/widgets/preference_slider.dart';

/// Bottom sheet to edit who shows up in discovery. Resolves with the new preferences when the
/// user taps Apply (null when dismissed). [premium] unlocks the verified-only switch; without
/// it the switch calls [onPremiumTap].
Future<Preferences?> showFiltersSheet(
  BuildContext context, {
  required Preferences current,
  required bool premium,
  required VoidCallback onPremiumTap,
}) {
  return showSynkBottomSheet<Preferences>(
    context,
    builder: (context) => _FiltersBody(
      initial: current,
      premium: premium,
      onPremiumTap: onPremiumTap,
    ),
  );
}

class _FiltersBody extends StatefulWidget {
  const _FiltersBody({
    required this.initial,
    required this.premium,
    required this.onPremiumTap,
  });

  final Preferences initial;
  final bool premium;
  final VoidCallback onPremiumTap;

  @override
  State<_FiltersBody> createState() => _FiltersBodyState();
}

class _FiltersBodyState extends State<_FiltersBody> {
  late Preferences _p = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeader(children: [SheetTitle('Filters')]),
        const SizedBox(height: 12),
        const SectionLabel('Show me'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in Gender.values)
              SynkChip(
                label: g.label,
                selected: _p.interestedIn.contains(g),
                onTap: () => setState(() {
                  final next = {..._p.interestedIn};
                  if (!next.remove(g)) next.add(g);
                  if (next.isNotEmpty) _p = _p.copyWith(interestedIn: next);
                }),
              ),
          ],
        ),
        const SizedBox(height: 18),
        PreferenceRangeSlider(
          label: 'Age',
          valueText: '${_p.minAge} to ${_p.maxAge}',
          values: RangeValues(_p.minAge.toDouble(), _p.maxAge.toDouble()),
          min: 18,
          max: 60,
          divisions: 42,
          onChanged: (v) => setState(
            () => _p = _p.copyWith(
              minAge: v.start.round(),
              maxAge: v.end.round(),
            ),
          ),
        ),
        PreferenceSlider(
          label: 'Maximum distance',
          valueText: '${_p.maxDistanceKm} km',
          value: _p.maxDistanceKm.toDouble(),
          min: 2,
          max: 100,
          divisions: 49,
          onChanged: (v) =>
              setState(() => _p = _p.copyWith(maxDistanceKm: v.round())),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(
              child: SynkText(
                'Verified profiles only',
                variant: SynkTextVariant.p,
              ),
            ),
            if (!widget.premium)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SynkBadge(
                  text: 'Premium',
                  variant: SynkBadgeVariant.amber,
                  small: true,
                ),
              ),
            SynkSwitch(
              value: _p.verifiedOnly,
              semanticLabel: 'Verified profiles only',
              onChanged: (v) {
                if (!widget.premium) {
                  widget.onPremiumTap();
                  return;
                }
                setState(() => _p = _p.copyWith(verifiedOnly: v));
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SynkButton(
                label: 'Reset',
                variant: SynkButtonVariant.outline,
                expand: true,
                onPressed: () => setState(() => _p = const Preferences()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SynkButton(
                label: 'Apply',
                expand: true,
                onPressed: () => Navigator.of(context).pop(_p),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
