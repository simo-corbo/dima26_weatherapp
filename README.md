# weather_app — DIMA lab track (Mobile App Design)

A small weather app (OpenWeather API, frosted-glass design) built lab by lab. It is first built in
**Flutter** (Labs 1–5), and from Lab 6 the same app is built again in **React Native**. Each lab adds that lesson's
code; the slides are shared separately.

- branch **`main`**: the Flutter app (Labs 1–5);
- branch **`react-native`**: the React Native app (from Lab 6), a separate Expo project with its own history.

## Labs

| Lab | Framework | Topic | Code |
|----:|-----------|-------|------|
| 1 | Flutter | Stateless widgets: tokens, composition, the static Home screen | `lib/mainlab1.dart` |
| 2 | Flutter | Stateful widgets, navigation stack, returning data, tabs | `lib/mainlab2.dart` (+ `_navbar`, `_drawer` variants) |
| 3 | Flutter | Lifting state up, REST API, JSON, `FutureBuilder` | `lib/mainlab3.dart`, `lib/weather_api.dart` |
| 4 | Flutter | Riverpod (shared state, dark mode), responsive and adaptive layouts | `lib/mainlab4.dart`, `lib/providers.dart` |
| 5 | Flutter | Saving to a file, English/Italian, location, a daily reminder, tests, a recap of the whole app with UML | `lib/main.dart` and the files below |
| 6 | React Native | Expo, components, JSX, props, styles, Flexbox, safe areas: the Lab 1 screen again | branch `react-native` |

Lab 5's code is the current Flutter app: `lib/main.dart`, `lib/providers.dart`,
`lib/storage.dart`, `lib/location.dart`, `lib/notifications.dart`, the texts in `lib/l10n/` and
the tests in `test/`. Its comments are marked `// LAB 5:`.

## Running the Flutter app

```bash
flutter pub get
flutter run --dart-define-from-file=dart_define.json
```

From Lab 3 the app calls OpenWeather. Put your API key in `dart_define.json` (git-ignored; copy
`dart_define.example.json`). VS Code passes it for you through `.vscode/launch.json`. Never commit a real key.

To run an older lab, run its file: `flutter run -t lib/mainlab2.dart`.

Tests (Lab 5): `flutter test` (16 tests, about a second; no API key or network needed).

## Running the React Native app (Lab 6)

```bash
git clone -b react-native --single-branch https://github.com/simo-corbo/dima26_weatherapp.git weather_rn
cd weather_rn
npm install
npx expo start
```

Then scan the QR code with the **Expo Go** app on your phone, or press `i` (iOS simulator),
`a` (Android emulator) or `w` (web browser). The step-by-step guide, for people who have never used
React Native, is the README of the `react-native` branch.

## Design contract

Open `weather_design_contract.html` in a browser. Every lab builds to it: the React Native app uses
the same colours and sizes (`designTokens.ts` on the `react-native` branch mirrors `lib/design_tokens.dart`).
