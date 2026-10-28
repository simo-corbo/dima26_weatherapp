// LAB 4: the shared state of the app, with Riverpod.
//
// Until Lab 3 the shared values lived in a widget's State (HomeScreen, then WeatherApp)
// and travelled with constructors (data down) and callbacks (events up).
// Here they live outside the widget tree, in providers:
// - a Notifier keeps a value and the operations that change it (the controller);
// - a Provider gives access to it to any widget (the access point).
// A widget reads a provider with ref.watch (and rebuilds when it changes)
// and changes it with ref.read(...notifier) (without rebuilding).
//
// LAB 5: the settings and the saved cities are also written to a file (storage.dart),
// so they are still there the next time the app starts.

import 'package:dima26_weatherapp/location.dart'; // LAB 5: where the phone is
import 'package:dima26_weatherapp/notifications.dart'; // LAB 5: the daily reminder
import 'package:dima26_weatherapp/storage.dart'; // LAB 5: the file
import 'package:dima26_weatherapp/weather_api.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The repository: the class that talks to the server.
// WeatherService (weather_api.dart, Lab 3) already is one: http and JSON stay there, not in the widgets.
// The provider creates it once and gives it to whoever needs it.
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// LAB 5: the second repository: WeatherService talks to the server, AppStorage to the disk.
// It must be read from the disk BEFORE the app starts (main in main.dart), and reading is a Future.
// So this provider has no value of its own: main gives it one, with overrideWithValue.
final storageProvider = Provider<AppStorage>((ref) {
  throw UnimplementedError('storageProvider is set in main()');
});

// LAB 5: two more repositories, for two more parts of the phone: the GPS and the notifications
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
final reminderServiceProvider = Provider<ReminderService>((ref) => ReminderService());

// The settings. An immutable model: we never change a field,
// we create a new Settings with copyWith (a copy with one value changed).
class Settings {
  final bool celsius; // true = °C, false = °F
  final bool kmh;     // true = km/h, false = mph
  final ThemeMode themeMode; // system (follow the phone), light or dark
  // LAB 5: the language of the app: 'system' (follow the phone), 'en' or 'it'.
  static const languages = ['system', 'en', 'it'];
  // A String, so it goes to the JSON file as it is.
  final String language;
  // LAB 5: the two switches that in Lab 4 were local state of SettingsScreen.
  // Now Home needs useLocation, and the reminder must survive a restart: shared, and saved.
  final bool reminder;    // a notification every morning
  final bool useLocation; // Home shows the weather where the phone is
  const Settings({required this.celsius, required this.kmh, required this.themeMode, this.language = 'system',
      this.reminder = false, this.useLocation = false});

  Settings copyWith({bool? celsius, bool? kmh, ThemeMode? themeMode, String? language, bool? reminder, bool? useLocation}) {
    return Settings(
      celsius: celsius ?? this.celsius, // ?? : the new value if given, else the old one
      kmh: kmh ?? this.kmh,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      reminder: reminder ?? this.reminder,
      useLocation: useLocation ?? this.useLocation,
    );
  }

  // LAB 5: Settings -> JSON, to write it in the file. The other direction of Weather.fromJson (Lab 3).
  // An enum like ThemeMode is not a JSON type: we save its name ("dark") as a string.
  Map<String, dynamic> toJson() {
    return {'celsius': celsius, 'kmh': kmh, 'themeMode': themeMode.name, 'language': language,
        'reminder': reminder, 'useLocation': useLocation};
  }

  // LAB 5: JSON -> Settings, to read it back from the file.
  // ?? : if a value is missing (a file written by an older version of the app), we use the default.
  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      celsius: json['celsius'] as bool? ?? true,
      kmh: json['kmh'] as bool? ?? true,
      themeMode: ThemeMode.values.asNameMap()[json['themeMode']] ?? ThemeMode.system, // "dark" -> ThemeMode.dark
      // LAB 5: no 'language' (a file written before this setting existed), or one the app doesn't have
      // (e.g. removed in a new version): 'system'. Otherwise Settings' dropdown would have no item to show
      language: languages.contains(json['language']) ? json['language'] as String : 'system',
      reminder: json['reminder'] as bool? ?? false,
      useLocation: json['useLocation'] as bool? ?? false,
    );
  }
}

// The Notifier: it keeps the Settings (in `state`) and the operations that change them.
class SettingsNotifier extends Notifier<Settings> {
  // build() gives the starting value. Riverpod calls it the first time someone reads the provider.
  // The theme starts as ThemeMode.system: MaterialApp follows the phone's own setting, live.
  @override
  Settings build() {
    final storage = ref.watch(storageProvider);
    // LAB 5: listenSelf is called every time `state` gets a new value (and once right after build).
    // So every change goes to the file, and the operations below stay exactly as in Lab 4.
    listenSelf((previous, next) => storage.write('settings', next.toJson()));
    // LAB 5: the settings in the file, if there are any. The first time there are none: the defaults, as in Lab 4
    final json = storage.read('settings');
    if (json == null) {
      return const Settings(celsius: true, kmh: true, themeMode: ThemeMode.system);
    }
    return Settings.fromJson(json as Map<String, dynamic>);
  }

  // Assigning `state` replaces setState(): every widget that watches this provider rebuilds.
  void setCelsius(bool celsius) => state = state.copyWith(celsius: celsius);
  void setKmh(bool kmh) => state = state.copyWith(kmh: kmh);
  void setThemeMode(ThemeMode themeMode) => state = state.copyWith(themeMode: themeMode);
  void setLanguage(String language) => state = state.copyWith(language: language); // LAB 5
  void setUseLocation(bool useLocation) => state = state.copyWith(useLocation: useLocation); // LAB 5

  // LAB 5: the reminder is more than a value: the phone must also schedule (or cancel) the notification,
  // and the user may say no. So this operation is async, and returns false if notifications are not allowed.
  // The texts arrive from the widget, already in the user's language: the Notifier knows no languages.
  Future<bool> setReminder(bool on, {required String title, required String body, required String confirmation}) async {
    final reminders = ref.read(reminderServiceProvider);
    if (on) {
      if (!await reminders.requestPermission()) return false; // denied: the switch stays off
      await reminders.scheduleDaily(title: title, body: body);
      await reminders.showNow(title: title, body: confirmation); // "every day at 8:00..."
    } else {
      await reminders.cancel();
    }
    state = state.copyWith(reminder: on); // saved in the file by listenSelf, like every setting
    return true;
  }
}

// The Provider: the access point. Any widget can ref.watch(settingsProvider).
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

// The saved cities: Home (the heart) and Saved (the list) both need them.
class SavedCitiesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final storage = ref.watch(storageProvider);
    // LAB 5: every change goes to the file, as for the settings.
    // JSON has lists but no sets: we write the set as a list
    listenSelf((previous, next) => storage.write('savedCities', next.toList()));
    // LAB 5: the cities in the file, as a set again. The first time there are none: no saved city
    final json = storage.read('savedCities') as List<dynamic>?;
    if (json == null) return {};
    return json.cast<String>().toSet();
  }

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

// LAB 5: the weather where the phone is: first the position (LocationService), then the weather there.
// It watches useLocation only to start again when the switch is turned on (e.g. after allowing the permission).
final hereWeatherProvider = FutureProvider<Weather>((ref) async {
  ref.watch(settingsProvider.select((settings) => settings.useLocation)); // select: only this field, not every setting
  final location = ref.watch(locationServiceProvider);
  final weather = ref.watch(weatherServiceProvider);
  final position = await location.currentPosition();
  return weather.fetchCurrentAt(position.lat, position.lon);
});

final forecastProvider = FutureProvider.family<List<DayForecast>, String>((ref, city) {
  return ref.watch(weatherServiceProvider).fetchForecast(city);
});
