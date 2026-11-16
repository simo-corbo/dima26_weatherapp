// LAB 8: tests of the whole app, as a user sees it: the real screens of src/app, the fake server,
// the fake disk. We look for what is on screen (texts) and we act like a user (press).
// renderRouter: Expo Router's version of render: it starts the app at a route, with every screen.
import AsyncStorage from '@react-native-async-storage/async-storage';
import { fireEvent, renderRouter, screen, testRouter, waitFor } from 'expo-router/testing-library';
import { fakeServer } from './fakeServer';

beforeEach(async () => {
  await AsyncStorage.clear(); // every test starts like a new phone
  fakeServer();
});

test('Home shows the weather of London from the server', async () => {
  await renderRouter('./src/app', { initialUrl: '/' });
  expect(await screen.findByText('London')).toBeOnTheScreen(); // findBy: waits until it appears
  expect(screen.getByText('2°')).toBeOnTheScreen();
  expect(screen.getByText('Cloudy')).toBeOnTheScreen();
});

test('a city that does not exist: a message, not a crash', async () => {
  await renderRouter('./src/app', { initialUrl: '/city/Atlantis' });
  expect(await screen.findByText('City "Atlantis" not found.')).toBeOnTheScreen();
});

test('the city screen shows the next 5 days', async () => {
  await renderRouter('./src/app', { initialUrl: '/city/Bergamo' });
  expect(await screen.findByText('Today')).toBeOnTheScreen();
});

test('Italiano: the texts change, and the choice is saved', async () => {
  await renderRouter('./src/app', { initialUrl: '/settings' });
  await fireEvent.press(await screen.findByText('Italiano'));
  expect(await screen.findByText('Impostazioni')).toBeOnTheScreen();
  // the disk answers later: wait until the choice has been written
  await waitFor(() => expect(AsyncStorage.setItem).toHaveBeenLastCalledWith('weather_app', expect.stringContaining('"language":"it"')));
});

test('°F in Settings: the card on Home converts', async () => {
  await renderRouter('./src/app', { initialUrl: '/settings' });
  await fireEvent(await screen.findByLabelText('Temperature in °C'), 'valueChange', false); // the user flips the switch
  await testRouter.navigate('/'); // to Home
  expect(await screen.findByText('36°')).toBeOnTheScreen(); // London: 2 °C = 35.6 °F
});
