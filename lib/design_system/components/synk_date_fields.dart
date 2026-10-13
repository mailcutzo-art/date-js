import 'package:flutter/material.dart';

import '../foundation/tap_target.dart';
import '../icons/synk_icon.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';

const List<String> _kMonthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Fixed English `d MMMM yyyy` formatting (never locale dependent), e.g. `5 October 2026`.
/// Only the year, month and day of [date] are used.
String formatSynkDate(DateTime date) =>
    '${date.day} ${_kMonthNames[date.month - 1]} '
    '${date.year.toString().padLeft(4, '0')}';

/// Fixed English time formatting: `h:mm a` (`8:00 PM`) or, with [use24h], `HH:mm` (`20:00`).
String formatSynkTime(TimeOfDay time, {required bool use24h}) {
  final minute = time.minute.toString().padLeft(2, '0');
  if (use24h) return '${time.hour.toString().padLeft(2, '0')}:$minute';
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// `date` minus [years], clamping Feb 29 to Feb 28 (like `LocalDate.minusYears`).
DateTime _minusYears(DateTime date, int years) {
  final year = date.year - years;
  final lastDay = DateUtils.getDaysInMonth(year, date.month);
  return DateTime(year, date.month, date.day > lastDay ? lastDay : date.day);
}

DateTime _clamp(DateTime d, DateTime min, DateTime max) =>
    d.isBefore(min) ? min : (d.isAfter(max) ? max : d);

/// Opens the Material date picker over `[minDate, maxDate]`. Resolves to a date-only UTC value
/// (`DateTime.utc(y, m, d)`) so a timezone can never shift the day, or null when cancelled.
Future<DateTime?> _pickDate(
  BuildContext context, {
  required DateTime? value,
  required DateTime? initialDate,
  required DateTime? minDate,
  required DateTime? maxDate,
  required DateTime today,
}) async {
  final first = _dateOnly(minDate ?? DateTime(1900));
  final lastCandidate = _dateOnly(maxDate ?? DateTime(2100, 12, 31));
  final last = lastCandidate.isBefore(first) ? first : lastCandidate;
  final initial = _clamp(
    _dateOnly(value ?? initialDate ?? maxDate ?? today),
    first,
    last,
  );
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
  );
  if (picked == null) return null;
  return DateTime.utc(picked.year, picked.month, picked.day);
}

/// A date field: shows the chosen day in `d MMMM yyyy` and opens the Material date picker.
///
/// [value] and the result are date-only; only year/month/day are read from [value] and the
/// result is `DateTime.utc(y, m, d)`. The picker starts on `value ?? initialDate ?? maxDate ??
/// today`, clamped into `[minDate, maxDate]` (default 1900 to 2100). A clear button shows when
/// [clearable] and a value is set (never while disabled). [now] is injectable for tests.
class SynkDateField extends StatelessWidget {
  const SynkDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Pick a day',
    this.minDate,
    this.maxDate,
    this.initialDate,
    this.clearable = true,
    this.enabled = true,
    this.now,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String placeholder;
  final DateTime? minDate;
  final DateTime? maxDate;
  final DateTime? initialDate;
  final bool clearable;
  final bool enabled;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final current = value;
    return SynkFieldSurface(
      icon: SynkIcons.calendar,
      placeholder: placeholder,
      text: current == null ? null : formatSynkDate(current),
      enabled: enabled,
      clearable: clearable,
      onClear: () => onChanged(null),
      onTap: () async {
        final picked = await _pickDate(
          context,
          value: value,
          initialDate: initialDate,
          minDate: minDate,
          maxDate: maxDate,
          today: (now ?? DateTime.now)(),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// Birthday field: placeholder `Add your birthday`, ages 5 to 120 (the newest allowed day is
/// today minus 5 years minus 1 day because the server counts ages in IST, which can lag a day),
/// and the picker opens on 2000-01-01 (clamped into the range).
class SynkBirthdayField extends StatelessWidget {
  const SynkBirthdayField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Add your birthday',
    this.enabled = true,
    this.now,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String placeholder;
  final bool enabled;
  final DateTime Function()? now;

  /// Earliest and latest selectable birthdays for [today].
  static ({DateTime min, DateTime max}) rangeFor(DateTime today) {
    final day = _dateOnly(today);
    final max = _minusYears(day, 5);
    return (
      min: _minusYears(day, 120),
      max: DateTime(max.year, max.month, max.day - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = (now ?? DateTime.now)();
    final range = rangeFor(today);
    return SynkDateField(
      value: value,
      onChanged: onChanged,
      placeholder: placeholder,
      minDate: range.min,
      maxDate: range.max,
      initialDate: DateTime(2000),
      enabled: enabled,
      now: () => today,
    );
  }
}

/// A time field: shows `h:mm a` (or `HH:mm` when [use24h], by default the device setting) and
/// opens the Material time picker, which starts on 20:00 when the field is empty.
class SynkTimeField extends StatelessWidget {
  const SynkTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Pick a time',
    this.use24h,
    this.enabled = true,
    this.clearable = true,
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String placeholder;

  /// `null` follows `MediaQuery.alwaysUse24HourFormatOf`.
  final bool? use24h;
  final bool enabled;
  final bool clearable;

  static const TimeOfDay defaultTime = TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    final is24h = use24h ?? MediaQuery.alwaysUse24HourFormatOf(context);
    final current = value;
    return SynkFieldSurface(
      icon: SynkIcons.clock,
      placeholder: placeholder,
      text: current == null ? null : formatSynkTime(current, use24h: is24h),
      enabled: enabled,
      clearable: clearable,
      onClear: () => onChanged(null),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? defaultTime,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: is24h),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// The read-only "field surface" shared by the date and time fields: solid-input look, a leading
/// icon, the value (or muted placeholder) and an optional clear button. Pressed it dims to 85 %,
/// disabled it dims to 50 % and ignores taps.
class SynkFieldSurface extends StatefulWidget {
  const SynkFieldSurface({
    super.key,
    required this.icon,
    required this.placeholder,
    required this.text,
    required this.onTap,
    this.onClear,
    this.clearable = false,
    this.enabled = true,
  });

  final SynkIcons icon;
  final String placeholder;

  /// Formatted value, null while empty.
  final String? text;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool clearable;
  final bool enabled;

  @override
  State<SynkFieldSurface> createState() => _SynkFieldSurfaceState();
}

class _SynkFieldSurfaceState extends State<SynkFieldSurface> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  void didUpdateWidget(SynkFieldSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = widget.text;
    final filled = text != null;
    final showClear =
        widget.clearable && filled && widget.enabled && widget.onClear != null;
    final textStyle = SynkTypography.of(SynkTextVariant.input);

    final main = TapTarget(
      properties: SemanticsProperties(
        button: true,
        enabled: widget.enabled,
        label: filled ? '${widget.placeholder}, $text' : widget.placeholder,
        onTap: widget.enabled ? widget.onTap : null,
      ),
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
        onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
        onTapCancel: widget.enabled ? () => _setPressed(false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: ExcludeSemantics(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: 14,
              top: 12,
              bottom: 12,
              end: showClear ? 4 : 14,
            ),
            child: Row(
              children: [
                SynkIcon(
                  widget.icon,
                  size: SynkIconSize.base,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text ?? widget.placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle.copyWith(
                      color: filled
                          ? colors.foreground
                          : colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Opacity(
      opacity: !widget.enabled ? 0.5 : (_pressed ? 0.85 : 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.solidInputBackground,
          borderRadius: SynkRadius.smAll,
          border: Border.all(color: Colors.transparent),
        ),
        // 1dp inset mirrors the text field's border so both are 48dp tall.
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Row(
            children: [
              Expanded(child: main),
              if (showClear)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: _ClearButton(onTap: widget.onClear!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 24dp clear "X" (semantics label `Clear`), pressed dims to 60 %.
class _ClearButton extends StatefulWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TapTarget(
      properties: SemanticsProperties(
        button: true,
        label: 'Clear',
        onTap: widget.onTap,
      ),
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: ExcludeSemantics(
          child: AnimatedOpacity(
            opacity: _pressed ? 0.6 : 1,
            duration: const Duration(milliseconds: 80),
            // A 24dp visual with a 32dp touch area.
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.mutedForeground.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: SynkIcon(
                    SynkIcons.close,
                    size: SynkIconSize.xs,
                    color: colors.mutedForeground,
                    strokeWidth: 1.8,
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
