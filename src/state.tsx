// LAB 7: the state that several SCREENS read: the chosen city, the saved cities, the units.
// Home, the picker, the city screen and Settings are separate screens: none of them is the
// parent of the others, so lifting the state up into one of them is not enough.
// We lift it above all of them: into a Context, around the whole app (see app/_layout.tsx).
// Flutter: the providers of Riverpod (savedCitiesProvider, settingsProvider).

import { ReactNode, createContext, useContext, useState } from 'react';

// what the Context holds: the values and the functions that change them
type WeatherState = {
  city: string;                         // the city shown on Home
  setCity: (city: string) => void;
  saved: string[];                      // the cities with the heart
  toggleSaved: (city: string) => void;
  celsius: boolean;                     // true = °C, false = °F
  setCelsius: (value: boolean) => void;
  kmh: boolean;                         // true = km/h, false = mph
  setKmh: (value: boolean) => void;
};

// createContext makes the "channel". null = the value used OUTSIDE a provider (a mistake: see useWeather)
const WeatherContext = createContext<WeatherState | null>(null);

// The provider: an ordinary component with useState. What it puts in value is visible to every
// component inside it, at any depth, without passing props down.
export function WeatherProvider({ children }: { children: ReactNode }) {
  const [city, setCity] = useState('London');
  const [saved, setSaved] = useState<string[]>([]);
  const [celsius, setCelsius] = useState(true);
  const [kmh, setKmh] = useState(true);

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

  return (
    // when one of these values changes, every component that reads the Context re-renders
    <WeatherContext value={{ city, setCity, saved, toggleSaved, celsius, setCelsius, kmh, setKmh }}>
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
