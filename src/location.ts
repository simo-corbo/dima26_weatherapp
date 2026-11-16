// LAB 8: where the phone is.
import * as Location from 'expo-location'; // npx expo install expo-location

// The position of the phone, roughly (about 1 km: enough for the weather).
// Three things must be true:
// 1. location is on in the phone's settings;
// 2. the user allowed OUR app to use it (the system asks only the first time);
// 3. the phone finds the position.
// Each can fail, and each failure gets a sentence the user understands.
export async function currentPosition(): Promise<{ lat: number; lon: number }> {
  if (!(await Location.hasServicesEnabledAsync())) {
    throw new Error('Location is off. Turn it on in the phone’s settings.');
  }
  // the system's pop-up "Allow Weather to use your location?" the first time; then it remembers the answer
  const { granted } = await Location.requestForegroundPermissionsAsync();
  if (!granted) {
    throw new Error('No permission for the location. You can allow it in the phone’s settings.');
  }
  // Low = faster, and enough for a city
  const position = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Low });
  return { lat: position.coords.latitude, lon: position.coords.longitude };
}
