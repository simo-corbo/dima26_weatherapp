// LAB 7: Settings. The units are shared (Home and the city screen show them): they come from the Context.
// Flutter: SettingsScreen with SwitchListTile rows inside a GlassCard.

import { ScrollView, Switch, Text, View } from 'react-native';
import { GlassCard, SubScreen } from '../components';
import { colors, text } from '../designTokens';
import { useWeather } from '../state';

// one row: the label on the left, the switch on the right. Flutter: SwitchListTile
function SwitchRow({ title, value, onChange }: { title: string; value: boolean; onChange: (value: boolean) => void }) {
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 10 }}>
      <Text style={text.cityName}>{title}</Text>
      {/* Switch: the system toggle (iOS on iPhone, Material on Android). value shows it, onValueChange changes it */}
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ true: colors.white80, false: colors.chipFill }}
        thumbColor={value ? colors.skyMid : colors.ink}
      />
    </View>
  );
}

export default function SettingsScreen() {
  const { celsius, setCelsius, kmh, setKmh } = useWeather();

  return (
    <SubScreen title="Settings">
      {/* on a wide screen the rows stay at most 600 wide, in the middle: the label stays close to its switch */}
      <ScrollView contentContainerStyle={{ alignItems: 'center' }}>
        <GlassCard style={{ width: '100%', maxWidth: 600, paddingVertical: 8 }}>
          <SwitchRow title="Temperature in °C" value={celsius} onChange={setCelsius} />
          <SwitchRow title="Wind in km/h" value={kmh} onChange={setKmh} />
        </GlassCard>
      </ScrollView>
    </SubScreen>
  );
}
