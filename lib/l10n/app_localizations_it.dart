// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Meteo';

  @override
  String get searchCity => 'Cerca città';

  @override
  String get home => 'Home';

  @override
  String get saved => 'Salvate';

  @override
  String get chooseOnTheLeft => 'Scegli una città a sinistra';

  @override
  String get chooseCity => 'Scegli una città';

  @override
  String get orTypeCity => 'Oppure scrivi una città';

  @override
  String get humidity => 'Umidità';

  @override
  String get wind => 'Vento';

  @override
  String get today => 'Oggi';

  @override
  String get settings => 'Impostazioni';

  @override
  String get temperatureInCelsius => 'Temperatura in °C';

  @override
  String get windInKmh => 'Vento in km/h';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Lingua';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Chiaro';

  @override
  String get dark => 'Scuro';

  @override
  String get dailyReminder => 'Promemoria giornaliero';

  @override
  String get useMyLocation => 'Usa la mia posizione';

  @override
  String get reminderTitle => 'Buongiorno!';

  @override
  String get reminderBody => 'Controlla il meteo di oggi prima di uscire.';

  @override
  String get reminderConfirm => 'Promemoria attivo: ogni giorno alle 8:00.';

  @override
  String get notificationsDenied =>
      'Le notifiche sono disattivate per questa app. Puoi attivarle nelle impostazioni del telefono.';

  @override
  String condition(String condition) {
    String _temp0 = intl.Intl.selectLogic(condition, {
      'Clear': 'Sereno',
      'Clouds': 'Nuvoloso',
      'Rain': 'Pioggia',
      'Drizzle': 'Pioggerella',
      'Thunderstorm': 'Temporale',
      'Snow': 'Neve',
      'Mist': 'Foschia',
      'Fog': 'Nebbia',
      'other': '$condition',
    });
    return '$_temp0';
  }
}
