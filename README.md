# Lab 6 — the weather app in React Native

This is the `react-native` branch of the course repository. The Flutter app (Labs 1–5) is on
`main`; this branch holds only the React Native version, with its own history.

The Home screen of Lab 1 (city, big icon, temperature, two chips, search field, tab bar),
rebuilt in React Native with Expo. Same sizes, same colours, no state yet: tapping does nothing.
State, navigation and data come in the next labs, exactly as they did in Flutter.

This guide assumes you have never used React Native.

## What React Native is, in one paragraph

React Native lets you write a mobile app in **TypeScript** (JavaScript with types) using **React**,
the library behind many websites. Like Flutter, one codebase gives an iOS and an Android app. The
difference: Flutter draws every pixel itself, while React Native asks iOS and Android to show their
own native views (a `<Text>` becomes a real iOS `UILabel`, a real Android `TextView`).
Instagram, Facebook, Discord, Shopify, Microsoft Office, Tesla and many others use it.

**Expo** is the toolkit the professor's slides use (and the React Native team recommends) to create,
run and build React Native apps without opening Xcode or Android Studio.

## What you need

- **Node.js** (the LTS version, from https://nodejs.org). It brings `npm` and `npx`.
  Check with `node --version`.
- **VS Code** (the same editor as for Flutter). Open this folder (the root of the `react-native` branch).
- One place to run the app (any of these):
  - **your phone** with the free **Expo Go** app (App Store / Google Play). Easiest: no simulator needed.
  - the **iOS simulator** (Mac with Xcode, the one you used for Flutter);
  - an **Android emulator** (Android Studio → Device Manager, the one you used for Flutter);
  - a **web browser** (good for a quick look; it's not the real mobile app).
- No install at all: **Expo Snack** (https://snack.expo.dev) runs React Native in the browser, and on
  your phone through Expo Go. Useful to try the professor's small examples.

## Run it

```bash
git clone -b react-native --single-branch https://github.com/simo-corbo/dima26_weatherapp.git weather_rn
cd weather_rn
npm install          # the first time only: downloads the packages into node_modules/ (like flutter pub get)
npx expo start       # starts the development server (Metro), and prints a QR code
```

Then, in the terminal where Expo is running:

| Press / do | Opens the app on |
|---|---|
| scan the QR code (iPhone: Camera app; Android: Expo Go) | your phone, with Expo Go |
| `i` | the iOS simulator (Expo installs Expo Go there the first time) |
| `a` | the Android emulator (start it from Android Studio first) |
| `w` | the web browser |
| `r` | reload the app |
| `m` | the developer menu |

`npm run ios`, `npm run android` and `npm run web` do the same in one step.

**Edit and see it change:** save a file and the app updates in a second, keeping what's on screen.
It's called *Fast Refresh*: Flutter's hot reload.

### If it doesn't work

- **The phone can't connect / the QR code loads forever:** the phone and the computer must be on the
  same Wi-Fi. University networks often block this: run `npx expo start --tunnel` instead.
- **"Project is incompatible with this version of Expo Go":** this project uses Expo SDK 58. Update
  Expo Go from the store.
- **`a` says no Android device:** open Android Studio → Device Manager and start an emulator, then press `a` again.
- **Something strange after installing a package:** stop Expo (Ctrl+C) and run `npx expo start -c`
  (`-c` clears the cache).

## The files

| File | What it is | In Flutter |
|---|---|---|
| `App.tsx` | the screen (`HomeScreen`) and the app (`App`) | `main.dart` |
| `components.tsx` | the small pieces: `GlassCard`, `InfoChip`, `WeatherIcon`, `WeatherCard`, `SearchField`, `GlassIconButton`, `BottomTabBar` | the widget classes in `main.dart` |
| `designTokens.ts` | colours, the gradient, the text styles | `design_tokens.dart` |
| `index.ts` | starts the app: `registerRootComponent(App)` | `void main() => runApp(...)` |
| `package.json` | the name, the scripts, the packages | `pubspec.yaml` |
| `app.json` | the app's name, icon, orientation, and the Expo plugins | `AndroidManifest.xml`, `Info.plist` |
| `assets/` | icon and splash images | the icons in `android/` and `ios/` |
| `node_modules/` | the downloaded packages (never edit, never commit) | `.dart_tool/`, the pub cache |

There are no `ios/` and `android/` folders: Expo generates them only when a native build needs them.

## From Flutter to React Native

| Flutter | React Native |
|---|---|
| `StatelessWidget` with `build()` | a function that returns JSX: `function WeatherCard(props) { return (...); }` |
| constructor parameters | **props**: `<WeatherCard city="London" temp={12} />` (read-only inside the component) |
| `child:` / `children:` | nesting in JSX: `<GlassCard>...</GlassCard>`, received as `children` |
| `Text('Hi', style: ...)` | `<Text style={...}>Hi</Text>` |
| `Container`, `Padding`, `Opacity`, `DecoratedBox` | one `<View>` with a `style` (padding, backgroundColor, borderRadius, opacity...) |
| `Column` | `<View>` (a column by default) |
| `Row` | `<View style={{ flexDirection: 'row' }}>` |
| `mainAxisAlignment` / `crossAxisAlignment` | `justifyContent` / `alignItems` |
| `Expanded`, `Spacer` | `flex: 1` |
| `SizedBox(height: 12)` | `<View style={{ height: 12 }} />` (or `gap: 12` on the parent) |
| `SafeArea` | `SafeAreaView` from `react-native-safe-area-context` (inside one `SafeAreaProvider`) |
| `LinearGradient` in a `BoxDecoration` | `backgroundImage: 'linear-gradient(...)'` |
| `Icon(Icons.settings)` | `<MaterialIcons name="settings" />` from `@react-native-vector-icons/material-icons` |
| logical pixels | density-independent pixels: numbers without a unit |
| `flutter pub add x` | `npx expo install x` (picks the version that matches our Expo SDK) |
| hot reload | Fast Refresh |

## How this project was created

```bash
npx create-expo-app@latest rn_weather --template blank-typescript   # then moved to the root of this branch
cd rn_weather
npx expo install react-native-safe-area-context @react-native-vector-icons/material-icons expo-font
npx expo install react-dom react-native-web     # only to run it in the browser (w)
```

Checks before committing: `npx tsc --noEmit` (types) and `npx expo lint` (style).

`AGENTS.md` and `.claude/` come from the Expo template: instructions for AI coding assistants.
You can ignore them.
