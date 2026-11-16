// LAB 8: the shared state and the disk together. Not the whole app: the provider and one card,
// rendered twice, like two starts of the app. render: the plain one of React Native Testing Library.
import AsyncStorage from '@react-native-async-storage/async-storage';
import { fireEvent, render, screen } from '@testing-library/react-native';
import { CityCard, SavedList } from '../src/components';
import { WeatherProvider, useWeather } from '../src/state';
import { fakeServer } from './fakeServer';

beforeEach(async () => {
  await AsyncStorage.clear();
  fakeServer();
});

test('the hearts survive a restart', async () => {
  // render, press and unmount are async: always await them, or their work spills into the next step
  const first = await render(<WeatherProvider><CityCard city="London" /></WeatherProvider>);
  await fireEvent.press(await screen.findByTestId('heart')); // save London
  expect(AsyncStorage.setItem).toHaveBeenLastCalledWith('weather_app', expect.stringContaining('"saved":["London"]'));
  await first.unmount(); // the app is closed: everything in RAM is gone

  await render(<WeatherProvider><SavedCities /></WeatherProvider>); // a new start: it reads the disk
  expect(await screen.findByText('London')).toBeOnTheScreen(); // London is in the saved list
});

// the saved list, read from the shared state: what the Saved tab shows
function SavedCities() {
  const { saved } = useWeather();
  return <SavedList cities={saved} onPick={() => {}} />;
}
