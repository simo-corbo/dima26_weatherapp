// LAB 8: the memory of the app, on the phone's disk. Everything in state.tsx lives in RAM:
// when the system closes the app, it's gone. What we write here is still there at the next start.
//
// AsyncStorage: the usual React Native way to keep small data. A dictionary saved on the disk:
// a key (a string) -> a value (a string). No files, no folders, no paths: the library chooses them.
// (In Flutter we wrote a JSON file ourselves; here the library handles the disk for us.)
// One key, one JSON text with everything inside.
import AsyncStorage from '@react-native-async-storage/async-storage'; // npx expo install @react-native-async-storage/async-storage

const KEY = 'weather_app';

// what we keep: the hearts and the settings. Not the city on Home: it starts again from London
export type Stored = {
  saved: string[];
  celsius: boolean;
  kmh: boolean;
  theme: 'system' | 'light' | 'dark';
  language: 'system' | 'en' | 'it';
  reminder: boolean;
  myLocation: boolean;
};

// Reads what we saved, or null the very first time. Reading the disk takes time: a Promise
export async function load(): Promise<Partial<Stored> | null> {
  const text = await AsyncStorage.getItem(KEY); // null if the key was never written
  if (text === null) return null;
  try {
    return JSON.parse(text); // the text -> an object
  } catch {
    // a broken value: better to lose the hearts than to have an app that doesn't open
    return null;
  }
}

// Writes everything again (a few hundred bytes). JSON.stringify: the object -> text
export async function save(stored: Stored): Promise<void> {
  await AsyncStorage.setItem(KEY, JSON.stringify(stored));
}
