// LAB 5: the memory of the app, in a file.
//
// Until Lab 4 everything lived in RAM: in a State, or in a provider.
// When the app is closed, the system frees that memory, and at the next start
// the saved cities and the settings are back to their starting values.
// A file is on the phone's disk (its storage): it stays there when the app closes.
//
// We keep everything in ONE small JSON file, weather_app.json:
// {
//   "settings": { "celsius": true, "kmh": true, "themeMode": "dark" },
//   "savedCities": [ "Oslo", "Milano" ]
// }
// JSON is the same format the server uses (Lab 3): here we write it, there we only read it.

import 'dart:convert'; // jsonEncode / jsonDecode: Maps and Lists <-> text
import 'dart:io'; // File: read and write files on the disk

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart'; // flutter pub add path_provider

/// Reads the file once, at the start, and writes it again every time something changes.
/// Like WeatherService, it's a repository: the widgets and the providers never touch the file.
class AppStorage {
  final File _file;
  final Map<String, dynamic> _data; // the content of the file, in memory

  AppStorage(this._file, this._data);

  /// Finds where the app may write, and reads the file from there.
  /// Each app has its own folders on the phone, and no other app can see them.
  /// We don't know the path in advance (it's different on iOS and Android):
  /// path_provider asks the system. It's a question to the system, so it's a Future.
  static Future<AppStorage> open() async {
    final folder = await getApplicationDocumentsDirectory();
    final file = File('${folder.path}/weather_app.json');
    debugPrint('Storage: ${file.path}'); // to find the file and open it (see the slides)
    return load(file);
  }

  /// Reads a file that may not exist yet.
  static Future<AppStorage> load(File file) async {
    // the very first start: no file yet, so nothing saved
    if (!await file.exists()) return AppStorage(file, {});
    try {
      final text = await file.readAsString();                // the text in the file
      final json = jsonDecode(text) as Map<String, dynamic>; // the text -> a Map
      return AppStorage(file, json);
    } catch (error) {
      // the file is broken (e.g. the app was killed while writing): we start again from nothing.
      // Better to lose the saved cities than to have an app that doesn't open.
      debugPrint('Storage: could not read the file ($error)');
      return AppStorage(file, {});
    }
  }

  /// The value saved under a key, or null if there is none (e.g. the first start).
  dynamic read(String key) => _data[key];

  // the last write we started: the next one waits for it
  Future<void> _writing = Future.value();

  /// Changes one key and writes the WHOLE file again (it's small: a few hundred bytes).
  Future<void> write(String key, Object value) {
    _data[key] = value;
    final text = jsonEncode(_data); // the Map -> text
    // One write at a time, in order. The settings and the saved cities share this file:
    // two writes at the same moment could mix their bytes and break it.
    _writing = _writing
        .then((_) => _file.writeAsString(text)) // text -> the disk
        .catchError((Object error) {
          // e.g. the disk is full: we keep the values in memory, the app goes on
          debugPrint('Storage: could not write the file ($error)');
          return _file;
        });
    return _writing;
  }
}
