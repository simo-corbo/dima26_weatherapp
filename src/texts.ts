// LAB 8: every text the user reads, in English and in Italian.
// No tool and no package: two plain objects with the same keys. TypeScript checks that Italian has every key of English
// (const it: Texts), so a missing translation is an error before the app even starts.
// Texts with a value inside are functions: updated(12) -> "Updated 12 s ago".

const en = {
  locale: 'en', // for the names of the days (toLocaleDateString)
  appTitle: 'Weather',
  searchCity: 'Search city',
  home: 'Home',
  saved: 'Saved',
  chooseCity: 'Choose a city',
  chooseOnTheLeft: 'Choose a city on the left',
  noSaved: 'No saved cities yet: tap the heart.',
  humidity: 'Humidity',
  wind: 'Wind',
  today: 'Today',
  updated: (seconds: number) => (seconds < 60 ? `Updated ${seconds} s ago` : `Updated ${Math.floor(seconds / 60)} min ago`),

  settings: 'Settings',
  temperatureInCelsius: 'Temperature in °C',
  windInKmh: 'Wind in km/h',
  theme: 'Theme',
  language: 'Language',
  system: 'System', // follow the phone (theme and language)
  light: 'Light',
  dark: 'Dark',
  dailyReminder: 'Daily reminder',
  useMyLocation: 'Use my location',

  reminderTitle: 'Good morning!',
  reminderBody: 'Check today’s weather before you go out.',
  reminderConfirm: 'Reminder on: every day at 8:00.',
  notificationsDenied: 'Notifications are off for this app. You can allow them in the phone’s settings.',

  // the condition from the server ("Rain") -> the words on the card
  conditions: { Clear: 'Clear sky', Clouds: 'Cloudy', Rain: 'Rain', Drizzle: 'Drizzle', Thunderstorm: 'Thunderstorm', Snow: 'Snow', Mist: 'Mist', Fog: 'Fog' } as Record<string, string>,
};

// the type of the English object: every other language must have the same keys
export type Texts = typeof en;

const it: Texts = {
  locale: 'it',
  appTitle: 'Meteo',
  searchCity: 'Cerca città',
  home: 'Home',
  saved: 'Salvate',
  chooseCity: 'Scegli una città',
  chooseOnTheLeft: 'Scegli una città a sinistra',
  noSaved: 'Nessuna città salvata: tocca il cuore.',
  humidity: 'Umidità',
  wind: 'Vento',
  today: 'Oggi',
  updated: (seconds: number) => (seconds < 60 ? `Aggiornato ${seconds} s fa` : `Aggiornato ${Math.floor(seconds / 60)} min fa`),

  settings: 'Impostazioni',
  temperatureInCelsius: 'Temperatura in °C',
  windInKmh: 'Vento in km/h',
  theme: 'Tema',
  language: 'Lingua',
  system: 'Sistema',
  light: 'Chiaro',
  dark: 'Scuro',
  dailyReminder: 'Promemoria quotidiano',
  useMyLocation: 'Usa la mia posizione',

  reminderTitle: 'Buongiorno!',
  reminderBody: 'Controlla il meteo di oggi prima di uscire.',
  reminderConfirm: 'Promemoria attivo: ogni giorno alle 8:00.',
  notificationsDenied: 'Le notifiche sono disattivate per questa app. Puoi attivarle nelle impostazioni del telefono.',

  conditions: { Clear: 'Sereno', Clouds: 'Nuvoloso', Rain: 'Pioggia', Drizzle: 'Pioviggine', Thunderstorm: 'Temporale', Snow: 'Neve', Mist: 'Foschia', Fog: 'Nebbia' },
};

export const texts = { en, it };
