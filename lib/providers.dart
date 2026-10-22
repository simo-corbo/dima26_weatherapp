// LAB 4: the shared state of the app, with Riverpod.
//
// Until Lab 3 the shared values lived in a widget's State (HomeScreen, then WeatherApp)
// and travelled with constructors (data down) and callbacks (events up).
// Here they live outside the widget tree, in providers:
// - a Notifier keeps a value and the operations that change it (the controller);
// - a Provider gives access to it to any widget (the access point).
// A widget reads a provider with ref.watch (and rebuilds when it changes)
// and changes it with ref.read(...notifier) (without rebuilding).

import 'package:dima26_weatherapp/weather_api.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The repository: the class that talks to the server.
// WeatherService (weather_api.dart, Lab 3) already is one: http and JSON stay there, not in the widgets.
// The provider creates it once and gives it to whoever needs it.
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// The settings. An immutable model: we never change a field,
// we create a new Settings with copyWith (a copy with one value changed).
class Settings {
  final bool celsius; // true = °C, false = °F
  final bool kmh;     // true = km/h, false = mph
  final ThemeMode themeMode; // system (follow the phone), light or dark
  const Settings({required this.celsius, required this.kmh, required this.themeMode});

  Settings copyWith({bool? celsius, bool? kmh, ThemeMode? themeMode}) {
    return Settings(
      celsius: celsius ?? this.celsius, // ?? : the new value if given, else the old one
      kmh: kmh ?? this.kmh,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

// The Notifier: it keeps the Settings (in `state`) and the operations that change them.
class SettingsNotifier extends Notifier<Settings> {
  // build() gives the starting value. Riverpod calls it the first time someone reads the provider.
  // The theme starts as ThemeMode.system: MaterialApp follows the phone's own setting, live.
  @override
  Settings build() {
    return const Settings(celsius: true, kmh: true, themeMode: ThemeMode.system);
  }

  // Assigning `state` replaces setState(): every widget that watches this provider rebuilds.
  void setCelsius(bool celsius) => state = state.copyWith(celsius: celsius);
  void setKmh(bool kmh) => state = state.copyWith(kmh: kmh);
  void setThemeMode(ThemeMode themeMode) => state = state.copyWith(themeMode: themeMode);
}

// The Provider: the access point. Any widget can ref.watch(settingsProvider).
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

// The saved cities: Home (the heart) and Saved (the list) both need them.
class SavedCitiesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {}; // no saved city at the start

  // toggles the heart of a city. We build a NEW set and assign it:
  // changing the old set with add() would not tell Riverpod that something changed.
  void toggle(String city) {
    final updated = Set<String>.from(state); // a copy of the saved cities
    if (updated.contains(city)) {
      updated.remove(city); // it was saved: remove it
    } else {
      updated.add(city);    // it wasn't saved: add it
    }
    state = updated; // most important part! triggers the notification 
  }
}

final savedCitiesProvider = NotifierProvider<SavedCitiesNotifier, Set<String>>(SavedCitiesNotifier.new);

// ---------------------------------------------------------------------------
// The weather. It arrives later, so it is asynchronous: its value is an AsyncValue
// (loading, data or error). We only read it, we never change it: no operations,
// so instead of an AsyncNotifier we use a FutureProvider, its read-only sibling.
//
// .family: one provider for each city. currentWeatherProvider('Oslo') and
// currentWeatherProvider('Milano') are two different providers, each with its own value.
// Riverpod keeps them: asking again for Oslo gives back the same weather, no new request
// (this replaces the Map of Futures and putIfAbsent of Lab 3).
final currentWeatherProvider = FutureProvider.family<Weather, String>((ref, city) {
  return ref.watch(weatherServiceProvider).fetchCurrent(city);
});

final forecastProvider = FutureProvider.family<List<DayForecast>, String>((ref, city) {
  return ref.watch(weatherServiceProvider).fetchForecast(city);
});
