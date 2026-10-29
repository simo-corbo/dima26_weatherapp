import 'dart:convert'; // jsonDecode: turns the text of the response into Maps and Lists

import 'package:http/http.dart' as http; // the package in pubspec.yaml: http.get

/// Data class for the current weather. We read it from the JSON of the response.
class Weather {
  final String name;        // the city, as OpenWeather writes it
  final String condition;   // Clear, Clouds, Rain, Drizzle, Thunderstorm, Snow... (see WeatherIcon)
  final String description; // "Light rain"
  final int temp;           // always °C: we convert only when we show it
  final int feelsLike;      // °C
  final int humidity;       // %
  final int windKmh;        // always km/h

  const Weather({
    required this.name,
    required this.condition,
    required this.description,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windKmh,
  });

  /// A factory constructor: it builds a Weather from the JSON of the response.
  /// The JSON looks like this (only the parts we read):
  /// {
  ///   "name": "London",
  ///   "weather": [ { "main": "Rain", "description": "light rain" } ],
  ///   "main": { "temp": 16.2, "feels_like": 15.4, "humidity": 80 },
  ///   "wind": { "speed": 4.1 }
  /// }
  factory Weather.fromJson(Map<String, dynamic> json) {
    final first = (json['weather'] as List).first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    return Weather(
      name: json['name'] as String,
      condition: first['main'] as String,
      description: _capitalize(first['description'] as String),
      // a number in JSON can be 16 or 16.2: "as num" accepts both, round() gives an int
      temp: (main['temp'] as num).round(),
      feelsLike: (main['feels_like'] as num).round(),
      humidity: (main['humidity'] as num).round(),
      windKmh: ((wind['speed'] as num) * 3.6).round(), // m/s × 3.6 = km/h
    );
  }
}

/// One day of the forecast strip.
class DayForecast {
  final String day;       // "Today", "Tue", ... (the English label of Lab 3: mainlab3/mainlab4 still show it)
  // LAB 5: the date. The name of the day depends on the user's language,
  // so the widget writes it (DayCard), like the units. The data stays the same in every language.
  final DateTime date;
  final String condition; // the condition at midday
  final int max;          // °C
  final int min;          // °C

  const DayForecast({required this.day, required this.date, required this.condition, required this.max, required this.min});
}

/// A problem we can explain to the user: the error view shows its message.
class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  @override
  String toString() => message; // so '${snapshot.error}' is just the message
}

/// Talks to OpenWeather. Every method returns a Future: the answer arrives later.
class WeatherService {
  // The key is NOT in the code: it's passed when the app is built, with
  //   flutter run --dart-define-from-file=dart_define.json
  // (VS Code does it for us: see .vscode/launch.json). dart_define.json is in .gitignore.
  // If the key wasn't passed, this is the empty string ''.
  static const _apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  static const _host = 'api.openweathermap.org';

  /// GET /data/2.5/weather?q={city}&units=metric&appid={key}
  Future<Weather> fetchCurrent(String city) async {
    final json = await _get('/data/2.5/weather', {'q': city});
    return Weather.fromJson(json);
  }

  /// LAB 5: GET /data/2.5/weather?lat={lat}&lon={lon}&units=metric&appid={key}
  /// The same answer, for a position instead of a name: "name" says which city it is.
  Future<Weather> fetchCurrentAt(double lat, double lon) async {
    final json = await _get('/data/2.5/weather', {'lat': '$lat', 'lon': '$lon'});
    return Weather.fromJson(json);
  }

  /// GET /data/2.5/forecast?q={city}&units=metric&appid={key}
  /// The answer is a list of 40 items, one every 3 hours for 5 days: we group them by day.
  Future<List<DayForecast>> fetchForecast(String city) async {
    final json = await _get('/data/2.5/forecast', {'q': city});
    return forecastFromJson(json);
  }

  /// The request all the methods share. async: it can wait (await) without blocking the app.
  /// LAB 5: `where` is the place: {'q': city}, or {'lat': ..., 'lon': ...}
  Future<Map<String, dynamic>> _get(String path, Map<String, String> where) async { // json is a Map<String, dynamic> 
    if (_apiKey.isEmpty) {
      throw const WeatherException('No API key. Run with --dart-define-from-file=dart_define.json');
    }

    // Uri.https builds the URL and encodes the parameters for us ("New York" -> "New%20York")
    // LAB 5: the parameters = a copy of the place, plus the two that every request has
    final parameters = Map<String, String>.from(where);
    parameters['units'] = 'metric'; // always C: we convert at display time
    parameters['appid'] = _apiKey;
    final uri = Uri.https(_host, path, parameters);

    final http.Response response;
    try {
      response = await http.get(uri); // waits here until the server answers
    } catch (e) {
      throw const WeatherException('No connection. Check the internet and try again.');
    }

    // the status code says how it went: 200 = OK
    switch (response.statusCode) {
      case 200:
        return jsonDecode(response.body) as Map<String, dynamic>;
      case 401:
        throw const WeatherException('Invalid API key.');
      case 404:
        throw WeatherException('City "${where['q'] ?? 'here'}" not found');
      default:
        throw WeatherException('Could not load the weather (error ${response.statusCode}).');
    }
  }
}

/// Groups the 3-hour items of /forecast into 5 days: min, max, and the condition at midday.
/// Each item looks like: { "dt_txt": "2026-10-09 12:00:00",
///                         "main": { "temp_min": 14.8, "temp_max": 16.3 },
///                         "weather": [ { "main": "Rain" } ] }
List<DayForecast> forecastFromJson(Map<String, dynamic> json) {
  // 1. group the items by date: "2026-10-09" → [item, item, ...]
  final byDate = <String, List<Map<String, dynamic>>>{};
  for (final item in json['list'] as List) {
    final date = (item['dt_txt'] as String).substring(0, 10);
    // putIfAbsent: the list of that date, created empty the first time
    byDate.putIfAbsent(date, () => []).add(item as Map<String, dynamic>);
  }

  // 2. one DayForecast per date, at most 5
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final days = <DayForecast>[];
  for (final date in byDate.keys.take(5)) {
    final items = byDate[date]!;
    var max = -1000;
    var min = 1000;
    var condition = (items.first['weather'] as List).first['main'] as String;
    for (final item in items) {
      final hi = (item['main']['temp_max'] as num).round();
      final lo = (item['main']['temp_min'] as num).round();
      if (hi > max) max = hi;
      if (lo < min) min = lo;
      // the condition at midday describes the day best
      if ((item['dt_txt'] as String).endsWith('12:00:00')) {
        condition = (item['weather'] as List).first['main'] as String;
      }
    }
    final label = days.isEmpty ? 'Today' : weekdays[DateTime.parse(date).weekday - 1];
    days.add(DayForecast(day: label, date: DateTime.parse(date), condition: condition, max: max, min: min));
  }
  return days;
}

/// "light rain" → "Light rain"
String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
