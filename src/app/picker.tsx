// LAB 7: the city picker: a list of cities, or type any other one.
// Flutter: CityPickerScreen, which gave the city back with Navigator.pop(city).
// Here a screen gives nothing back: it changes the shared city, then goes back. Home reads the city.

import { useRouter } from 'expo-router';
import { FlatList, Pressable, Text } from 'react-native';
import { SearchField, SubScreen } from '../components';
import { text } from '../designTokens';
import { useWeather } from '../state';

const cities = ['Bergamo', 'Milano', 'London', 'Beijing', 'Oslo', 'New York', 'Wonderland'];

export default function PickerScreen() {
  const router = useRouter();       // to move between screens
  const { setCity } = useWeather(); // the shared city

  function pick(city: string) {
    if (city === '') return; // empty text: stay here
    setCity(city);           // the shared city changes: Home will show it...
    router.back();           // ...and we go back to Home
  }

  return (
    <SubScreen title="Choose a city">
      <SearchField onSubmit={pick} />
      <FlatList
        data={cities}
        keyExtractor={(city) => city}
        renderItem={({ item }) => (
          <Pressable onPress={() => pick(item)} style={{ minHeight: 56, justifyContent: 'center' }}>
            <Text style={text.cityName}>{item}</Text>
          </Pressable>
        )}
      />
    </SubScreen>
  );
}
