// LAB 5: where the phone is. A repository, like WeatherService and AppStorage:
// the providers ask "where are we?", and only this class knows about GPS and permissions.

import 'package:geolocator/geolocator.dart'; // flutter pub add geolocator

/// A problem we can explain to the user: the error view shows its message.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  /// The position of the phone, roughly (about 1 km: enough for the weather).
  /// Three things must be true, and we check them in this order:
  /// 1. location is on in the phone's settings;
  /// 2. the user allowed OUR app to use it (the system asks only the first time);
  /// 3. the phone finds the position.
  Future<({double lat, double lon})> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('Location is off. Turn it on in the phone’s settings.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // the system's pop-up: "Allow Weather to use your location?". The text comes from Info.plist on iOS
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // deniedForever: the system won't ask again. Only the user can change it, in the phone's settings
      throw const LocationException('No permission for the location. You can allow it in the phone’s settings.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low), // low = faster, and enough for a city
    );
    // a record: two named values, without writing a class. Nobody outside this file sees geolocator's Position
    return (lat: position.latitude, lon: position.longitude);
  }
}
