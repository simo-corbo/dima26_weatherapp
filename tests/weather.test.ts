// LAB 8: unit tests: plain functions, no screen. Each test: prepare, act, check (expect).
import { formatTemp, formatWind } from '../src/components';
import { fetchCurrent, forecastFromJson, weatherFromJson } from '../src/weather';
import { fakeServer, forecastJson, weatherJson } from './fakeServer';

test('weatherFromJson takes what we need, rounded, wind in km/h', () => {
  const weather = weatherFromJson(weatherJson('London'));
  expect(weather).toEqual({ name: 'London', condition: 'Clouds', temp: 2, humidity: 83, windKmh: 6 });
});

test('forecastFromJson: 40 items become 5 days, with the condition at midday', () => {
  const days = forecastFromJson(forecastJson());
  expect(days).toHaveLength(5);
  expect(days[0].condition).toBe('Rain'); // the item at 12:00, not the first one (Clouds)
  expect(days[0].min).toBe(4);
  expect(days[0].max).toBe(13);
});

test('the units are converted only when shown', () => {
  expect(formatTemp(12, true)).toBe('12°');
  expect(formatTemp(12, false)).toBe('54°');
  expect(formatWind(15, true)).toBe('15 km/h');
  expect(formatWind(15, false)).toBe('9 mph');
});

test('fetchCurrent puts the city in the URL, encoded', async () => {
  const fetchMock = fakeServer();
  await fetchCurrent('New York');
  expect(fetchMock.mock.calls[0][0]).toContain('q=New%20York');
});

test('a 404 is not a failure for fetch: we turn it into a message', async () => {
  fakeServer();
  await expect(fetchCurrent('Atlantis')).rejects.toThrow('City "Atlantis" not found.');
});

test('no internet: a message, not a crash', async () => {
  globalThis.fetch = jest.fn(() => Promise.reject(new TypeError('Network request failed')));
  await expect(fetchCurrent('London')).rejects.toThrow('No connection');
});
