// LAB 8: the disk. AsyncStorage is the fake one of jest.setup.js: in memory, empty at the start of each test.
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Stored, load, save } from '../src/storage';

beforeEach(() => AsyncStorage.clear());

test('the very first start: nothing saved', async () => {
  expect(await load()).toBeNull();
});

test('what we save is what we load', async () => {
  const stored: Stored = { saved: ['Bergamo'], celsius: false, kmh: true, theme: 'dark', language: 'it', reminder: false, myLocation: true };
  await save(stored);
  expect(await load()).toEqual(stored);
});

test('a broken value does not break the app', async () => {
  await AsyncStorage.setItem('weather_app', '{ not json');
  expect(await load()).toBeNull();
});
