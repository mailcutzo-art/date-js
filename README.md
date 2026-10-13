# date-js

Flutter app (to become a dating app), bootstrapped from the Synkly app's design system and base setup.

## Stack

- Flutter 3.47.6 (`.fvmrc` / `.flutter-version`), Dart ^3.13.5
- State: `flutter_riverpod`, routing: `go_router`
- Design system in `lib/design_system` (tokens, theme, icons, 37 components) with Manrope fonts

## Layout

```
lib/
  main.dart / bootstrap.dart / app.dart   entry, error hooks, root MaterialApp.router
  app/router, app/shell                   routes, app-wide shell (toasts)
  core/config, core/utils                 EnvConfig (--dart-define), AppLogger
  design_system/                          copied from Synkly (Synk* components)
  features/home                           placeholder screen
test/
  design_system/                          component + golden tests
  app/                                    app smoke test
```

## Commands

```
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=APP_ENV=development
```

Android/iOS ids use `com.datejs.date_js`; change them (and the `name` in `pubspec.yaml`) when the product is named.
