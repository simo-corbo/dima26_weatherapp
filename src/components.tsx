// The small components of the weather screen: the same pieces as the widgets of Lab 1.
//
// Flutter: a widget is a class (StatelessWidget) with a build method.
// React Native: a component is a FUNCTION. It receives its props (the constructor parameters
// of a Flutter widget) and returns JSX, a description of what to show.
//
// Each component is exported by name: App.tsx imports them with
//   import { WeatherCard, SearchField, ... } from './components';

import { ReactNode, useEffect, useState } from 'react';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, TextInput, View, ViewStyle, useWindowDimensions } from 'react-native';
import { MaterialIcons } from '@react-native-vector-icons/material-icons'; // npx expo install @react-native-vector-icons/material-icons
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors, skyOf, text } from './designTokens';
import { useWeather } from './state';
import { DayForecast, fetchCurrent, fetchCurrentAt, fetchForecast } from './weather'; // LAB 8
import { currentPosition } from './location'; // LAB 8

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
  const { t } = useWeather(); // LAB 8: the labels of the chips, in the app's language
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
        <Pressable onPress={props.onToggleSave} testID="heart">{/* LAB 8: testID: how a test finds it */}
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
      {/* LAB 7: in °F if the user chose it. LAB 8: the conversion moved to formatTemp, the forecast needs it too */}
      <Text style={text.temp}>{formatTemp(props.temp, props.celsius)}</Text>
      <Text style={text.description}>{props.description}</Text>
      <View style={{ height: 16 }} />
      <View style={[styles.row, { flexDirection: stacked ? 'column' : 'row' }]}>
        <InfoChip icon="water-drop" value={`${props.humidity}%`} label={t.humidity} />
        <View style={{ width: 10, height: 10 }} />{/* LAB 7: the gap works in both directions */}
        <InfoChip icon="air" value={formatWind(props.windKmh, props.kmh)} label={t.wind} />
      </View>
    </View>
  );
}

// LAB 8: the units, in one place. The data is always °C and km/h: we convert only to show it,
// so changing the unit never changes the data. Math.round: Dart's .round()
export const formatTemp = (temp: number, celsius: boolean) => `${celsius ? temp : Math.round((temp * 9) / 5 + 32)}°`;
export const formatWind = (kmh: number, useKmh: boolean) => (useKmh ? `${kmh} km/h` : `${Math.round(kmh * 0.621)} mph`);

// LAB 8: the three moments of a request. TypeScript lets us read data or message only in the right moment
type Request<T> = { status: 'loading' } | { status: 'error'; message: string } | { status: 'done'; data: T };

// LAB 8: asks the server when the component appears, and again every time `key` changes (another city).
// `ask` is the function that makes the request: fetchCurrent(city), fetchForecast(city)...
function useRequest<T>(key: string, ask: () => Promise<T>): Request<T> {
  const [request, setRequest] = useState<Request<T>>({ status: 'loading' });
  useEffect(() => {
    let current = true; // false as soon as the key changes or the component disappears
    async function run() {
      setRequest({ status: 'loading' });
      try {
        const data = await ask(); // the component goes on living while we wait
        if (current) setRequest({ status: 'done', data });
      } catch (error) {
        if (current) setRequest({ status: 'error', message: (error as Error).message });
      }
    }
    run();
    // the cleanup: React runs it before the effect runs again, and when the component disappears.
    // An answer that arrives late, for the old city, is thrown away.
    return () => {
      current = false;
    };
    // the key says which request this is. `ask` is a new function at every render: it stays out of the list
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);
  return request;
}

// LAB 8: while we wait for the server: the system's spinner
export function LoadingView() {
  return <ActivityIndicator size="large" color={colors.ink} style={{ padding: 24 }} />;
}

// LAB 8: when the request fails: an icon and a sentence the user understands, never a stack trace
export function ErrorView({ message }: { message: string }) {
  return (
    <View style={{ alignItems: 'center', padding: 24 }}>
      <MaterialIcons name="cloud-off" size={44} color={colors.ink} />
      <View style={{ height: 12 }} />
      <Text style={[text.description, { textAlign: 'center' }]}>{message}</Text>
    </View>
  );
}

// LAB 8: "Updated 12 s ago". A clock that ticks every second, from the moment the weather is shown.
function UpdatedAgo() {
  const { t } = useWeather();
  const [seconds, setSeconds] = useState(0);
  useEffect(() => {
    // (s) => s + 1: "one more than the latest value". The interval keeps the function it got the first
    // time: inside it, `seconds` would stay 0 forever, so seconds + 1 would always give 1
    const id = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => clearInterval(id); // the cleanup: stop the clock when the card goes away
  }, []); // [] : start it once, when the component appears
  return <Text style={text.chipLabel}>{t.updated(seconds)}</Text>;
}

// LAB 7: the card of one city, with its data. It reads the hearts and the units from the shared
// state by itself: Home, the right pane of Saved and the detail screen just give it the city.
// LAB 8: the weather comes from the server. city null = the weather where the phone is.
export function CityCard({ city }: { city: string | null }) {
  const { saved, toggleSaved, celsius, kmh, t } = useWeather();
  const request = useRequest(city ?? 'here', async () => {
    if (city !== null) return fetchCurrent(city);
    const { lat, lon } = await currentPosition(); // first the position, then the weather there
    return fetchCurrentAt(lat, lon);
  });
  if (request.status === 'loading') return <LoadingView />;
  if (request.status === 'error') return <ErrorView message={request.message} />;

  const weather = request.data;
  const name = city ?? weather.name; // where the phone is, the server tells us the city
  return (
    <View style={{ alignItems: 'center' }}>
      <WeatherCard
        city={name}
        condition={weather.condition}
        temp={weather.temp}
        description={t.conditions[weather.condition] ?? weather.condition} // "Rain" -> "Pioggia"; unknown: as it is
        humidity={weather.humidity}
        windKmh={weather.windKmh}
        saved={saved.includes(name)}
        onToggleSave={() => toggleSaved(name)}
        celsius={celsius}
        kmh={kmh}
      />
      <View style={{ height: 12 }} />
      <UpdatedAgo />
    </View>
  );
}

// LAB 8: one day of the forecast: the day, the icon, the max and the min
function DayCard({ label, day, celsius }: { label: string; day: DayForecast; celsius: boolean }) {
  return (
    <View style={{ alignItems: 'center', paddingHorizontal: 8 }}>
      <Text style={text.chipLabel}>{label}</Text>
      <WeatherIcon condition={day.condition} size={24} />
      <Text style={text.chipValue}>{formatTemp(day.max, celsius)}</Text>
      <Text style={text.chipLabel}>{formatTemp(day.min, celsius)}</Text>
    </View>
  );
}

// LAB 8: the next 5 days of a city, under its card (city screen, and right pane of Saved)
export function Forecast({ city }: { city: string }) {
  const { celsius, t } = useWeather();
  const request = useRequest(city, () => fetchForecast(city));
  if (request.status === 'loading') return <LoadingView />;
  if (request.status === 'error') return null; // the card above already says what went wrong
  return (
    <View style={[styles.row, { marginTop: 24 }]}>
      {/* map: one DayCard for each day. Five items, always: no need for a FlatList. key: as in a FlatList */}
      {request.data.map((day, index) => (
        <DayCard
          key={day.date.toISOString()}
          // the first day is "Today"; the others, the short name of the day in the app's language ("Tue", "mar")
          label={index === 0 ? t.today : day.date.toLocaleDateString(t.locale, { weekday: 'short' })}
          day={day}
          celsius={celsius}
        />
      ))}
    </View>
  );
}

// LAB 7: the search bar of Home: only the look of a field. Tapping it opens the picker.
// Flutter: SearchField(onTap: _pickCity)
export function SearchBar({ onPress }: { onPress: () => void }) {
  const { t } = useWeather(); // LAB 8
  return (
    <Pressable onPress={onPress}>
      <GlassCard radius={14} fill={colors.chipFill} style={styles.search}>
        <View style={styles.row}>
          <MaterialIcons name="search" size={18} color={colors.white85} />
          <View style={{ width: 10 }} />
          <Text style={text.searchHint}>{t.searchCity}</Text>
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
  const { t } = useWeather(); // LAB 8
  return (
    <GlassCard radius={14} fill={colors.chipFill} style={styles.search}>
      <View style={styles.row}>
        <MaterialIcons name="search" size={18} color={colors.white85} />
        <View style={{ width: 10 }} />
        {/* Flutter: TextField(onChanged: ..., onSubmitted: ...) */}
        <TextInput
          style={[text.searchHint, styles.input]}
          placeholder={t.searchCity}
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
  const { t } = useWeather(); // LAB 8
  if (cities.length === 0) {
    // LAB 7: flex 1, like the FlatList: the hint takes the free space, so the tab bar stays at the bottom
    return (
      <View style={{ flex: 1 }}>
        <Text style={text.searchHint}>{t.noSaved}</Text>
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
  const { dark } = useWeather(); // LAB 8: the sky, or the night sky
  return (
    <View style={[styles.sky, { backgroundImage: skyOf(dark) }]}>
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
  const { t } = useWeather(); // LAB 8
  return (
    <View style={[styles.row, { justifyContent: 'center' }]}>
      <TabItem icon="home" label={t.home} active={activeIndex === 0} onPress={() => onTabPress(0)} />
      <View style={{ width: 48 }} />
      <TabItem icon="bookmark" label={t.saved} active={activeIndex === 1} onPress={() => onTabPress(1)} />
    </View>
  );
}

// LAB 7: the same two tabs as the BottomTabBar, in a column on the left, for wide screens.
// Same TabItem, same look: only the arrangement changes (a column instead of a row).
export function SideRail({ activeIndex, onTabPress }: { activeIndex: number; onTabPress: (index: number) => void }) {
  const { t } = useWeather(); // LAB 8
  return (
    <View style={{ justifyContent: 'center', paddingRight: 20 }}>
      <TabItem icon="home" label={t.home} active={activeIndex === 0} onPress={() => onTabPress(0)} />
      <View style={{ height: 32 }} />
      <TabItem icon="bookmark" label={t.saved} active={activeIndex === 1} onPress={() => onTabPress(1)} />
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
  sky: { flex: 1 }, // LAB 7: the same sky as Home. LAB 8: the gradient is chosen in SubScreen (day or night)
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
