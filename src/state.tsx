// LAB 7: the state that several SCREENS read: the chosen city, the saved cities, the units.
// Home, the picker, the city screen and Settings are separate screens: none of them is the
// parent of the others, so lifting the state up into one of them is not enough.
// We lift it above all of them: into a Context, around the whole app (see app/_layout.tsx).
// Flutter: the providers of Riverpod (savedCitiesProvider, settingsProvider).
// LAB 8: four more settings (theme, language, reminder, my location), and everything is saved on the disk.

import { ReactNode, createContext, useContext, useEffect, useState } from 'react';
import { useColorScheme } from 'react-native';
import { useLocales } from 'expo-localization'; // LAB 8: npx expo install expo-localization
import { Stored, load, save } from './storage';
import { Texts, texts } from './texts';

// what the Context holds: the values and the functions that change them
type WeatherState = {
  city: string | null;                  // the city shown on Home. LAB 8: null = not chosen yet
  setCity: (city: string) => void;
  saved: string[];                      // the cities with the heart
  toggleSaved: (city: string) => void;
  celsius: boolean;                     // true = °C, false = °F
  setCelsius: (value: boolean) => void;
  kmh: boolean;                         // true = km/h, false = mph
  setKmh: (value: boolean) => void;
  // LAB 8: the new settings
  theme: Stored['theme'];               // 'system' (follow the phone), 'light' or 'dark'
  setTheme: (value: Stored['theme']) => void;
  language: Stored['language'];         // 'system', 'en' or 'it'
  setLanguage: (value: Stored['language']) => void;
  reminder: boolean;                    // a notification every morning at 8:00
  setReminder: (value: boolean) => void;
  myLocation: boolean;                  // no city chosen: Home shows the weather where the phone is
  setMyLocation: (value: boolean) => void;
  // LAB 8: computed from the settings and the phone: every screen needs them
  dark: boolean;                        // is the night sky on?
  t: Texts;                             // the texts, in the language of the app
};

// createContext makes the "channel". null = the value used OUTSIDE a provider (a mistake: see useWeather)
const WeatherContext = createContext<WeatherState | null>(null);

// The provider: an ordinary component with useState. What it puts in value is visible to every
// component inside it, at any depth, without passing props down.
export function WeatherProvider({ children }: { children: ReactNode }) {
  const [city, setCity] = useState<string | null>(null); // LAB 8: was 'London': now Home decides (see index.tsx)
  const [saved, setSaved] = useState<string[]>([]);
  const [celsius, setCelsius] = useState(true);
  const [kmh, setKmh] = useState(true);
  const [theme, setTheme] = useState<Stored['theme']>('system');
  const [language, setLanguage] = useState<Stored['language']>('system');
  const [reminder, setReminder] = useState(false);
  const [myLocation, setMyLocation] = useState(false);
  const [loaded, setLoaded] = useState(false); // LAB 8: have we read the disk yet?

  // LAB 8: once, when the app starts ([] = no dependencies: never again): read what we saved last time.
  // The disk answers later (a Promise): meanwhile the app shows nothing (see the end of this component).
  useEffect(() => {
    async function start() {
      const stored = await load();
      if (stored !== null) {
        // ?? : a value missing in an older save gets its default
        setSaved(stored.saved ?? []);
        setCelsius(stored.celsius ?? true);
        setKmh(stored.kmh ?? true);
        setTheme(stored.theme ?? 'system');
        setLanguage(stored.language ?? 'system');
        setReminder(stored.reminder ?? false);
        setMyLocation(stored.myLocation ?? false);
      }
      setLoaded(true);
    }
    start();
  }, []);

  // LAB 8: after every render in which one of these values changed: write them all to the disk.
  useEffect(() => {
    if (!loaded) return; // not before reading: we would overwrite the saved values with the defaults
    save({ saved, celsius, kmh, theme, language, reminder, myLocation });
  }, [loaded, saved, celsius, kmh, theme, language, reminder, myLocation]);

  // LAB 8: the phone's own choices, updated live when the user changes them in the phone's settings
  const phoneScheme = useColorScheme();  // 'light' or 'dark'
  const phoneLocales = useLocales();     // the phone's languages, the preferred one first
  const dark = theme === 'system' ? phoneScheme === 'dark' : theme === 'dark';
  const lang = language === 'system' ? (phoneLocales[0].languageCode === 'it' ? 'it' : 'en') : language;

  // the heart: if the city was saved, remove it; if not, add it.
  // We never change the array: we give React a NEW one, so it sees that something changed.
  // setSaved is used only here: the screens get toggleSaved, not setSaved.
  function toggleSaved(c: string) {
    if (saved.includes(c)) {
      setSaved(saved.filter((x) => x !== c)); // a copy without this city
    } else {
      setSaved([...saved, c]); // a copy with this city at the end
    }
  }

  // LAB 8: until the disk has answered (a few milliseconds), nothing: no flash of the default settings
  if (!loaded) return null;

  return (
    // when one of these values changes, every component that reads the Context re-renders
    <WeatherContext
      value={{
        city, setCity, saved, toggleSaved, celsius, setCelsius, kmh, setKmh,
        theme, setTheme, language, setLanguage, reminder, setReminder, myLocation, setMyLocation,
        dark, t: texts[lang],
      }}>
      {children}
    </WeatherContext>
  );
}

// Any component calls useWeather() to read (and change) the shared state.
// Flutter: ref.watch(settingsProvider). It is a hook: same rules as useState (top level, not in an if).
export function useWeather() {
  const value = useContext(WeatherContext);
  if (value === null) throw new Error('useWeather must be used inside <WeatherProvider>');
  return value;
}
