// LAB 5: widget tests. Flutter builds our widgets in memory, without a phone,
// and the test taps them and looks at what's on screen, as a user would.
//   tester.pumpWidget(...)   builds the app
//   tester.tap(find...)      taps a widget
//   tester.pump()            draws the next frame (after a setState, a provider change...)
//   tester.pumpAndSettle()   draws frames until nothing moves any more (animations, Futures)
//   find.text('London')      looks for a widget, findsOneWidget / findsNothing say how many we expect
//
// The repositories are replaced by fakes (overrides, as in main): no network, no API key,
// always the same weather. That's why a test gives the same result every time.

import 'dart:io';

import 'package:dima26_weatherapp/location.dart';
import 'package:dima26_weatherapp/main.dart';
import 'package:dima26_weatherapp/notifications.dart';
import 'package:dima26_weatherapp/providers.dart';
import 'package:dima26_weatherapp/storage.dart';
import 'package:dima26_weatherapp/weather_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A WeatherService that never goes online: 12° and light rain everywhere.
class FakeWeatherService implements WeatherService {
  @override
  Future<Weather> fetchCurrent(String city) async {
    return Weather(name: city, condition: 'Rain', description: 'Light rain',
        temp: 12, feelsLike: 11, humidity: 80, windKmh: 15);
  }

  @override
  Future<Weather> fetchCurrentAt(double lat, double lon) async {
    // the server tells us the name of the place: here, always Milano
    return const Weather(name: 'Milano', condition: 'Clear', description: 'Clear sky',
        temp: 20, feelsLike: 20, humidity: 50, windKmh: 5);
  }

  @override
  Future<List<DayForecast>> fetchForecast(String city) async {
    return [
      DayForecast(day: 'Today', date: DateTime(2026, 10, 9), condition: 'Clear', max: 18, min: 10),
    ];
  }
}

/// LAB 5: a phone that is always in Milan, without GPS and without asking permission.
class FakeLocationService implements LocationService {
  @override
  Future<({double lat, double lon})> currentPosition() async => (lat: 45.46, lon: 9.19);
}

/// LAB 5: a phone that remembers what it was asked to schedule, instead of showing notifications.
class FakeReminderService implements ReminderService {
  bool allow = true;     // what the user answers to "Allow notifications?"
  String? scheduled;     // the text of the daily reminder, if one is scheduled
  @override
  Future<bool> requestPermission() async => allow;
  @override
  Future<void> scheduleDaily({required String title, required String body}) async => scheduled = body;
  @override
  Future<void> showNow({required String title, required String body}) async {}
  @override
  Future<void> cancel() async => scheduled = null;
}

/// Builds the app on a phone-sized screen, with the fake server and a storage that starts from `saved`
/// (what the file would contain).
Future<void> pumpApp(WidgetTester tester, {Map<String, dynamic>? saved, FakeReminderService? reminders}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3); // an iPhone 17, in physical pixels
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  // AppStorage built directly from a Map: nothing is read from the disk.
  // (Inside a widget test the real file writes don't finish: here we only check the screen.)
  final storage = AppStorage(File('${Directory.systemTemp.path}/widget_test.json'), saved ?? {});

  await tester.pumpWidget(ProviderScope(
    retry: (retryCount, error) => null,
    overrides: [
      storageProvider.overrideWithValue(storage),
      weatherServiceProvider.overrideWithValue(FakeWeatherService()),
      locationServiceProvider.overrideWithValue(FakeLocationService()), // LAB 5
      reminderServiceProvider.overrideWithValue(reminders ?? FakeReminderService()), // LAB 5
    ],
    child: const WeatherApp(),
  ));
  await tester.pumpAndSettle(); // the fake weather arrives
}

void main() {
  testWidgets('Home shows the weather of London', (tester) async {
    await pumpApp(tester);

    expect(find.text('London'), findsOneWidget);
    expect(find.text('12°'), findsOneWidget);
    expect(find.text('Rain'), findsOneWidget); // LAB 5: the condition, from app_en.arb (not the server's "Light rain")
  });

  testWidgets('a heart on Home puts the city in the Saved tab', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.favorite_border)); // the empty heart next to London
    await tester.pump();
    expect(find.byIcon(Icons.favorite), findsOneWidget); // now full

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('London'), findsOneWidget); // in the list
  });

  testWidgets('°F chosen in Settings changes the temperature on Home', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle(); // the Settings screen slides in
    await tester.tap(find.text('Temperature in °C'));
    await tester.pumpAndSettle();
    await tester.pageBack(); // the back arrow of the AppBar
    await tester.pumpAndSettle();

    expect(find.text('54°'), findsOneWidget);
  });

  testWidgets('with Italian saved in the file, the app speaks Italian', (tester) async {
    await pumpApp(tester, saved: {
      'settings': {'language': 'it'},
    });

    expect(find.text('Cerca città'), findsOneWidget);
    expect(find.text('Pioggia'), findsOneWidget); // the condition, from app_it.arb
    expect(find.text('Umidità'), findsOneWidget);
    expect(find.text('Search city'), findsNothing);
  });

  testWidgets('with "Use my location" on, Home shows where the phone is', (tester) async {
    await pumpApp(tester, saved: {
      'settings': {'useLocation': true},
    });

    expect(find.text('Milano'), findsOneWidget); // the name the (fake) server gave for the position
    expect(find.text('20°'), findsOneWidget);
  });

  testWidgets('turning the reminder on schedules it', (tester) async {
    final reminders = FakeReminderService();
    await pumpApp(tester, reminders: reminders);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily reminder'));
    await tester.pumpAndSettle();

    expect(reminders.scheduled, 'Check today’s weather before you go out.');
  });

  testWidgets('if notifications are denied, the switch stays off and we explain why', (tester) async {
    final reminders = FakeReminderService()..allow = false; // the user taps "Don't allow"
    await pumpApp(tester, reminders: reminders);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily reminder'));
    await tester.pump(); // the SnackBar appears

    expect(reminders.scheduled, isNull);
    expect(find.textContaining('Notifications are off'), findsOneWidget);
  });

  // LAB 5: ONE LONG TEST, the one we read together in class.
  // A user's first morning with the app, from the first start to a restart, in 9 steps.
  // Each step is: do what a user does (tap), let Flutter draw (pump), look at the screen (expect).
  testWidgets('a morning with the app: from the first start to a restart', (tester) async {
    // 1. ARRANGE. A phone in memory, a fake server (12°, rain), an empty file,
    //    and a user who will say "Don't allow" to notifications
    final reminders = FakeReminderService()..allow = false;
    await pumpApp(tester, reminders: reminders);

    // 2. LOOK. Home shows London, as we expect from the fake server
    expect(find.text('London'), findsOneWidget);
    expect(find.text('12°'), findsOneWidget);
    expect(find.text('Rain'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget); // not saved yet

    // 3. TAP AND PUMP. The heart: the state changes at once, the screen at the next frame
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    // 4. NAVIGATE. The Saved tab, then back to Home: pumpAndSettle waits for the animation
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('London'), findsOneWidget); // in the list
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // 5. SETTINGS. °F, and the reminder, which the (fake) user refuses
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Temperature in °C'));
    await tester.tap(find.text('Daily reminder'));
    await tester.pump();
    expect(reminders.scheduled, isNull); // nothing scheduled
    expect(find.textContaining('Notifications are off'), findsOneWidget); // and we say why

    // 6. A DROPDOWN. Open the language menu, choose Italiano: the screen changes language at once
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Italiano').last); // .last: the item in the open menu
    await tester.pumpAndSettle();
    expect(find.text('Impostazioni'), findsOneWidget); // "Settings", in Italian

    // 7. BACK HOME. The back arrow now has an Italian tooltip; Home follows every setting
    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();
    expect(find.text('54°'), findsOneWidget); // 12 °C in °F
    expect(find.text('Pioggia'), findsOneWidget); // the condition, in Italian
    expect(find.byIcon(Icons.favorite), findsOneWidget); // London still saved

    // 8. THE FILE. We look inside the app: what would be written on the disk?
    final container = ProviderScope.containerOf(tester.element(find.byType(WeatherApp)));
    final storage = container.read(storageProvider);
    final file = {'settings': storage.read('settings'), 'savedCities': storage.read('savedCities')};
    expect(file['savedCities'], ['London']);
    expect(file['settings'], containsPair('celsius', false));
    expect(file['settings'], containsPair('language', 'it'));
    expect(file['settings'], containsPair('reminder', false)); // refused: still off

    // 9. RESTART. Throw the app away and start a new one from that file: everything is back
    await tester.pumpWidget(const SizedBox()); // the old app is gone, with all its providers
    await pumpApp(tester, saved: file);
    expect(find.text('Cerca città'), findsOneWidget);
    expect(find.text('54°'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}

