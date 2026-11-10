// The small components of the weather screen: the same pieces as the widgets of Lab 1.
//
// Flutter: a widget is a class (StatelessWidget) with a build method.
// React Native: a component is a FUNCTION. It receives its props (the constructor parameters
// of a Flutter widget) and returns JSX, a description of what to show.
//
// Each component is exported by name: App.tsx imports them with
//   import { WeatherCard, SearchField, ... } from './components';

import { ReactNode, useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, TextInput, View, ViewStyle, useWindowDimensions } from 'react-native';
import { MaterialIcons } from '@react-native-vector-icons/material-icons'; // npx expo install @react-native-vector-icons/material-icons
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors, skyGradient, text } from './designTokens';
import { useWeather } from './state';

// The names of the Material icons, as TypeScript knows them ('settings', 'search', ...).
// Flutter: Icons.settings_rounded. Here: <MaterialIcons name="settings" />, the same icon set.
type IconName = React.ComponentProps<typeof MaterialIcons>['name'];

// GlassCard 
// The rounded, translucent box that everything sits on.
// Its props are described by a TypeScript type, aka, the parameters of the Flutter constructor.
// ? = optional
type GlassCardProps = {
  children: ReactNode;   // what goes inside. Flutter: `child`. JSX passes it by nesting: <GlassCard>...</GlassCard>
  radius?: number;
  fill?: string;
  style?: ViewStyle;     // extra style from the parent (padding, size)
};


export function GlassCard({ children, radius = 22, fill = colors.glassFill, style }: GlassCardProps) {
  return (
    // style can be a list: later entries win
    // Here the parent's style (e.g. its padding) comes last, so it overrides our padding of 20.
    <View style={[styles.glass, { borderRadius: radius, backgroundColor: fill }, style]}>
      {children}
    </View>
  );
  // Flutter also blurred what's behind (BackdropFilter). Behind our cards there is only the smooth
  // sky gradient, so a blur would change nothing visible: we keep just the fill and the border.
}

// InfoChip
// A small glass chip: an icon, a value and a label ("80%" / "Humidity").
type InfoChipProps = { icon: IconName; value: string; label: string };

export function InfoChip({ icon, value, label }: InfoChipProps) {
  return (
    <GlassCard radius={14} fill={colors.chipFill} style={styles.chip}>

      {/* Flutter: Row. In React Native every View is a column by default: flexDirection 'row' makes a row */}
      <View style={styles.row}>
        <MaterialIcons name={icon} size={16} color={colors.ink} />
        {/* the space between the icon and the texts. Flutter: SizedBox(width: 6) */}
        <View style={{ width: 6 }} />
        <View style={{ alignItems: 'center' }}>
          <Text style={text.chipValue}>{value}</Text>
          <Text style={text.chipLabel}>{label}</Text>
        </View>
      </View>
    </GlassCard>
  );
}

// WeatherIcon
// The big icon of the weather. Flutter used a switch on the condition: here an object
// works as a table, condition -> icon and colour
const conditionIcons: Record<string, { name: IconName; color: string }> = {
  Clear: { name: 'wb-sunny', color: colors.sun },
  Clouds: { name: 'cloud', color: colors.ink },
  Rain: { name: 'water-drop', color: colors.ink },
  Drizzle: { name: 'water-drop', color: colors.ink },
  Thunderstorm: { name: 'bolt', color: colors.ink },
  Snow: { name: 'ac-unit', color: colors.ink },
};

type WeatherIconProps = { condition: string; size?: number };

export function WeatherIcon({ condition, size = 96 }: WeatherIconProps) {
  const icon = conditionIcons[condition] ?? conditionIcons.Clouds; // ?? : as in Dart, "if missing, use this"
  return <MaterialIcons name={icon.name} size={size} color={icon.color} />;
}

// WeatherCard
// The centre of the screen: city and heart, big icon, temperature, description, two chips.
// Same props as the Flutter WeatherCard.
type WeatherCardProps = {
  city: string;
  condition: string;
  temp: number;          // °C. TypeScript has one type for all numbers: number (Dart: int and double)
  description: string;
  humidity: number;      // %
  windKmh: number;
  saved: boolean;
  onToggleSave: () => void; // LAB 7: called when the heart is tapped. Flutter: VoidCallback onToggleSave
  celsius: boolean;         // LAB 7: the units chosen in Settings
  kmh: boolean;
};

export function WeatherCard(props: WeatherCardProps) {
  // here we keep 'props' whole and write props.city, props.temp... (the other form shown in the slides)
  // LAB 7: fontScale is the text size the user chose in the phone's settings (1 = normal).
  // With very big text the two chips don't fit side by side: one above the other instead.
  // Flutter: MediaQuery.textScalerOf(context)
  const { fontScale } = useWindowDimensions();
  const stacked = fontScale > 2;
  return (
    <View style={{ alignItems: 'center' }}>
      <View style={styles.row}>
        <Text style={text.cityName}>{props.city}</Text>
        <View style={{ width: 8 }} />
        {/* LAB 7: Pressable makes what's inside tappable. Flutter: GestureDetector(onTap: ...).
            The card doesn't change saved itself (props are read-only): it asks its parent */}
        <Pressable onPress={props.onToggleSave}>
          {/* { } in JSX: any JavaScript expression. Here a ternary, exactly like Dart's */}
          <MaterialIcons
            name={props.saved ? 'favorite' : 'favorite-border'}
            size={18}
            color={props.saved ? colors.sun : colors.white80}
          />
        </Pressable>
      </View>
      <View style={{ height: 8 }} />
      <WeatherIcon condition={props.condition} size={96} />
      {/* a template string: `${...}` puts a value inside a text. Dart: '$temp°' */}
      {/* LAB 7: in °F if the user chose it. Math.round: Dart's .round() */}
      <Text style={text.temp}>{`${props.celsius ? props.temp : Math.round((props.temp * 9) / 5 + 32)}°`}</Text>
      <Text style={text.description}>{props.description}</Text>
      <View style={{ height: 16 }} />
      <View style={[styles.row, { flexDirection: stacked ? 'column' : 'row' }]}>
        <InfoChip icon="water-drop" value={`${props.humidity}%`} label="Humidity" />
        <View style={{ width: 10, height: 10 }} />{/* LAB 7: the gap works in both directions */}
        <InfoChip
          icon="air"
          value={props.kmh ? `${props.windKmh} km/h` : `${Math.round(props.windKmh * 0.621)} mph`}
          label="Wind"
        />
      </View>
    </View>
  );
}

// LAB 7: the card of one city, with its data. It reads the hearts and the units from the shared
// state by itself: Home, the right pane of Saved and the detail screen just give it the city.
// The weather is still invented: only the city changes.
export function CityCard({ city }: { city: string }) {
  const { saved, toggleSaved, celsius, kmh } = useWeather();
  return (
    <WeatherCard
      city={city}
      condition="Rain"
      temp={12}
      description="Light rain"
      humidity={80}
      windKmh={15}
      saved={saved.includes(city)}
      onToggleSave={() => toggleSaved(city)}
      celsius={celsius}
      kmh={kmh}
    />
  );
}

// LAB 7: the search bar of Home: only the look of a field. Tapping it opens the picker.
// Flutter: SearchField(onTap: _pickCity)
export function SearchBar({ onPress }: { onPress: () => void }) {
  return (
    <Pressable onPress={onPress}>
      <GlassCard radius={14} fill={colors.chipFill} style={styles.search}>
        <View style={styles.row}>
          <MaterialIcons name="search" size={18} color={colors.white85} />
          <View style={{ width: 10 }} />
          <Text style={text.searchHint}>Search city</Text>
        </View>
      </GlassCard>
    </Pressable>
  );
}

// SearchField
// LAB 7: a real field: type a city and press enter on the keyboard. It lives in the picker.
export function SearchField({ onSubmit }: { onSubmit: (city: string) => void }) {
  // LAB 7: what's being typed is local state: only the field needs it, so it stays here.
  // The chosen city is not: HomeScreen gets it through onSubmit.
  const [typed, setTyped] = useState('');
  return (
    <GlassCard radius={14} fill={colors.chipFill} style={styles.search}>
      <View style={styles.row}>
        <MaterialIcons name="search" size={18} color={colors.white85} />
        <View style={{ width: 10 }} />
        {/* Flutter: TextField(onChanged: ..., onSubmitted: ...) */}
        <TextInput
          style={[text.searchHint, styles.input]}
          placeholder="Search city"
          placeholderTextColor={colors.inkHint}
          onChangeText={setTyped}               // every key: keep the text
          onSubmitEditing={() => onSubmit(typed)} // enter: hand the city to the parent
          defaultValue={typed}
        />
      </View>
    </GlassCard>
  );
}

// SavedList
// LAB 7: the saved cities. Flutter: ListView with a ListTile for each city.
// FlatList only builds the rows that are on screen: it needs the data and how to draw one item.
export function SavedList({ cities, onPick }: { cities: string[]; onPick: (city: string) => void }) {
  if (cities.length === 0) {
    // LAB 7: flex 1, like the FlatList: the hint takes the free space, so the tab bar stays at the bottom
    return (
      <View style={{ flex: 1 }}>
        <Text style={text.searchHint}>No saved cities yet: tap the heart.</Text>
      </View>
    );
  }
  return (
    <FlatList
      data={cities}
      keyExtractor={(city) => city} // a unique key for each row: the name of the city
      renderItem={({ item }) => (
        // one row: the name of the city, tappable. Flutter: ListTile(title: Text(city), onTap: ...)
        <Pressable onPress={() => onPick(item)} style={styles.cityRow}>
          <Text style={text.cityName}>{item}</Text>
        </Pressable>
      )}
    />
  );
}

// GlassIconButton
// The 34×34 glass square of the top bar (the settings button).
// LAB 7: now tappable: settings on Home, back on the other screens
export function GlassIconButton({ icon, onPress }: { icon: IconName; onPress: () => void }) {
  // the props type can also be written in place, without a name: { icon: IconName }
  return (
    <Pressable onPress={onPress}>
      <GlassCard radius={12} fill={colors.chipFill} style={styles.iconButton}>
        <MaterialIcons name={icon} size={18} color={colors.ink} />
      </GlassCard>
    </Pressable>
  );
}

// LAB 7: the frame of every screen except Home: the sky, the safe area, and a top bar with
// a back button and the title. Flutter: Scaffold with an AppBar, which adds the back arrow.
export function SubScreen({ title, children }: { title: string; children: ReactNode }) {
  const router = useRouter();
  return (
    <View style={styles.sky}>
      <SafeAreaView style={styles.safe}>
        <View style={styles.row}>
          {/* router.back(): remove this screen from the stack. Flutter: Navigator.pop(context) */}
          <GlassIconButton icon="arrow-back" onPress={() => router.back()} />
          <View style={{ width: 12 }} />
          <Text style={text.screenTitle}>{title}</Text>
        </View>
        <View style={{ height: 12 }} />
        {children}
      </SafeAreaView>
    </View>
  );
}

// BottomTabBar
// Two tabs. Not exported: only BottomTabBar uses TabItem (Flutter: the private _TabItem).
function TabItem({ icon, label, active, onPress }: { icon: IconName; label: string; active: boolean; onPress: () => void }) {
  return (
    // opacity is a style here. Flutter: an Opacity widget around the column
    <Pressable onPress={onPress} style={{ alignItems: 'center', opacity: active ? 1 : 0.55 }}>
      <MaterialIcons name={icon} size={22} color={colors.ink} />
      <View style={{ height: 2 }} />
      <Text style={text.tabLabel}>{label}</Text>
    </Pressable>
  );
}

// LAB 7: the tab bar doesn't know which tab is open: HomeScreen tells it (activeIndex),
// and the bar tells HomeScreen when a tab is tapped (onTabPress). Flutter: onTap: (index) => ...
export function BottomTabBar({ activeIndex, onTabPress }: { activeIndex: number; onTabPress: (index: number) => void }) {
  return (
    <View style={[styles.row, { justifyContent: 'center' }]}>
      <TabItem icon="home" label="Home" active={activeIndex === 0} onPress={() => onTabPress(0)} />
      <View style={{ width: 48 }} />
      <TabItem icon="bookmark" label="Saved" active={activeIndex === 1} onPress={() => onTabPress(1)} />
    </View>
  );
}

// LAB 7: the same two tabs as the BottomTabBar, in a column on the left, for wide screens.
// Same TabItem, same look: only the arrangement changes (a column instead of a row).
export function SideRail({ activeIndex, onTabPress }: { activeIndex: number; onTabPress: (index: number) => void }) {
  return (
    <View style={{ justifyContent: 'center', paddingRight: 20 }}>
      <TabItem icon="home" label="Home" active={activeIndex === 0} onPress={() => onTabPress(0)} />
      <View style={{ height: 32 }} />
      <TabItem icon="bookmark" label="Saved" active={activeIndex === 1} onPress={() => onTabPress(1)} />
    </View>
  );
}

// The styles used more than once, in one place. Sizes have no unit: they are density-independent
// pixels, the logical pixels of Flutter.
const styles = StyleSheet.create({
  glass: {
    padding: 20,
    borderWidth: 1,
    borderColor: colors.glassStroke,
  },
  row: {
    flexDirection: 'row', // the main axis is horizontal
    alignItems: 'center', // the cross axis (vertical): centred. Flutter: crossAxisAlignment.center
  },
  chip: { paddingHorizontal: 13, paddingVertical: 9 },
  search: { paddingHorizontal: 14, paddingVertical: 12 },
  input: { flex: 1, padding: 0, color: colors.ink }, // LAB 7: the field takes the rest of the row; padding 0: no extra space on Android
  sky: { flex: 1, backgroundImage: skyGradient }, // LAB 7: the same sky as Home
  safe: { flex: 1, paddingHorizontal: 20 },
  cityRow: { minHeight: 56, justifyContent: 'center', paddingHorizontal: 16 }, // LAB 7: a row of the saved list, as tall as a ListTile
  iconButton: {
    width: 34,
    height: 34,
    padding: 0,
    alignItems: 'center', // the icon in the middle. Flutter: Center
    justifyContent: 'center',
  },
});
