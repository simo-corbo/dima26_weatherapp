# Lab 9 — the weather app in Kotlin (Android, Jetpack Compose)

This is the `kotlin` branch of the course repository. The Flutter app (Labs 1–5) is on `main`, the
React Native app (Labs 6–8) on `react-native`; this branch holds only the native Android version,
with its own history.

Lab 9 rebuilds, in Kotlin with Jetpack Compose, everything the app does without the outside world:
the Home screen (city, big icon, temperature, two chips), the tabs, the hearts, the city picker
(a list, or type a city), Settings (°C/°F, km/h/mph), a screen for each saved city, two panes
on a wide screen, a night sky when the phone is in dark mode, and English or Italian texts.
The weather is still invented: real data, saving, location, notifications and tests come in Lab 10.

## What you need

- **Android Studio** (https://developer.android.com/studio). It brings everything else: the Android
  SDK, Gradle, a Java runtime and the emulator.
- An **emulator** (Android Studio → Device Manager → a Pixel phone) or your own **Android phone**
  with *USB debugging* on (Settings → About phone → tap *Build number* 7 times → Developer options).
- The app runs only on Android: there is no iOS version of this branch.

## Run it

```bash
git clone -b kotlin --single-branch https://github.com/simo-corbo/dima26_weatherapp.git weather_kotlin
```

1. Android Studio → **Open** → choose the `weather_kotlin` folder (the one with `settings.gradle.kts`).
2. Wait for the **Gradle sync** at the bottom: the first time it downloads Gradle and the libraries
   (a few minutes). If Android Studio asks to install a missing SDK platform (Android 37), accept.
3. Pick a device in the toolbar and press **Run ▶** (Ctrl+R / ⌃R). Android Studio builds the APK,
   installs it on the device and starts it.

From a terminal the same build is `./gradlew assembleDebug` (the APK lands in
`app/build/outputs/apk/debug/`), and `./gradlew installDebug` installs it on the running device.

**Edit and see it change:** with *Live Edit* (Settings → Editor → Live Edit), changes to a composable
reach the running app without Run. Bigger changes (a new parameter, a new file) need Run again. Each `@Preview` function
is also drawn in the editor: open a file and choose **Split** in the top right corner.

## The files

| File | What it holds | In Flutter | In React Native |
|---|---|---|---|
| `app/src/main/AndroidManifest.xml` | the app's name, icon, and its activity (the one the icon opens) | `AndroidManifest.xml` | `app.json` |
| `app/build.gradle.kts` | how to build the app: SDK versions, libraries | `pubspec.yaml` | `package.json` |
| `gradle/libs.versions.toml` | the versions of every library, in one place | `pubspec.yaml` | `package.json` |
| `MainActivity.kt` | the activity, and `WeatherApp`: the shared state and the routes | `main()` + `MaterialApp` | `_layout.tsx` |
| `WeatherViewModel.kt` | the state shared by the screens: city, saved cities, units | Riverpod providers | `state.tsx` |
| `HomeScreen.kt` | the first screen: tabs, card, saved list, two panes when wide | `HomeScreen` | `index.tsx` |
| `PickerScreen.kt`, `SettingsScreen.kt`, `CityScreen.kt` | the three screens pushed on top | the pushed screens | `picker.tsx`, `settings.tsx`, `city/[name].tsx` |
| `Components.kt` | the pieces: GlassCard, InfoChip, WeatherCard, lists, bars | the widgets | `components.tsx` |
| `DesignTokens.kt` | colours, gradient, text styles of the design contract | `design_tokens.dart` | `designTokens.ts` |

The Kotlin files are in `app/src/main/java/com/example/weather/` (the folder follows the package name).
`res/` holds what isn't code: every text (`values/strings.xml`, in Italian `values-it/strings.xml`),
the icon (`mipmap-*`), the window theme and its night colour (`values-night/`).

**Try the other language and dark mode:** set the phone to Italian, or only this app (Android 13+:
Settings → Apps → Weather → Language); turn on dark mode in the phone's display settings.

## If it doesn't work

- **"SDK location not found":** open the project from Android Studio once: it writes `local.properties`
  with the path of your SDK (that file is personal and is not committed).
- **"Minimum supported Gradle version" / plugin errors after updating Android Studio:** let Android
  Studio's *AGP Upgrade Assistant* update the project, or ask before changing versions: the libraries
  are pinned to work with Android 37.
- **The emulator is slow or black:** Device Manager → the device's menu → *Cold Boot Now*.
