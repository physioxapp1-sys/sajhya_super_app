# Sajhya Super App

A Flutter implementation of the Sajhya healthcare super-app landing/home screen, structured as a complete Flutter project so it can be built entirely on [Codemagic](https://codemagic.io) (no local Flutter install required).

## Project structure
- `lib/main.dart` - the landing/home screen UI (search, health summary, services grid, recommendations, bottom nav).
- `assets/` - SVG service icons and `icon.png`, the Sajhya logo (used both in-app and as the app icon).
- `android/` - full native Android project (package `com.sajhya.super_app`).
- `codemagic.yaml` - CI workflow that installs Flutter, generates launcher icons, and builds the release APK/AAB.

## App icon
`assets/icon.png` is used as **both** the adaptive icon foreground and background via `flutter_launcher_icons` (configured in `pubspec.yaml`). Codemagic regenerates all `android/app/src/main/res/mipmap-*` icons from it on every build; fallback icons are already committed so the project also opens cleanly in an IDE.

## Building on Codemagic
1. Push this repository to GitHub/GitLab/Bitbucket and connect it in Codemagic.
2. Codemagic will detect `codemagic.yaml` and run the `android-release` workflow:
   - `flutter pub get`
   - `dart run flutter_launcher_icons` (regenerates the app icon from `assets/icon.png`)
   - `flutter build apk --release`
   - `flutter build appbundle --release`
3. Artifacts (`.apk` and `.aab`) are attached to the build and emailed to the configured recipient.
4. To ship a signed release, add a keystore under Codemagic > Team settings > Code signing identities and uncomment the `android_signing` block in `codemagic.yaml`.

## Building locally (if Flutter is installed)
```
flutter pub get
dart run flutter_launcher_icons
flutter run
```

## Included in the landing page
- Universal search bar with a camera/scan shortcut
- Sajhya logo + brand header
- "My Health Today" summary card
- 2-column services grid (Shop, Pharmacy, Exercise Videos, Lab Test, Home Visits, Medicine Delivery)
- Recommended content carousel
- Recent activity
- Functional bottom navigation
