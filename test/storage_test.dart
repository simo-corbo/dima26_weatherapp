// LAB 5: tests of the persistence (storage.dart + the Notifiers in providers.dart).
// They use a real file, in a temporary folder of the computer: no phone, no path_provider.
//
// A ProviderContainer is a ProviderScope without widgets: it holds the providers,
// and we read them with container.read. A new container on the same file = a new start of the app.

import 'dart:io';

import 'package:dima26_weatherapp/providers.dart';
import 'package:dima26_weatherapp/storage.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// "starts the app" on a file: reads it, and gives it to the providers as main() does
Future<ProviderContainer> startApp(File file) async {
  final storage = await AppStorage.load(file);
  final container = ProviderContainer(overrides: [storageProvider.overrideWithValue(storage)]);
  addTearDown(container.dispose); // closed at the end of the test
  return container;
}

void main() {
  late Directory folder;

  // setUp runs before EACH test, tearDown after it: every test gets its own empty folder
  setUp(() => folder = Directory.systemTemp.createTempSync('weather_test'));
  tearDown(() => folder.deleteSync(recursive: true));

  test('the first start uses the defaults', () async {
    final app = await startApp(File('${folder.path}/weather_app.json')); // the file doesn't exist

    expect(app.read(savedCitiesProvider), isEmpty);
    expect(app.read(settingsProvider).themeMode, ThemeMode.system);
    await app.read(storageProvider).write('test', true); // let the writes of the start finish
  });

  test('the choices survive a restart', () async {
    final file = File('${folder.path}/weather_app.json');

    // first start: the user saves two cities and picks dark mode
    final first = await startApp(file);
    first.read(savedCitiesProvider.notifier).toggle('Oslo');
    first.read(savedCitiesProvider.notifier).toggle('Milano');
    first.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
    // the writes are Futures: one more write waits in the queue until all the others are done
    await first.read(storageProvider).write('test', true);

    // second start, on the same file
    final second = await startApp(file);

    expect(second.read(savedCitiesProvider), {'Oslo', 'Milano'});
    expect(second.read(settingsProvider).themeMode, ThemeMode.dark);
    await second.read(storageProvider).write('test', true); // let the writes of the start finish
  });

  test('a broken file does not stop the app', () async {
    final file = File('${folder.path}/weather_app.json')
      ..writeAsStringSync('{"savedCities": ["Os'); // cut in the middle, as if the phone died

    final app = await startApp(file);

    expect(app.read(savedCitiesProvider), isEmpty); // we start from nothing
    await app.read(storageProvider).write('test', true);
  });
}
