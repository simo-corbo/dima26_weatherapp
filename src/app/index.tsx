// Lab 6: the weather screen of Lab 1, rebuilt in React Native.
// Same screen, same sizes, same colours

// This file is the start of the app. index.ts (made by create-expo-app) imports App from here
// and hands it to React Native. it is the equivalent of Flutter: main() and runApp(const WeatherApp()).

import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context'; // npx expo install react-native-safe-area-context
import { BottomTabBar, GlassIconButton, SearchField, WeatherCard } from './components'; // here we import the components we made
import { skyGradient, text } from './designTokens'; // here we import the design tokens we made, taken from the design contract

// The screen. Flutter: HomeScreen, a StatelessWidget whose build returns a Scaffold.
function HomeScreen() {
  return (
    // the sky behind everything, from edge to edge (also behind the notch and the home bar)
    <View style={styles.sky}>
      {/* SafeAreaView keeps its content away from the notch, the status bar and the home bar.
          Flutter: SafeArea. The padding of 20 on the sides is the Flutter Padding */}
      <SafeAreaView style={styles.safe}>
        {/* the top bar: title on the left, settings on the right.
            Flutter: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween) */}
        <View style={styles.topBar}>
          <Text style={text.screenTitle}>Weather</Text>
          <GlassIconButton icon="settings" />
        </View>
        <View style={{ height: 12 }} />{/* a spacer, in Flutter: SizedBox(height: 12) */}
        <SearchField />{/* the search field, with its glassy background and the search icon */}

        {/* the card in the middle of the free space.
            Flutter: Spacer(), WeatherCard, Spacer(). Here one View with flex: 1 takes all the
            space left, and centres its child: the same result with one element */}
        <View style={styles.middle}>
          <WeatherCard 
            city="London"
            condition="Rain"
            temp={12}
            description="Light rain"
            humidity={80}
            windKmh={15}
            saved={true}
          />{/* this is th weather card with static data, later we will make it dynamic*/}
        </View>{/* here we close the middle view, it has the same principle of HTML */}

        <BottomTabBar />
      </SafeAreaView>
      <StatusBar style="light" />
    </View>
  );
}

// The app. Flutter: WeatherApp with its MaterialApp.
// export default: the ONE thing this file exports by default. index.ts imports it without braces:
//   import App from './App';
export default function App() {
  return (
    // SafeAreaProvider measures the notch and the bars once, for every SafeAreaView inside.
    // It goes at the root, around the whole app.
    <SafeAreaProvider>
      <HomeScreen />
    </SafeAreaProvider>
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
    alignItems: 'center',
    justifyContent: 'center',
  },
});
