// LAB 7: Settings. The units are shared (Home and the city screen show them): they come from the Context.
// Flutter: SettingsScreen with SwitchListTile rows inside a GlassCard.
// LAB 8: four more rows: the theme, the language, the daily reminder, my location. All saved on the disk.

import { Alert, Pressable, ScrollView, StyleSheet, Switch, Text, View } from 'react-native';
import { GlassCard, SubScreen } from '../components';
import { colors, text } from '../designTokens';
import { turnOffReminder, turnOnReminder } from '../notifications';
import { useWeather } from '../state';

// one row: the label on the left, the switch on the right. Flutter: SwitchListTile
function SwitchRow({ title, value, onChange }: { title: string; value: boolean; onChange: (value: boolean) => void }) {
  const { dark } = useWeather(); // LAB 8: the knob takes the colour of the sky, or of the night sky
  return (
    <View style={styles.row}>
      <Text style={text.cityName}>{title}</Text>
      {/* Switch: the system toggle (iOS on iPhone, Material on Android). value shows it, onValueChange changes it */}
      <Switch
        accessibilityLabel={title} // LAB 8: what a screen reader says for this switch (and how a test finds it)
        value={value}
        onValueChange={onChange}
        trackColor={{ true: colors.white80, false: colors.chipFill }}
        thumbColor={value ? (dark ? colors.nightMid : colors.skyMid) : colors.ink}
      />
    </View>
  );
}

// LAB 8: one row with a few choices: the label, then one pill per option. The chosen one is filled.
// <T extends string>: the type of the values, chosen by whoever uses the row ('light' | 'dark'...),
// so onChange gives back exactly that type.
function ChoiceRow<T extends string>({ title, value, options, onChange }: {
  title: string;
  value: T;
  options: { value: T; label: string }[];
  onChange: (value: T) => void;
}) {
  return (
    <View style={styles.row}>
      <Text style={text.cityName}>{title}</Text>
      <View style={{ flexDirection: 'row', gap: 6 }}>
        {options.map((option) => (
          <Pressable
            key={option.value}
            onPress={() => onChange(option.value)}
            style={[styles.pill, option.value === value ? styles.pillOn : null]}>
            <Text style={[text.chipValue, option.value === value ? { color: colors.skyBottom } : null]}>{option.label}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

export default function SettingsScreen() {
  const {
    celsius, setCelsius, kmh, setKmh,
    theme, setTheme, language, setLanguage, reminder, setReminder, myLocation, setMyLocation, t,
  } = useWeather();

  // LAB 8: the reminder is more than a value: the phone must schedule (or cancel) the notification,
  // and the user may say no. So this is async: the answer to the permission arrives later.
  async function changeReminder(on: boolean) {
    if (on) {
      const allowed = await turnOnReminder(t.reminderTitle, t.reminderBody, t.reminderConfirm);
      if (!allowed) {
        Alert.alert(t.notificationsDenied); // the system's dialog. The switch stays off
        return;
      }
    } else {
      await turnOffReminder();
    }
    setReminder(on); // saved on the disk, like every setting
  }

  return (
    <SubScreen title={t.settings}>
      {/* on a wide screen the rows stay at most 600 wide, in the middle: the label stays close to its switch */}
      <ScrollView contentContainerStyle={{ alignItems: 'center' }}>
        <GlassCard style={{ width: '100%', maxWidth: 600, paddingVertical: 8 }}>
          <SwitchRow title={t.temperatureInCelsius} value={celsius} onChange={setCelsius} />
          <SwitchRow title={t.windInKmh} value={kmh} onChange={setKmh} />
          <ChoiceRow
            title={t.theme}
            value={theme}
            options={[{ value: 'system', label: t.system }, { value: 'light', label: t.light }, { value: 'dark', label: t.dark }]}
            onChange={setTheme}
          />
          {/* the names of the languages are written in their own language: who can't read English must still find "Italiano" */}
          <ChoiceRow
            title={t.language}
            value={language}
            options={[{ value: 'system', label: t.system }, { value: 'en', label: 'English' }, { value: 'it', label: 'Italiano' }]}
            onChange={setLanguage}
          />
          <SwitchRow title={t.dailyReminder} value={reminder} onChange={changeReminder} />
          {/* the permission is asked on Home, when it needs the position (location.ts) */}
          <SwitchRow title={t.useMyLocation} value={myLocation} onChange={setMyLocation} />
        </GlassCard>
      </ScrollView>
    </SubScreen>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingVertical: 10, gap: 12 },
  pill: { paddingHorizontal: 10, paddingVertical: 6, borderRadius: 12, backgroundColor: colors.chipFill },
  pillOn: { backgroundColor: colors.ink }, // the chosen option: white, with blue text
});
