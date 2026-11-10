// LAB 7: the detail of one city, pushed from the saved list on a phone.
// [name] in the file name is a parameter of the route: '/city/Oslo' opens this screen with name = 'Oslo'.
// Flutter: CityDetailScreen(city: city), the city passed in the constructor.

import { useLocalSearchParams } from 'expo-router';
import { ScrollView, StyleSheet } from 'react-native';
import { CityCard, SubScreen } from '../../components';

export default function CityDetailScreen() {
  // the parameters of the route, read from the URL. <{ name: string }> tells TypeScript what's inside
  const { name } = useLocalSearchParams<{ name: string }>();
  return (
    <SubScreen title={name}>
      <ScrollView style={{ flex: 1 }} contentContainerStyle={styles.centred}>
        <CityCard city={name} />
      </ScrollView>
    </SubScreen>
  );
}

const styles = StyleSheet.create({
  centred: { flexGrow: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 12 },
});
