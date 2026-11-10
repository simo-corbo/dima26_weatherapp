// LAB 7: the root layout. With Expo Router every file in src/app is a screen, and its path is
// the route: index.tsx = '/', picker.tsx = '/picker', city/[name].tsx = '/city/London'.
// _layout.tsx is not a screen: it wraps them. Here it says HOW they are shown: a Stack, where
// a new screen goes on top of the previous one and "back" removes it.
// Flutter: MaterialApp with Navigator.push / Navigator.pop.

import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { WeatherProvider } from '../state';

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      {/* the shared state around the Stack: every screen can read it */}
      <WeatherProvider>
        {/* headerShown: false: no system header, each screen draws its own top bar, as in the design */}
        <Stack screenOptions={{ headerShown: false }} />
      </WeatherProvider>
      <StatusBar style="light" />
    </SafeAreaProvider>
  );
}
