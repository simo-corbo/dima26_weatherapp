// LAB 5: unit tests. Each one checks a small piece of logic, without any widget, screen or phone.
// Run them with:  flutter test test/unit_test.dart   (or the Testing panel of VS Code)
//
// The shape is always the same three steps:
//   1. arrange: prepare the input
//   2. act: call the code under test
//   3. assert: expect(actual, expected) says what the result must be

import 'package:dima26_weatherapp/main.dart';
import 'package:dima26_weatherapp/providers.dart';
import 'package:dima26_weatherapp/weather_api.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // group: a title for some tests about the same thing (it shows in the report)
  group('units', () {
    test('°C stays as it is, °F is converted', () {
      expect(formatTemp(12, true), '12°');
      expect(formatTemp(12, false), '54°'); // 12 × 9/5 + 32 = 53.6 → 54
      expect(formatTemp(-40, false), '-40°'); // the one temperature that is the same in both
    });

    test('km/h stays as it is, mph is converted', () {
      expect(formatWind(10, true), '10 km/h');
      expect(formatWind(10, false), '6 mph'); // 10 × 0.621 = 6.21 → 6
    });
  });

  group('JSON from the server (Lab 3)', () {
    test('Weather.fromJson reads the fields we need', () {
      final json = {
        'name': 'London',
        'weather': [
          {'main': 'Rain', 'description': 'light rain'}
        ],
        'main': {'temp': 16.4, 'feels_like': 15.4, 'humidity': 80},
        'wind': {'speed': 5}, // m/s
      };

      final weather = Weather.fromJson(json);

      expect(weather.name, 'London');
      expect(weather.condition, 'Rain');
      expect(weather.description, 'Light rain'); // capitalized
      expect(weather.temp, 16); // rounded
      expect(weather.windKmh, 18); // 5 m/s × 3.6
    });

    test('forecastFromJson groups the 3-hour items by day', () {
      // two days, two items each: the max and the min of each day, and the condition at midday
      Map<String, dynamic> item(String time, num min, num max, String condition) => {
            'dt_txt': time,
            'main': {'temp_min': min, 'temp_max': max},
            'weather': [
              {'main': condition}
            ],
          };
      final json = {
        'list': [
          item('2026-10-09 09:00:00', 10, 14, 'Clouds'),
          item('2026-10-09 12:00:00', 12, 18, 'Clear'),
          item('2026-10-10 12:00:00', 8, 11, 'Rain'),
          item('2026-10-10 15:00:00', 7, 12, 'Rain'),
        ],
      };

      final days = forecastFromJson(json);

      expect(days.length, 2);
      expect(days[0].date, DateTime(2026, 10, 9));
      expect(days[0].max, 18);
      expect(days[0].min, 10);
      expect(days[0].condition, 'Clear'); // the one at 12:00
      expect(days[1].min, 7);
    });
  });

  group('JSON to the file (Lab 5)', () {
    test('Settings survive a trip to JSON and back', () {
      const settings = Settings(celsius: false, kmh: true, themeMode: ThemeMode.dark, language: 'it',
          reminder: true, useLocation: true);

      final back = Settings.fromJson(settings.toJson());

      expect(back.celsius, false);
      expect(back.kmh, true);
      expect(back.themeMode, ThemeMode.dark);
      expect(back.language, 'it');
      expect(back.reminder, true);
      expect(back.useLocation, true);
    });

    test('a file from an older version (missing keys, unknown values) gets the defaults', () {
      final settings = Settings.fromJson({'celsius': false});

      expect(settings.celsius, false); // what the file had
      expect(settings.kmh, true); // the rest: defaults
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.language, 'system');
      expect(settings.reminder, false);
      expect(settings.useLocation, false);

      // a language or a theme the app doesn't have (any more)
      final unknown = Settings.fromJson({'language': 'fr', 'themeMode': 'sepia'});
      expect(unknown.language, 'system');
      expect(unknown.themeMode, ThemeMode.system);
    });
  });
}
