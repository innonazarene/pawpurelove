# PawureLove 🐾

> Loving care for your furry best friend

A Flutter mobile application for pet care management — track your pet's health, location, schedules, and more all in one place.

---

## Features

- **Pet Profiles** — Create and manage profiles for each of your pets with photo support via image picker and cropper
- **Health Tracking** — Log and visualize your pet's health metrics with interactive charts
- **Location Services** — Track and geocode your pet's location using GPS
- **Notifications** — Schedule reminders for feeding, medication, vet visits, and more
- **Offline Storage** — Persistent local data with shared preferences
- **Map View** — Interactive map to visualize pet locations
- **Data Export** — Export pet records and health data to files

---

## Tech Stack

| Category | Package |
|---|---|
| UI & Fonts | `google_fonts`, `cupertino_icons`, Material Design |
| Charts | `fl_chart` |
| Storage | `shared_preferences`, `path_provider` |
| Location | `geolocator`, `geocoding` |
| Maps | `flutter_map`, `latlong2` |
| Notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Media | `image_picker`, `image_cropper` |
| Utilities | `uuid`, `intl`, `url_launcher`, `file_saver` |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `^3.11.4`
- Dart SDK `^3.11.4`
- Android Studio / VS Code with Flutter extension
- A connected device or emulator

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/pawurelove.git
cd pawurelove

# Install dependencies
flutter pub get

# Generate launcher icons
dart run flutter_launcher_icons

# Generate native splash screen
dart run flutter_native_splash:create

# Run the app
flutter run
```

---

## Building

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS (requires macOS + Xcode)

```bash
flutter build ios --release --no-codesign
```

> **Windows/Linux users:** Use [Codemagic](https://codemagic.io) or GitHub Actions to build iOS remotely. See `.github/workflows/ios.yml`.

### Web

```bash
flutter build web --release
```

---

## CI/CD

This project includes a GitHub Actions workflow for automated iOS builds.

```
.github/
└── workflows/
    └── ios.yml   # Builds iOS on macOS runner, uploads Runner.app artifact
```

Push to `main` or `master` to trigger a build, or run it manually from the **Actions** tab.

---

## Project Structure

```
pawurelove/
├── assets/
│   └── logo.png
├── lib/
│   └── main.dart
├── ios/
├── android/
├── .github/
│   └── workflows/
│       └── ios.yml
└── pubspec.yaml
```

---

## Permissions

The app requires the following permissions:

| Permission | Platform | Purpose |
|---|---|---|
| Location | Android & iOS | GPS tracking for pets |
| Camera / Gallery | Android & iOS | Pet photo uploads |
| Notifications | Android & iOS | Care reminders & alerts |
| Storage | Android | Exporting pet data files |

---

## Version

Current version: **1.0.0** (build 1)

---

## License

This project is private and not published to pub.dev.

---

*Made with love for pets everywhere 🐶🐱*