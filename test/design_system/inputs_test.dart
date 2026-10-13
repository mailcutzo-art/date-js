import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/components/synk_date_fields.dart';
import 'package:date_js/design_system/components/synk_switch.dart';
import 'package:date_js/design_system/components/synk_text_field.dart';
import 'package:date_js/design_system/icons/synk_icon.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_theme.dart';

import '../support/synk_test_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(420, 800),
}) async {
  useGoldenViewport(tester, size: size);
  await tester.pumpWidget(
    synkApp(
      Align(alignment: Alignment.topLeft, child: child),
      brightness: brightness,
      textScale: textScale,
    ),
  );
}

/// The decorated box that draws the field's fill and border.
BoxDecoration _boxOf(WidgetTester tester) {
  final box = find
      .descendant(
        of: find.byType(SynkTextField),
        matching: find.byType(DecoratedBox),
      )
      .evaluate()
      .map((e) => e.widget as DecoratedBox)
      .firstWhere(
        (w) =>
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border != null,
      );
  return box.decoration as BoxDecoration;
}

Border _borderOf(WidgetTester tester) => _boxOf(tester).border! as Border;

Finder _closeIcon() =>
    find.byWidgetPredicate((w) => w is SynkIcon && w.icon == SynkIcons.close);

void main() {
  const light = SynkColors.light;

  group('SynkTextField', () {
    testWidgets('typing fires onChanged and updates the controller', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: SynkTextField(
            controller: controller,
            hint: 'Your name',
            onChanged: changes.add,
          ),
        ),
      );
      expect(find.text('Your name'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Ravi');
      expect(controller.text, 'Ravi');
      expect(changes, ['Ravi']);
      await tester.pump();
      final hintFade = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('Your name'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(hintFade.opacity, 0, reason: 'hint hides once filled');
    });

    testWidgets('onSubmitted fires with the text', (tester) async {
      String? submitted;
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: SynkTextField(
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => submitted = v,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'go');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submitted, 'go');
    });

    testWidgets('maxLength truncates and shows no counter', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: SynkTextField(controller: controller, maxLength: 5),
        ),
      );
      await tester.enterText(find.byType(TextField), 'abcdefghij');
      expect(controller.text, 'abcde');
      expect(find.text('5/5'), findsNothing);
      expect(find.textContaining('/5'), findsNothing);
      await tester.enterText(find.byType(TextField), 'ab');
      expect(find.textContaining('/5'), findsNothing);
    });

    testWidgets('obscureText hides the input', (tester) async {
      await _pump(
        tester,
        const SizedBox(width: 300, child: SynkTextField(obscureText: true)),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
    });

    testWidgets('cursor is primary, text uses the input style', (tester) async {
      await _pump(tester, const SizedBox(width: 300, child: SynkTextField()));
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorColor, light.primary);
      expect(editable.style.fontSize, 16);
      expect(editable.style.color, light.foreground);
      expect(editable.style.height, closeTo(22 / 16, 0.001));
    });

    testWidgets('hint uses the muted foreground colour', (tester) async {
      await _pump(
        tester,
        const SizedBox(width: 300, child: SynkTextField(hint: 'Search')),
      );
      expect(
        tester.widget<Text>(find.text('Search')).style?.color,
        light.mutedForeground,
      );
    });

    testWidgets('solid look: radius 8, solid fill, 1dp transparent border', (
      tester,
    ) async {
      await _pump(tester, const SizedBox(width: 300, child: SynkTextField()));
      final box = _boxOf(tester);
      expect(box.color, light.solidInputBackground);
      expect(box.borderRadius, BorderRadius.circular(8));
      final border = _borderOf(tester);
      expect(border.top.width, 1);
      expect(border.top.color, Colors.transparent);
      expect(tester.getSize(find.byType(SynkTextField)).height, closeTo(48, 1));
    });

    testWidgets('glass look: radius 14, overlay fill, 2px glass border', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: SynkTextField(variant: SynkInputVariant.glass),
        ),
      );
      final box = _boxOf(tester);
      expect(box.color, light.glassOverlay);
      expect(box.borderRadius, BorderRadius.circular(14));
      final border = _borderOf(tester);
      expect(
        border.top.width,
        closeTo(2 / tester.view.devicePixelRatio, 0.0001),
      );
      expect(border.top.color, light.glassBorder);
    });

    testWidgets('focus switches the border and tapping the padding focuses', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await _pump(
        tester,
        SizedBox(width: 300, child: SynkTextField(focusNode: node)),
      );
      expect(_borderOf(tester).top.color, Colors.transparent);

      // Left padding area, outside the editable region.
      final topLeft = tester.getTopLeft(find.byType(SynkTextField));
      await tester.tapAt(topLeft + const Offset(5, 24));
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(_borderOf(tester).top.color, light.solidInputFocusedBorder);

      node.unfocus();
      await tester.pump();
      expect(_borderOf(tester).top.color, Colors.transparent);
    });

    testWidgets(
      'works with its own focus node and an external one swapped in',
      (tester) async {
        final external = FocusNode();
        addTearDown(external.dispose);
        Widget build(FocusNode? node) =>
            SizedBox(width: 300, child: SynkTextField(focusNode: node));
        await _pump(tester, build(null));
        await tester.tap(find.byType(TextField));
        await tester.pump();
        expect(_borderOf(tester).top.color, light.solidInputFocusedBorder);

        await _pump(tester, build(external));
        await tester.pump();
        expect(_borderOf(tester).top.color, Colors.transparent);
        external.requestFocus();
        await tester.pump();
        expect(_borderOf(tester).top.color, light.solidInputFocusedBorder);
        // Removing the widget must not dispose the external node.
        await tester.pumpWidget(const SizedBox());
        expect(() => external.addListener(() {}), returnsNormally);
      },
    );

    testWidgets('autofocus focuses the field', (tester) async {
      await _pump(
        tester,
        const SizedBox(width: 300, child: SynkTextField(autofocus: true)),
      );
      await tester.pump();
      expect(_borderOf(tester).top.color, light.solidInputFocusedBorder);
    });

    testWidgets('error text shows in destructive and recolours the border', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: SynkTextField(
            errorText: 'Name is required',
            helperText: 'Shown to friends',
          ),
        ),
      );
      expect(_borderOf(tester).top.color, light.destructive);
      final error = tester.widget<Text>(find.text('Name is required'));
      expect(error.style?.color, light.destructive);
      expect(error.style?.fontSize, 12);
      expect(
        find.text('Shown to friends'),
        findsNothing,
        reason: 'error replaces helper',
      );
    });

    testWidgets('error stays destructive while focused', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: SynkTextField(errorText: 'Bad', autofocus: true),
        ),
      );
      await tester.pump();
      expect(_borderOf(tester).top.color, light.destructive);
    });

    testWidgets('helper text is muted 11sp', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: SynkTextField(helperText: 'Only the day and month are shared'),
        ),
      );
      final helper = tester.widget<Text>(
        find.text('Only the day and month are shared'),
      );
      expect(helper.style?.color, light.mutedForeground);
      expect(helper.style?.fontSize, 11);
      expect(_borderOf(tester).top.color, Colors.transparent);
    });

    testWidgets('disabled looks exactly like enabled but refuses focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final controller = TextEditingController(text: 'Locked');
      addTearDown(controller.dispose);

      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: SynkTextField(controller: controller, hint: 'h'),
        ),
      );
      final enabledBox = _boxOf(tester);
      final enabledStyle = tester
          .widget<EditableText>(find.byType(EditableText))
          .style;
      final enabledSize = tester.getSize(find.byType(SynkTextField));

      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: SynkTextField(
            controller: controller,
            hint: 'h',
            enabled: false,
            focusNode: node,
          ),
        ),
      );
      final disabledBox = _boxOf(tester);
      expect(disabledBox.color, enabledBox.color);
      expect(disabledBox.border, enabledBox.border);
      expect(disabledBox.borderRadius, enabledBox.borderRadius);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style,
        enabledStyle,
      );
      expect(tester.getSize(find.byType(SynkTextField)), enabledSize);

      await tester.tap(find.byType(SynkTextField), warnIfMissed: false);
      await tester.tapAt(
        tester.getTopLeft(find.byType(SynkTextField)) + const Offset(5, 24),
      );
      await tester.pump();
      expect(node.hasFocus, isFalse);
      expect(_borderOf(tester).top.color, Colors.transparent);
    });

    testWidgets(
      'multi-line field grows from minLines to maxLines then scrolls',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await _pump(
          tester,
          SizedBox(
            width: 300,
            child: SynkTextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
            ),
          ),
        );
        final minHeight = tester.getSize(find.byType(SynkTextField)).height;
        expect(minHeight, closeTo(24 + 2 + 2 * 22, 1));

        await tester.enterText(find.byType(TextField), 'a\nb\nc');
        await tester.pump();
        final threeLines = tester.getSize(find.byType(SynkTextField)).height;
        expect(threeLines, closeTo(24 + 2 + 3 * 22, 1));

        await tester.enterText(
          find.byType(TextField),
          List.filled(10, 'x').join('\n'),
        );
        await tester.pump();
        final capped = tester.getSize(find.byType(SynkTextField)).height;
        expect(capped, closeTo(24 + 2 + 4 * 22, 1));
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).maxLines,
          4,
        );
      },
    );

    testWidgets('leading and trailing slots surround the text', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: SynkTextField(
            hint: 'Search groups',
            leading: SizedBox(key: ValueKey('lead'), width: 18, height: 18),
            trailing: SizedBox(key: ValueKey('trail'), width: 18, height: 18),
          ),
        ),
      );
      final lead = tester.getRect(find.byKey(const ValueKey('lead')));
      final trail = tester.getRect(find.byKey(const ValueKey('trail')));
      final field = tester.getRect(find.byType(TextField));
      expect(lead.right, lessThanOrEqualTo(field.left));
      expect(trail.left, greaterThanOrEqualTo(field.right));
      expect(
        lead.left,
        closeTo(tester.getTopLeft(find.byType(SynkTextField)).dx + 15, 0.5),
      );
    });

    testWidgets('semantic label is exposed on the text field', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: SynkTextField(
            hint: 'Your name',
            semanticLabel: 'Display name',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(TextField)),
        // Named by its label; the placeholder is the hint (an example), not a second name.
        isSemantics(
          isTextField: true,
          label: 'Display name',
          hint: 'Your name',
        ),
      );
      // No extra wrapper nodes around the field.
      expect(find.bySemanticsLabel(RegExp('Display name')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('error message is a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: SynkTextField(errorText: 'Too short'),
        ),
      );
      expect(
        tester.getSemantics(find.text('Too short')),
        isSemantics(label: 'Too short', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('input formatters are applied', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: SynkTextField(
            controller: controller,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'a1b2');
      expect(controller.text, '12');
    });

    testWidgets('survives text scale 1.3 with every decoration', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: Column(
            children: [
              SynkTextField(
                hint: 'Group name that is rather long indeed',
                leading: Icon(Icons.search, size: 18),
                trailing: Icon(Icons.close, size: 18),
                errorText: 'Something is wrong with this field, please check',
              ),
              SynkTextField(
                hint: 'x',
                variant: SynkInputVariant.glass,
                helperText:
                    'A helper line that wraps onto a second line for sure',
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark theme uses the dark tokens', (tester) async {
      await _pump(
        tester,
        const SizedBox(width: 300, child: SynkTextField()),
        brightness: Brightness.dark,
      );
      expect(_boxOf(tester).color, SynkColors.dark.solidInputBackground);
    });
  });

  group('date and time formatting', () {
    test('formats d MMMM yyyy in English regardless of locale or zone', () {
      const months = [
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
      for (var m = 1; m <= 12; m++) {
        expect(formatSynkDate(DateTime(2026, m, 5)), '5 ${months[m - 1]} 2026');
        expect(
          formatSynkDate(DateTime.utc(2026, m, 28)),
          '28 ${months[m - 1]} 2026',
        );
      }
      expect(formatSynkDate(DateTime(2026, 10, 5)), '5 October 2026');
      expect(formatSynkDate(DateTime.utc(2000, 1, 1)), '1 January 2000');
      expect(formatSynkDate(DateTime(5, 3, 9)), '9 March 0005');
    });

    test('formats times as h:mm a or HH:mm', () {
      String f(int h, int m, {bool use24h = false}) => formatSynkTime(
        TimeOfDay(hour: h, minute: m),
        use24h: use24h,
      );
      expect(f(20, 0), '8:00 PM');
      expect(f(0, 5), '12:05 AM');
      expect(f(12, 30), '12:30 PM');
      expect(f(9, 7), '9:07 AM');
      expect(f(23, 59), '11:59 PM');
      expect(f(20, 0, use24h: true), '20:00');
      expect(f(8, 5, use24h: true), '08:05');
      expect(f(0, 0, use24h: true), '00:00');
    });

    test('birthday range is ages 5..120 with a one day margin', () {
      final range = SynkBirthdayField.rangeFor(DateTime(2026, 10, 5, 23, 59));
      expect(range.min, DateTime(1906, 10, 5));
      expect(range.max, DateTime(2021, 10, 4));
    });

    test('birthday range clamps Feb 29 like minusYears', () {
      final leap = SynkBirthdayField.rangeFor(DateTime(2028, 2, 29));
      expect(leap.min, DateTime(1908, 2, 29));
      expect(leap.max, DateTime(2023, 2, 27));
      final other = SynkBirthdayField.rangeFor(DateTime(2024, 2, 29));
      expect(other.min, DateTime(1904, 2, 29));
      expect(other.max, DateTime(2019, 2, 27));
    });
  });

  group('SynkDateField', () {
    Future<void> openPicker(WidgetTester tester) async {
      await tester.tap(find.byType(SynkFieldSurface));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the placeholder, then the formatted value', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(value: null, onChanged: (_) {}),
        ),
      );
      expect(find.text('Pick a day'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Pick a day')).style?.color,
        light.mutedForeground,
      );
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(
            value: DateTime.utc(2026, 10, 5),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('5 October 2026'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('5 October 2026')).style?.color,
        light.foreground,
      );
    });

    testWidgets(
      'surface look: solid input fill, radius 8, 18dp calendar icon',
      (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 320,
            child: SynkDateField(value: null, onChanged: (_) {}),
          ),
        );
        final decorated = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(SynkFieldSurface),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final decoration = decorated.decoration as BoxDecoration;
        expect(decoration.color, light.solidInputBackground);
        expect(decoration.borderRadius, BorderRadius.circular(8));
        final icon = tester.widget<SynkIcon>(find.byType(SynkIcon));
        expect(icon.icon, SynkIcons.calendar);
        expect(icon.size, 18);
        expect(
          tester.getSize(find.byType(SynkFieldSurface)).height,
          closeTo(48, 1),
        );
      },
    );

    testWidgets(
      'opens the picker on maxDate and returns a date-only UTC value',
      (tester) async {
        DateTime? result;
        await _pump(
          tester,
          SizedBox(
            width: 320,
            child: SynkDateField(
              value: null,
              maxDate: DateTime(2026, 10, 20),
              onChanged: (v) => result = v,
            ),
          ),
        );
        await openPicker(tester);
        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        await tester.tap(find.text('15'));
        await tester.pump();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(result, DateTime.utc(2026, 10, 15));
        expect(result!.isUtc, isTrue);
        expect(result!.hour, 0);
      },
    );

    testWidgets('confirming without touching returns the initial date', (
      tester,
    ) async {
      DateTime? result;
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(
            value: DateTime.utc(2024, 2, 29),
            onChanged: (v) => result = v,
          ),
        ),
      );
      await openPicker(tester);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, DateTime.utc(2024, 2, 29));
    });

    testWidgets('cancel leaves the value alone', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(
            value: DateTime.utc(2024, 2, 29),
            onChanged: (_) => calls++,
          ),
        ),
      );
      await openPicker(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets(
      'initial date prefers value, then initialDate, then maxDate, then today',
      (tester) async {
        Future<DateTime?> confirm({
          DateTime? value,
          DateTime? initialDate,
          DateTime? maxDate,
          DateTime? minDate,
        }) async {
          DateTime? result;
          await _pump(
            tester,
            SizedBox(
              width: 320,
              child: SynkDateField(
                value: value,
                initialDate: initialDate,
                minDate: minDate,
                maxDate: maxDate,
                now: () => DateTime(2026, 10, 5, 14, 30),
                onChanged: (v) => result = v,
              ),
            ),
          );
          await openPicker(tester);
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          return result;
        }

        expect(
          await confirm(
            value: DateTime.utc(2020, 3, 4),
            initialDate: DateTime(2010, 1, 1),
            maxDate: DateTime(2030, 1, 1),
          ),
          DateTime.utc(2020, 3, 4),
        );
        expect(
          await confirm(
            initialDate: DateTime(2010, 1, 1),
            maxDate: DateTime(2030, 1, 1),
          ),
          DateTime.utc(2010, 1, 1),
        );
        expect(
          await confirm(maxDate: DateTime(2022, 5, 6)),
          DateTime.utc(2022, 5, 6),
        );
        expect(await confirm(), DateTime.utc(2026, 10, 5));
      },
    );

    testWidgets('initial date is clamped into [minDate, maxDate]', (
      tester,
    ) async {
      Future<DateTime?> confirm({
        required DateTime initialDate,
        DateTime? minDate,
        DateTime? maxDate,
      }) async {
        DateTime? result;
        await _pump(
          tester,
          SizedBox(
            width: 320,
            child: SynkDateField(
              value: null,
              initialDate: initialDate,
              minDate: minDate,
              maxDate: maxDate,
              onChanged: (v) => result = v,
            ),
          ),
        );
        await openPicker(tester);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        return result;
      }

      expect(
        await confirm(
          initialDate: DateTime(1990, 1, 1),
          minDate: DateTime(2000, 6, 15),
          maxDate: DateTime(2010, 1, 1),
        ),
        DateTime.utc(2000, 6, 15),
      );
      expect(
        await confirm(
          initialDate: DateTime(2050, 1, 1),
          minDate: DateTime(2000, 6, 15),
          maxDate: DateTime(2010, 1, 1),
        ),
        DateTime.utc(2010, 1, 1),
      );
    });

    testWidgets('a time of day or timezone in value never shifts the day', (
      tester,
    ) async {
      DateTime? result;
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(
            value: DateTime.utc(2026, 3, 1, 23, 59),
            onChanged: (v) => result = v,
          ),
        ),
      );
      expect(find.text('1 March 2026'), findsOneWidget);
      await openPicker(tester);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, DateTime.utc(2026, 3, 1));
    });

    testWidgets('clear button resets to null without opening the picker', (
      tester,
    ) async {
      final calls = <DateTime?>[];
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(
            value: DateTime.utc(2026, 10, 5),
            onChanged: calls.add,
          ),
        ),
      );
      expect(_closeIcon(), findsOneWidget);
      await tester.tap(_closeIcon());
      await tester.pumpAndSettle();
      expect(calls, [null]);
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets(
      'clear button is hidden when empty, not clearable or disabled',
      (tester) async {
        Widget field({
          DateTime? value,
          bool clearable = true,
          bool enabled = true,
        }) => SizedBox(
          width: 320,
          child: SynkDateField(
            value: value,
            clearable: clearable,
            enabled: enabled,
            onChanged: (_) {},
          ),
        );
        final date = DateTime.utc(2026, 10, 5);
        await _pump(tester, field());
        expect(_closeIcon(), findsNothing);
        await _pump(tester, field(value: date, clearable: false));
        expect(_closeIcon(), findsNothing);
        await _pump(tester, field(value: date, enabled: false));
        expect(_closeIcon(), findsNothing);
        await _pump(tester, field(value: date));
        expect(_closeIcon(), findsOneWidget);
      },
    );

    testWidgets('disabled field is dimmed and does not open', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(value: null, enabled: false, onChanged: (_) {}),
        ),
      );
      await tester.tap(find.byType(SynkFieldSurface));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(SynkFieldSurface),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.5);
    });

    testWidgets('pressed field dims to 85%', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(value: null, onChanged: (_) {}),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SynkFieldSurface)),
      );
      await tester.pump();
      double opacity() => tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(SynkFieldSurface),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(opacity(), 0.85);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(opacity(), 1);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('semantics: placeholder, then "<placeholder>, <value>"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(value: null, onChanged: (_) {}),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pick a day')),
        isSemantics(
          label: 'Pick a day',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkDateField(
            value: DateTime.utc(2026, 10, 5),
            placeholder: 'Together since',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Together since, 5 October 2026'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Clear'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('survives text scale 1.3 and a narrow width', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 200,
          child: SynkDateField(
            value: DateTime.utc(2026, 9, 28),
            onChanged: (_) {},
          ),
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SynkBirthdayField', () {
    DateTime now() => DateTime(2026, 10, 5, 9);

    testWidgets('default placeholder and Android picker initial 2000-01-01', (
      tester,
    ) async {
      DateTime? result;
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkBirthdayField(
            value: null,
            now: now,
            onChanged: (v) => result = v,
          ),
        ),
      );
      expect(find.text('Add your birthday'), findsOneWidget);
      await tester.tap(find.byType(SynkFieldSurface));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, DateTime.utc(2000, 1, 1));
    });

    testWidgets(
      'initial is clamped to the newest allowed day for young ranges',
      (tester) async {
        DateTime? result;
        await _pump(
          tester,
          SizedBox(
            width: 320,
            child: SynkBirthdayField(
              value: null,
              now: () => DateTime(2004, 6, 1),
              onChanged: (v) => result = v,
            ),
          ),
        );
        await tester.tap(find.byType(SynkFieldSurface));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        // today - 5y - 1 day = 1999-05-31
        expect(result, DateTime.utc(1999, 5, 31));
      },
    );

    testWidgets('initial is clamped to the oldest allowed day', (tester) async {
      DateTime? result;
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkBirthdayField(
            value: null,
            now: () => DateTime(2130, 1, 1),
            onChanged: (v) => result = v,
          ),
        ),
      );
      await tester.tap(find.byType(SynkFieldSurface));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, DateTime.utc(2010, 1, 1));
    });

    testWidgets('an existing value is shown and reopens on that day', (
      tester,
    ) async {
      DateTime? result;
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkBirthdayField(
            value: DateTime.utc(1994, 7, 21),
            now: now,
            onChanged: (v) => result = v,
          ),
        ),
      );
      expect(find.text('21 July 1994'), findsOneWidget);
      await tester.tap(find.byType(SynkFieldSurface).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, DateTime.utc(1994, 7, 21));
    });

    testWidgets('can be cleared and can be disabled', (tester) async {
      final values = <DateTime?>[];
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkBirthdayField(
            value: DateTime.utc(1994, 7, 21),
            now: now,
            onChanged: values.add,
          ),
        ),
      );
      await tester.tap(_closeIcon());
      await tester.pump();
      expect(values, [null]);

      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkBirthdayField(
            value: DateTime.utc(1994, 7, 21),
            enabled: false,
            now: now,
            onChanged: values.add,
          ),
        ),
      );
      expect(_closeIcon(), findsNothing);
    });
  });

  group('SynkTimeField', () {
    testWidgets('shows h:mm a by default and HH:mm when 24h', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkTimeField(
            value: const TimeOfDay(hour: 20, minute: 0),
            use24h: false,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('8:00 PM'), findsOneWidget);
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkTimeField(
            value: const TimeOfDay(hour: 20, minute: 0),
            use24h: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('20:00'), findsOneWidget);
    });

    testWidgets('follows the device 24-hour setting when use24h is null', (
      tester,
    ) async {
      Widget field(bool alwaysUse24h) => Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: alwaysUse24h),
          child: SizedBox(
            width: 320,
            child: SynkTimeField(
              value: const TimeOfDay(hour: 7, minute: 5),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await _pump(tester, field(true));
      expect(find.text('07:05'), findsOneWidget);
      await _pump(tester, field(false));
      expect(find.text('7:05 AM'), findsOneWidget);
    });

    testWidgets('empty field shows the placeholder and a clock icon', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkTimeField(value: null, onChanged: (_) {}),
        ),
      );
      expect(find.text('Pick a time'), findsOneWidget);
      expect(
        tester.widget<SynkIcon>(find.byType(SynkIcon)).icon,
        SynkIcons.clock,
      );
    });

    testWidgets('opens the time picker on 20:00 when empty', (tester) async {
      TimeOfDay? result;
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkTimeField(
            value: null,
            use24h: false,
            onChanged: (v) => result = v,
          ),
        ),
      );
      await tester.tap(find.byType(SynkFieldSurface));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, const TimeOfDay(hour: 20, minute: 0));
    });

    testWidgets(
      'picker starts on the current value and cancel changes nothing',
      (tester) async {
        final values = <TimeOfDay?>[];
        await _pump(
          tester,
          SizedBox(
            width: 320,
            child: SynkTimeField(
              value: const TimeOfDay(hour: 6, minute: 45),
              use24h: true,
              onChanged: values.add,
            ),
          ),
        );
        await tester.tap(find.byType(SynkFieldSurface).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(values, isEmpty);

        await tester.tap(find.byType(SynkFieldSurface).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(values, [const TimeOfDay(hour: 6, minute: 45)]);
      },
    );

    testWidgets('clear resets, disabled blocks everything', (tester) async {
      final values = <TimeOfDay?>[];
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkTimeField(
            value: const TimeOfDay(hour: 6, minute: 45),
            onChanged: values.add,
          ),
        ),
      );
      await tester.tap(_closeIcon());
      await tester.pump();
      expect(values, [null]);

      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: SynkTimeField(
            value: const TimeOfDay(hour: 6, minute: 45),
            enabled: false,
            onChanged: values.add,
          ),
        ),
      );
      expect(_closeIcon(), findsNothing);
      await tester.tap(find.byType(SynkFieldSurface));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsNothing);
    });
  });

  group('SynkSwitch', () {
    Widget sw({
      bool value = false,
      ValueChanged<bool>? onChanged,
      bool enabled = true,
      EdgeInsets hitSlop = const EdgeInsets.all(6),
      String? label,
    }) => SynkSwitch(
      value: value,
      onChanged: onChanged,
      enabled: enabled,
      hitSlop: hitSlop,
      semanticLabel: label,
    );

    Container track(WidgetTester tester) => tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SynkSwitch),
            matching: find.byType(Container),
          )
          .first,
    );

    testWidgets('tap reports the toggled value', (tester) async {
      final values = <bool>[];
      await _pump(tester, sw(onChanged: values.add));
      await tester.tap(find.byType(SynkSwitch));
      expect(values, [true]);
      await _pump(tester, sw(value: true, onChanged: values.add));
      await tester.tap(find.byType(SynkSwitch));
      expect(values, [true, false]);
    });

    testWidgets('disabled and onChanged == null are inert and dimmed', (
      tester,
    ) async {
      final values = <bool>[];
      await _pump(tester, sw(enabled: false, onChanged: values.add));
      await tester.tap(find.byType(SynkSwitch));
      expect(values, isEmpty);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(SynkSwitch),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.5,
      );
      await _pump(tester, sw());
      await tester.tap(find.byType(SynkSwitch));
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(SynkSwitch),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.5,
      );
    });

    testWidgets('enabled switch is fully opaque', (tester) async {
      await _pump(tester, sw(onChanged: (_) {}));
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(SynkSwitch),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        1,
      );
    });

    testWidgets('geometry: 51x31 track, 27dp knob, 2dp inset, 6dp slop', (
      tester,
    ) async {
      await _pump(tester, sw(onChanged: (_) {}));
      expect(tester.getSize(find.byType(SynkSwitch)), const Size(63, 43));
      final trackBox = find.descendant(
        of: find.byType(SynkSwitch),
        matching: find.byType(Container),
      );
      expect(tester.getSize(trackBox.first), const Size(51, 31));
      expect(tester.getSize(trackBox.last), const Size(27, 27));
      final knobLeft =
          tester.getTopLeft(trackBox.last).dx -
          tester.getTopLeft(trackBox.first).dx;
      final knobTop =
          tester.getTopLeft(trackBox.last).dy -
          tester.getTopLeft(trackBox.first).dy;
      expect(knobLeft, 2);
      expect(knobTop, 2);

      await _pump(tester, sw(hitSlop: EdgeInsets.zero, onChanged: (_) {}));
      expect(tester.getSize(find.byType(SynkSwitch)), const Size(51, 31));
    });

    testWidgets('6dp hit slop around the track toggles', (tester) async {
      final values = <bool>[];
      await _pump(tester, sw(onChanged: values.add));
      final origin = tester.getTopLeft(find.byType(SynkSwitch));
      await tester.tapAt(origin + const Offset(1, 21));
      expect(values, [true]);
    });

    testWidgets('colours: primary when on, switchTrackOff when off', (
      tester,
    ) async {
      await _pump(tester, sw(onChanged: (_) {}));
      expect(
        (track(tester).decoration! as BoxDecoration).color,
        light.switchTrackOff,
      );
      await _pump(tester, sw(value: true, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect((track(tester).decoration! as BoxDecoration).color, light.primary);
    });

    testWidgets('knob is white with a shadow', (tester) async {
      await _pump(tester, sw(onChanged: (_) {}));
      final knob = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SynkSwitch),
              matching: find.byType(Container),
            )
            .last,
      );
      final decoration = knob.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFFFFF));
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('knob slides 20dp over 220ms', (tester) async {
      await _pump(tester, sw(onChanged: (_) {}));
      double knobLeft() => tester
          .widget<Positioned>(
            find.descendant(
              of: find.byType(SynkSwitch),
              matching: find.byType(Positioned),
            ),
          )
          .left!;
      expect(knobLeft(), 2);
      await tester.pumpWidget(
        synkApp(
          Align(
            alignment: Alignment.topLeft,
            child: sw(value: true, onChanged: (_) {}),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 110));
      expect(knobLeft(), inExclusiveRange(2, 22));
      await tester.pump(const Duration(milliseconds: 130));
      expect(knobLeft(), closeTo(22, 0.01));
    });

    testWidgets('semantics: toggled state, enabled flag and label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        sw(value: true, onChanged: (_) {}, label: 'Show on leaderboard'),
      );
      expect(
        tester.getSemantics(find.byType(SynkSwitch)),
        isSemantics(
          label: 'Show on leaderboard',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await _pump(
        tester,
        sw(value: false, enabled: false, label: 'Show on leaderboard'),
      );
      expect(
        tester.getSemantics(find.byType(SynkSwitch)),
        isSemantics(
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('mirrors in RTL', (tester) async {
      useGoldenViewport(tester);
      await tester.pumpWidget(
        synkApp(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.topLeft,
              child: sw(value: false, onChanged: (_) {}),
            ),
          ),
        ),
      );
      final trackBox = find.descendant(
        of: find.byType(SynkSwitch),
        matching: find.byType(Container),
      );
      // Off sits at the start edge, which is the right edge in RTL.
      expect(
        tester.getTopRight(trackBox.last).dx,
        tester.getTopRight(trackBox.first).dx - 2,
      );
    });
  });

  group('golden state sheets', () {
    testWidgets('text fields', (tester) async {
      final filled = TextEditingController(text: 'Ravi Kumar');
      final multi = TextEditingController(
        text: 'Friday movie night!\nBring snacks and a blanket.',
      );
      final searching = TextEditingController(text: 'weekend');
      addTearDown(filled.dispose);
      addTearDown(multi.dispose);
      addTearDown(searching.dispose);
      await expectStateSheetGolden(
        tester,
        'inputs_text_fields',
        [
          const GoldenCell('empty with hint', SynkTextField(hint: 'Your name')),
          GoldenCell(
            'filled',
            SynkTextField(controller: filled, hint: 'Your name'),
          ),
          const GoldenCell(
            'focused (autofocus)',
            SynkTextField(hint: 'Group name', autofocus: true),
          ),
          const GoldenCell(
            'error',
            SynkTextField(
              hint: 'Email',
              errorText: 'Enter a valid email address',
            ),
          ),
          const GoldenCell(
            'helper',
            SynkTextField(
              hint: 'Birthday',
              helperText: 'Friends get a reminder on the day.',
            ),
          ),
          const GoldenCell(
            'disabled (identical to enabled)',
            SynkTextField(hint: 'Locked field', enabled: false),
          ),
          GoldenCell(
            'multiline (min 3, max 5)',
            SynkTextField(
              controller: multi,
              minLines: 3,
              maxLines: 5,
              hint: 'Say something',
            ),
          ),
          GoldenCell(
            'leading + trailing',
            SynkTextField(
              controller: searching,
              hint: 'Search',
              leading: const _Glyph(SynkIcons.search),
              trailing: const _Glyph(SynkIcons.close),
            ),
          ),
          const GoldenCell(
            'obscured',
            SynkTextField(hint: 'Password', obscureText: true),
          ),
          GoldenCell(
            'glass on pastel gradient (empty / filled / error)',
            _PastelBackdrop(
              child: Column(
                children: [
                  const SynkTextField(
                    variant: SynkInputVariant.glass,
                    hint: 'Invite by email',
                  ),
                  const SizedBox(height: 10),
                  SynkTextField(
                    variant: SynkInputVariant.glass,
                    controller: filled,
                    leading: const _Glyph(SynkIcons.mail),
                  ),
                  const SizedBox(height: 10),
                  const SynkTextField(
                    variant: SynkInputVariant.glass,
                    hint: 'Code',
                    errorText: 'Invalid code',
                  ),
                ],
              ),
            ),
          ),
        ],
        size: const Size(420, 1100),
        cellWidth: 388,
      );
    });

    testWidgets('date and time fields', (tester) async {
      await expectStateSheetGolden(
        tester,
        'inputs_date_time',
        [
          GoldenCell(
            'date: empty',
            SynkDateField(value: null, onChanged: (_) {}),
          ),
          GoldenCell(
            'date: filled, clearable',
            SynkDateField(value: DateTime.utc(2026, 10, 5), onChanged: (_) {}),
          ),
          GoldenCell(
            'date: filled, not clearable',
            SynkDateField(
              value: DateTime.utc(2026, 1, 28),
              clearable: false,
              placeholder: 'Together since (optional)',
              onChanged: (_) {},
            ),
          ),
          GoldenCell(
            'date: disabled empty / filled',
            Column(
              children: [
                SynkDateField(value: null, enabled: false, onChanged: (_) {}),
                const SizedBox(height: 8),
                SynkDateField(
                  value: DateTime.utc(2026, 10, 5),
                  enabled: false,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          GoldenCell(
            'birthday: empty',
            SynkBirthdayField(value: null, onChanged: (_) {}),
          ),
          GoldenCell(
            'birthday: filled',
            SynkBirthdayField(
              value: DateTime.utc(1994, 7, 21),
              onChanged: (_) {},
            ),
          ),
          GoldenCell(
            'time: empty',
            SynkTimeField(value: null, onChanged: (_) {}),
          ),
          GoldenCell(
            'time: 12h / 24h',
            Column(
              children: [
                SynkTimeField(
                  value: const TimeOfDay(hour: 20, minute: 0),
                  use24h: false,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 8),
                SynkTimeField(
                  value: const TimeOfDay(hour: 20, minute: 0),
                  use24h: true,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          GoldenCell(
            'time: disabled',
            SynkTimeField(
              value: const TimeOfDay(hour: 7, minute: 30),
              enabled: false,
              use24h: false,
              onChanged: (_) {},
            ),
          ),
        ],
        size: const Size(420, 880),
        cellWidth: 388,
      );
    });

    // The stock pickers draw Material icons; flutter_test only loads the app fonts.
    setUpAll(() async {
      final loader = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await loader.load();
    });

    for (final brightness in [Brightness.light, Brightness.dark]) {
      final suffix = brightness == Brightness.dark ? 'dark' : 'light';

      testWidgets('open date picker ($suffix)', (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 320,
            child: SynkBirthdayField(
              value: DateTime.utc(2000, 1, 15),
              now: () => DateTime(2026, 10, 5),
              onChanged: (_) {},
            ),
          ),
          brightness: brightness,
        );
        await tester.tap(find.byType(SynkFieldSurface).first);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/inputs_date_picker_$suffix.png'),
        );
      });

      testWidgets('open time picker ($suffix)', (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 320,
            child: SynkTimeField(
              value: const TimeOfDay(hour: 20, minute: 0),
              use24h: false,
              onChanged: (_) {},
            ),
          ),
          brightness: brightness,
        );
        await tester.tap(find.byType(SynkFieldSurface).first);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/inputs_time_picker_$suffix.png'),
        );
      });
    }

    testWidgets('switches', (tester) async {
      Widget row(String label, Widget control) => Builder(
        builder: (context) {
          final colors = context.colors;
          return Container(
            width: 388,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: colors.foreground),
                  ),
                ),
                control,
              ],
            ),
          );
        },
      );
      await expectStateSheetGolden(
        tester,
        'inputs_switch',
        [
          GoldenCell(
            'off / on',
            Row(
              children: [
                SynkSwitch(value: false, onChanged: (_) {}),
                const SizedBox(width: 12),
                SynkSwitch(value: true, onChanged: (_) {}),
              ],
            ),
          ),
          GoldenCell(
            'disabled off / on',
            Row(
              children: [
                SynkSwitch(value: false, enabled: false, onChanged: (_) {}),
                const SizedBox(width: 12),
                SynkSwitch(value: true, enabled: false, onChanged: (_) {}),
                const SizedBox(width: 12),
                const SynkSwitch(value: true),
              ],
            ),
          ),
          GoldenCell(
            'in a settings row (no slop)',
            Column(
              children: [
                row(
                  'Show on weekly leaderboard',
                  SynkSwitch(
                    value: true,
                    hitSlop: EdgeInsets.zero,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(height: 8),
                row(
                  'Movie night reminders',
                  SynkSwitch(
                    value: false,
                    hitSlop: EdgeInsets.zero,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ],
        size: const Size(420, 300),
        cellWidth: 388,
      );
    });

    testWidgets('fields at text scale 1.3', (tester) async {
      final filled = TextEditingController(text: 'Ravi Kumar');
      addTearDown(filled.dispose);
      await expectStateSheetGolden(
        tester,
        'inputs_scale13',
        [
          GoldenCell(
            'text field',
            SynkTextField(controller: filled, hint: 'Your name'),
          ),
          const GoldenCell(
            'error + helper',
            Column(
              children: [
                SynkTextField(
                  hint: 'Email',
                  errorText: 'Enter a valid email address, please',
                ),
                SizedBox(height: 8),
                SynkTextField(
                  hint: 'Birthday',
                  helperText: 'Friends get a reminder on the day. Only the day and month are shared.',
                ),
              ],
            ),
          ),
          GoldenCell(
            'date / time',
            Column(
              children: [
                SynkDateField(
                  value: DateTime.utc(2026, 9, 28),
                  onChanged: (_) {},
                ),
                const SizedBox(height: 8),
                SynkBirthdayField(value: null, onChanged: (_) {}),
                const SizedBox(height: 8),
                SynkTimeField(
                  value: const TimeOfDay(hour: 20, minute: 0),
                  use24h: false,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ],
        size: const Size(420, 560),
        cellWidth: 388,
        textScale: 1.3,
      );
    });
  });
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.icon);

  final SynkIcons icon;

  @override
  Widget build(BuildContext context) => SynkIcon(
    icon,
    size: 18,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

/// Pastel gradient (theme tokens) behind translucent glass fields.
class _PastelBackdrop extends StatelessWidget {
  const _PastelBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [colors.periwinkle, colors.chartPink]),
      ),
      child: child,
    );
  }
}
