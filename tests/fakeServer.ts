// LAB 8: a fake OpenWeather, for the tests. The tests never use the internet:
// we replace fetch (a global function) with one that answers like the server, instantly, always the same.

// the answer of /weather for a city, in the shape OpenWeather uses (only the fields we read)
export function weatherJson(name: string) {
  return { name, weather: [{ main: 'Clouds', description: 'overcast clouds' }], main: { temp: 1.6, humidity: 83 }, wind: { speed: 1.7 } };
}

// the answer of /forecast: 3 hours apart, from today at 00:00 for 5 days (40 items)
export function forecastJson() {
  const list = [];
  for (let i = 0; i < 40; i++) {
    const day = 14 + Math.floor(i / 8); // 8 items per day
    const hour = (i % 8) * 3;
    list.push({
      dt_txt: `2026-11-${day} ${String(hour).padStart(2, '0')}:00:00`,
      main: { temp_min: 4 + (i % 8), temp_max: 6 + (i % 8) },
      weather: [{ main: hour === 12 ? 'Rain' : 'Clouds' }],
    });
  }
  return { list };
}

// A Response has a status, ok, and json(): we give just these three
const answer = (status: number, body: unknown) => Promise.resolve({ status, ok: status === 200, json: () => Promise.resolve(body) });

// Installs the fake server. "Atlantis" doesn't exist: 404, like the real server for an unknown city
export function fakeServer() {
  const fetchMock = jest.fn((url: string) => {
    if (url.includes('Atlantis')) return answer(404, { message: 'city not found' });
    if (url.includes('/forecast')) return answer(200, forecastJson());
    const city = decodeURIComponent(url.match(/q=([^&]*)/)?.[1] ?? 'Bergamo');
    return answer(200, weatherJson(city));
  });
  globalThis.fetch = fetchMock as unknown as typeof fetch;
  return fetchMock;
}
