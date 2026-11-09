// The small components of the weather screen: the same pieces as the widgets of Lab 1.
//
// Flutter: a widget is a class (StatelessWidget) with a build method.
// React Native: a component is a FUNCTION. It receives its props (the constructor parameters
// of a Flutter widget) and returns JSX, a description of what to show.
//
// Each component is exported by name: App.tsx imports them with
//   import { WeatherCard, SearchField, ... } from './components';

import { ReactNode } from 'react';
import { StyleSheet, Text, View, ViewStyle } from 'react-native';
import { MaterialIcons } from '@react-native-vector-icons/material-icons'; // npx expo install @react-native-vector-icons/material-icons
import { colors, text } from './designTokens';

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
};

export function WeatherCard(props: WeatherCardProps) {
  // here we keep 'props' whole and write props.city, props.temp... (the other form shown in the slides)
  return (
    <View style={{ alignItems: 'center' }}>
      <View style={styles.row}>
        <Text style={text.cityName}>{props.city}</Text>
        <View style={{ width: 8 }} />
        {/* { } in JSX: any JavaScript expression. Here a ternary, exactly like Dart's */}
        <MaterialIcons
          name={props.saved ? 'favorite' : 'favorite-border'}
          size={18}
          color={props.saved ? colors.sun : colors.white80}
        />
      </View>
      <View style={{ height: 8 }} />
      <WeatherIcon condition={props.condition} size={96} />
      {/* a template string: `${...}` puts a value inside a text. Dart: '$temp°' */}
      <Text style={text.temp}>{`${props.temp}°`}</Text>
      <Text style={text.description}>{props.description}</Text>
      <View style={{ height: 16 }} />
      <View style={styles.row}>
        <InfoChip icon="water-drop" value={`${props.humidity}%`} label="Humidity" />
        <View style={{ width: 10 }} />
        <InfoChip icon="air" value={`${props.windKmh} km/h`} label="Wind" />
      </View>
    </View>
  );
}

// SearchField
// Only the look of a search field, as in Lab 1: tapping it does nothing yet (no state today).
export function SearchField() {
  return (
    <GlassCard radius={14} fill={colors.chipFill} style={styles.search}>
      <View style={styles.row}>
        <MaterialIcons name="search" size={18} color={colors.white85} />
        <View style={{ width: 10 }} />
        <Text style={text.searchHint}>Search city</Text>
      </View>
    </GlassCard>
  );
}

// GlassIconButton
// The 34×34 glass square of the top bar (the settings button).
export function GlassIconButton({ icon }: { icon: IconName }) {
  // the props type can also be written in place, without a name: { icon: IconName }
  return (
    <GlassCard radius={12} fill={colors.chipFill} style={styles.iconButton}>
      <MaterialIcons name={icon} size={18} color={colors.ink} />
    </GlassCard>
  );
}

// BottomTabBar
// Two tabs. Not exported: only BottomTabBar uses TabItem (Flutter: the private _TabItem).
function TabItem({ icon, label, active }: { icon: IconName; label: string; active: boolean }) {
  return (
    // opacity is a style here. Flutter: an Opacity widget around the column
    <View style={{ alignItems: 'center', opacity: active ? 1 : 0.55 }}>
      <MaterialIcons name={icon} size={22} color={colors.ink} />
      <View style={{ height: 2 }} />
      <Text style={text.tabLabel}>{label}</Text>
    </View>
  );
}

export function BottomTabBar({ activeIndex = 0 }: { activeIndex?: number }) {
  return (
    <View style={[styles.row, { justifyContent: 'center' }]}>
      <TabItem icon="home" label="Home" active={activeIndex === 0} />
      <View style={{ width: 48 }} />
      <TabItem icon="bookmark" label="Saved" active={activeIndex === 1} />
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
  iconButton: {
    width: 34,
    height: 34,
    padding: 0,
    alignItems: 'center', // the icon in the middle. Flutter: Center
    justifyContent: 'center',
  },
});
