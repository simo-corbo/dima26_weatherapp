// Lab 6: the weather screen of Lab 1, rebuilt in React Native.
// Same screen, same sizes, same colours
// LAB 7: the same screen, now interactive: taps, a list, two panes, and other screens to go to.

// LAB 7: this file was App.tsx. With Expo Router it is src/app/index.tsx: the screen at '/',
// the first one the app shows. The app itself (the providers) is in src/app/_layout.tsx.

import { useState } from 'react';
import { useRouter } from 'expo-router';
import { ScrollView, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context'; // npx expo install react-native-safe-area-context
import { BottomTabBar, CityCard, GlassIconButton, SavedList, SearchBar, SideRail } from '../components'; // here we import the components we made
import { skyGradient, text } from '../designTokens'; // here we import the design tokens we made, taken from the design contract
import { useWeather } from '../state';

// The screen. Flutter: HomeScreen, a StatelessWidget whose build returns a Scaffold.
// LAB 7: now it has state, so in Flutter it would be a StatefulWidget with a _HomeScreenState.
// Here the state lives in the same function, with useState.
export default function HomeScreen() {
  // LAB 7: useState gives the current value and the function that changes it.
  // Calling the setter re-renders HomeScreen: the function runs again with the new value.
  // Flutter: the fields of _HomeScreenState, changed inside setState(() { ... }).
  const [tab, setTab] = useState(0);                     // 0 = Home, 1 = Saved. Flutter: int _tab = 0
  const [selected, setSelected] = useState<string | null>(null); // wide Saved tab: the city on the right. null = none yet
  // selected lives here, above the layout: so it survives when the screen rotates or unfolds.

  // LAB 7: the city and the saved cities are needed by other screens too (the picker changes the city,
  // the city screen shows the hearts): they live in the shared state, src/state.tsx
  const { city, saved } = useWeather();
  const router = useRouter(); // to open the other screens

  // LAB 7: the size of the window, updated when it changes (rotation, iPad split view).
  // Flutter: MediaQuery.sizeOf(context).width
  const { width } = useWindowDimensions();
  const wide = width >= 600; // the same breakpoint as Lab 4

  // LAB 7: phone Saved tab: a tap pushes the detail screen of the city.
  // pathname is the route (the file city/[name].tsx), params fills [name]. Flutter: Navigator.push(...)
  function openCity(c: string) {
    router.push({ pathname: '/city/[name]', params: { name: c } });
  }

  return (
    // the sky behind everything, from edge to edge (also behind the notch and the home bar)
    <View style={styles.sky}>
      {/* SafeAreaView keeps its content away from the notch, the status bar and the home bar.
          Flutter: SafeArea. The padding of 20 on the sides is the Flutter Padding */}
      <SafeAreaView style={[styles.safe, { paddingHorizontal: wide ? 32 : 20 }]}>{/* LAB 7: more room on the sides when wide */}
        {/* LAB 7: a row: on a wide screen the tabs move to the left (SideRail), next to the content.
            Flutter: Row(children: [wide ? SideRail(...) : SizedBox.shrink(), Expanded(child: Column(...))]) */}
        <View style={styles.panes}>
          {wide ? <SideRail activeIndex={tab} onTabPress={setTab} /> : null}
          <View style={{ flex: 1 }}>
            {/* the top bar: title on the left, settings on the right.
                Flutter: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween) */}
            <View style={styles.topBar}>
              <Text style={text.screenTitle}>Weather</Text>
              <GlassIconButton icon="settings" onPress={() => router.push('/settings')} />{/* LAB 7 */}
            </View>
            <View style={{ height: 12 }} />{/* a spacer, in Flutter: SizedBox(height: 12) */}
            {/* LAB 7: the search bar opens the picker. The picker changes the shared city, and Home shows it */}
            <SearchBar onPress={() => router.push('/picker')} />
            <View style={{ height: 12 }} />

            {/* the card in the middle of the free space.
                Flutter: Spacer(), WeatherCard, Spacer(). Here one View with flex: 1 takes all the
                space left, and centres its child: the same result with one element.
                LAB 7: a ScrollView around it: if the card is taller than the space (a phone on its side,
                very big text), it scrolls. Flutter: SingleChildScrollView */}
            {tab === 0 ? (
              <ScrollView style={styles.middle} contentContainerStyle={styles.centred}>
                <CityCard city={city} />
              </ScrollView>
            ) : wide ? (
              // LAB 7: wide Saved tab: master-detail. The list on the left, the selected city on the right
              <View style={styles.panes}>
                <View style={{ width: 260 }}>
                  <SavedList cities={saved} onPick={setSelected} />
                </View>
                <View style={{ width: 32 }} />
                <ScrollView style={styles.middle} contentContainerStyle={styles.centred}>
                  {selected === null ? (
                    <Text style={text.description}>Choose a city on the left</Text>
                  ) : (
                    <CityCard city={selected} />
                  )}
                </ScrollView>
              </View>
            ) : (
              // LAB 7: phone Saved tab: just the list. A tap opens the detail screen
              <SavedList cities={saved} onPick={openCity} />
            )}

            {/* LAB 7: on a wide screen the tabs are in the SideRail: no bottom bar */}
            {wide ? null : <BottomTabBar activeIndex={tab} onTabPress={setTab} />}
          </View>
        </View>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  sky: {
    flex: 1, // all the screen: the root has the size of the screen, flex 1 fills it
    backgroundImage: skyGradient,
  },
  safe: {
    flex: 1, // without it, the SafeAreaView would be only as tall as its content
    paddingHorizontal: 20,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between', // main axis: first child at the start, last at the end
    alignItems: 'center',
  },
  middle: {
    flex: 1, // takes all the height that the top bar, the search and the tab bar leave free
  },
  centred: {
    flexGrow: 1, // LAB 7: the content of the ScrollView: at least as tall as the ScrollView, so it can be centred
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
  },
  panes: {
    flex: 1,
    flexDirection: 'row', // LAB 7: side by side: the rail and the content, the list and the detail
  },
});
