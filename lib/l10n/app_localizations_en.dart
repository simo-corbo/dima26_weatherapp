// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Weather';

  @override
  String get searchCity => 'Search city';

  @override
  String get home => 'Home';

  @override
  String get saved => 'Saved';

  @override
  String get chooseOnTheLeft => 'Choose a city on the left';

  @override
  String get chooseCity => 'Choose a city';

  @override
  String get orTypeCity => 'Or type a city';

  @override
  String get humidity => 'Humidity';

  @override
  String get wind => 'Wind';

  @override
  String get today => 'Today';

  @override
  String get settings => 'Settings';

  @override
  String get temperatureInCelsius => 'Temperature in °C';

  @override
  String get windInKmh => 'Wind in km/h';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get reminderTitle => 'Good morning!';

  @override
  String get reminderBody => 'Check today’s weather before you go out.';

  @override
  String get reminderConfirm => 'Reminder on: every day at 8:00.';

  @override
  String get notificationsDenied =>
      'Notifications are off for this app. You can allow them in the phone’s settings.';

  @override
  String condition(String condition) {
    String _temp0 = intl.Intl.selectLogic(condition, {
      'Clear': 'Clear sky',
      'Clouds': 'Cloudy',
      'Rain': 'Rain',
      'Drizzle': 'Drizzle',
      'Thunderstorm': 'Thunderstorm',
      'Snow': 'Snow',
      'Mist': 'Mist',
      'Fog': 'Fog',
      'other': '$condition',
    });
    return '$_temp0';
  }
}
