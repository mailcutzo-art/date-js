import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:date_js/design_system/foundation/synk_haptics.dart';
import 'package:date_js/design_system/tokens/synk_colors.dart';
import 'package:date_js/design_system/tokens/synk_theme.dart';
import 'package:date_js/design_system/tokens/synk_typography.dart';

/// Wraps [child] in the Synkly theme inside a MaterialApp (Navigator + Overlay available).
Widget synkApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  Color? background,

  /// Leaves the platform's "remove animations" setting off (the default is on, so goldens and
  /// transitions are deterministic): for widgets whose looks differ with motion, like spinners.
  bool animations = false,

  /// Who plays the haptics for everything in the app, routes included (a recorder in tests that
  /// check them).
  SynkHapticsPlayer haptics = const NoopHaptics(),
}) {
  final colors = brightness == Brightness.dark
      ? SynkColors.dark
      : SynkColors.light;
  return SynkHapticsScope(
    player: haptics,
    child: MaterialApp(
      // A fresh app per brightness: reusing one would cross-fade the theme over 200 ms.
      key: ValueKey<Brightness>(brightness),
      debugShowCheckedModeBanner: false,
      theme: SynkThemeData.light,
      darkTheme: SynkThemeData.dark,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, home) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: !animations,
        ),
        child: home!,
      ),
      home: Scaffold(
        backgroundColor: background ?? colors.background,
        body: child,
      ),
    ),
  );
}

/// Sets a fixed logical size + 2x pixel ratio so goldens are crisp and identical everywhere.
void useGoldenViewport(
  WidgetTester tester, {
  Size size = const Size(420, 800),
}) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// One labelled cell of a state sheet.
class GoldenCell {
  const GoldenCell(this.label, this.child);
  final String label;
  final Widget child;
}

/// A column of labelled cells, rendered once per theme brightness by [pumpStateSheet].
class StateSheet extends StatelessWidget {
  const StateSheet({
    required this.cells,
    this.cellWidth,
    this.spacing = 16,
    super.key,
  });

  final List<GoldenCell> cells;
  final double? cellWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final cell in cells)
            SizedBox(
              width: cellWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cell.label,
                    style: SynkTypography.of(SynkTextVariant.caption)
                        .copyWith(color: colors.mutedForeground, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  cell.child,
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders [cells] and compares against `goldens/<name>_<light|dark>.png` (relative to the test).
Future<void> expectStateSheetGolden(
  WidgetTester tester,
  String name,
  List<GoldenCell> cells, {
  Size size = const Size(420, 800),
  double? cellWidth,
  double textScale = 1.0,
  bool darkToo = true,
}) async {
  for (final brightness in [Brightness.light, if (darkToo) Brightness.dark]) {
    useGoldenViewport(tester, size: size);
    await tester.pumpWidget(
      synkApp(
        StateSheet(cells: cells, cellWidth: cellWidth),
        brightness: brightness,
        textScale: textScale,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final suffix = brightness == Brightness.dark ? 'dark' : 'light';
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/${name}_$suffix.png'),
    );
  }
}

/// Decodes every [Image] on screen before a golden is captured. Widget tests do not wait for an
/// asset or network image, so a picture would otherwise be missing from the capture.
Future<void> loadImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
}
