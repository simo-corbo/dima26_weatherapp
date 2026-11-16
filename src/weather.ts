// LAB 8: the weather, from the OpenWeather server.
// No React here: plain TypeScript functions, so the tests can call them directly.

// The key is NOT in the code: Expo reads it from .env.local (never committed, see .env.example)
// and writes it into the app when it builds the bundle. Only variables that start with
// EXPO_PUBLIC_ get there.
const API_KEY = process.env.EXPO_PUBLIC_OPENWEATHER_API_KEY;
const BASE = 'https://api.openweathermap.org/data/2.5';

// What we take from the answer. The server always sends °C (units=metric) and m/s:
// we keep °C and km/h, and convert only when we show them (formatTemp, formatWind in components.tsx).
export type Weather = {
  name: string;        // the city, as the server writes it ("London")
  condition: string;   // "Rain", "Clear", "Clouds"... it chooses the icon and the words (texts.ts)
  temp: number;        // °C
  humidity: number;    // %
  windKmh: number;     // km/h
};

// One day of the forecast strip
export type DayForecast = {
  date: Date;
  condition: string; // the condition at midday
  max: number;       // °C
  min: number;       // °C
};

// The answer, as text, has no type: response.json() gives `any`. Here we say which fields we use.
// The JSON looks like this (only the parts we read):
// { "name": "London",
//   "weather": [ { "main": "Rain", "description": "light rain" } ],
//   "main": { "temp": 16.2, "humidity": 80 },
//   "wind": { "speed": 4.1 } }
export function weatherFromJson(json: any): Weather {
  return {
    name: json.name,
    condition: json.weather[0].main, // weather is a list: we take the first
    temp: Math.round(json.main.temp),
    humidity: Math.round(json.main.humidity),
    windKmh: Math.round(json.wind.speed * 3.6), // m/s × 3.6 = km/h
  };
}

// The forecast answer is a list of 40 items, one every 3 hours for 5 days. We group them by day.
// Each item: { "dt_txt": "2026-11-14 12:00:00", "main": { "temp_min": 9.8, "temp_max": 12.3 },
//              "weather": [ { "main": "Rain" } ] }
export function forecastFromJson(json: any): DayForecast[] {
  // 1. group the items by date: "2026-11-14" -> [item, item, ...]
  const byDate: Record<string, any[]> = {};
  for (const item of json.list) {
    const date = item.dt_txt.slice(0, 10);
    byDate[date] = [...(byDate[date] ?? []), item];
  }
  // 2. one DayForecast per date, at most 5
  return Object.keys(byDate).slice(0, 5).map((date) => {
    const items = byDate[date];
    const midday = items.find((item) => item.dt_txt.endsWith('12:00:00')) ?? items[0];
    return {
      date: new Date(`${date}T12:00:00`), // midday, so the day is the same in every time zone of the world
      condition: midday.weather[0].main,
      max: Math.round(Math.max(...items.map((item) => item.main.temp_max))),
      min: Math.round(Math.min(...items.map((item) => item.main.temp_min))),
    };
  });
}

// The request all the functions share. async: it can wait (await) without blocking the app.
// `place` is only for the message when the city doesn't exist.
async function get(path: string, place: string): Promise<any> {
  if (!API_KEY) {
    throw new Error('No API key. Copy .env.example to .env.local and write your key there.');
  }
  let response: Response;
  try {
    response = await fetch(`${BASE}${path}&units=metric&appid=${API_KEY}`); // waits here until the server answers
  } catch {
    // fetch fails only when there is no answer at all: no internet, server unreachable
    throw new Error('No connection. Check the internet and try again.');
  }
  // A 404 IS an answer: fetch doesn't fail. We look at the status code ourselves (200 = OK)
  if (response.status === 401) throw new Error('Invalid API key.');
  if (response.status === 404) throw new Error(`City "${place}" not found.`);
  if (!response.ok) throw new Error(`Could not load the weather (error ${response.status}).`);
  return await response.json(); // the text of the body -> objects and arrays
}

// GET /weather?q={city}. encodeURIComponent: "New York" -> "New%20York", safe in a URL
export async function fetchCurrent(city: string): Promise<Weather> {
  return weatherFromJson(await get(`/weather?q=${encodeURIComponent(city)}`, city));
}

// GET /weather?lat=..&lon=.. : the same answer for a position. "name" says which city it is
export async function fetchCurrentAt(lat: number, lon: number): Promise<Weather> {
  return weatherFromJson(await get(`/weather?lat=${lat}&lon=${lon}`, 'here'));
}

// GET /forecast?q={city}: the next 5 days
export async function fetchForecast(city: string): Promise<DayForecast[]> {
  return forecastFromJson(await get(`/forecast?q=${encodeURIComponent(city)}`, city));
}
