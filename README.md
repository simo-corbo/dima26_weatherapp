# weather_app — Flutter lab track (Mobile App Design)

A small weather app (OpenWeather API, frosted-glass design) built incrementally across
**five lab sessions** plus two optional self-study extensions. The repository grows week
by week: each session adds that lesson's code and its notes in `docs/`.

## Lessons

| Session | Topic |
|--------:|-------|
| 1 | Stateless widgets — tokens, composition, the static Home screen |
| 2 | Stateful widgets — controllers, lifecycle, `http` + `FutureBuilder` |
| 3 | Navigation — multi-screen project, tabs, `Navigator`, lifting state up |
| 4 | Bloc/Cubit — app-wide state, persistence, notifications & location |
| 5 | Adaptive & theming — landscape/tablet layouts, dark theme |
| — | Production craft (self-study) — animations, custom painters, caching, launcher icon |
| — | Cloud sync (self-study) — Firebase anonymous auth + Firestore, the repository swap |

## Running

```bash
flutter pub get
flutter run
```

From lesson 2 the app calls OpenWeather. Put your API key in `dart_define.json`
(git-ignored) and run with `flutter run --dart-define-from-file=dart_define.json`,
or replace the `YOUR_OPENWEATHER_API_KEY` placeholder locally — never commit a real key.

For the optional cloud-sync extension, create a Firebase project and run
`flutterfire configure`; without it the app detects the missing config and falls back to
local-only persistence.

## Design contract

Open `weather_design_contract.html` in a browser. Every lesson builds to it.
