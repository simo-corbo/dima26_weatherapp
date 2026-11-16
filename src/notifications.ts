// LAB 8: the daily reminder. A LOCAL notification: our app asks the phone
// "show this text every day at 8:00", and from then on the phone does it by itself,
// even with the app closed. No server involved (that would be a PUSH notification).
import { Platform } from 'react-native';
import * as Notifications from 'expo-notifications'; // npx expo install expo-notifications
import { AndroidImportance } from 'expo-notifications';

const DAILY = 'daily-reminder'; // the identifier: the same one replaces or cancels it

// A notification that arrives while the app is OPEN is hidden by default.
// We want to see it (the confirmation arrives right while the user is in Settings).
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true, // the banner at the top
    shouldShowList: true,   // and in the notification centre
    shouldPlaySound: false,
    shouldSetBadge: false,
  }),
});

// Turns the reminder on. false = the user said no: nothing is scheduled.
// The texts arrive already in the user's language: this file knows no languages.
export async function turnOnReminder(title: string, body: string, confirmation: string): Promise<boolean> {
  // Android only: every notification belongs to a channel, which the user can turn off in the
  // phone's settings ("Daily reminder"). iOS has no channels: there this line must not run.
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync(DAILY, {
      name: 'Daily reminder',
      importance: AndroidImportance.DEFAULT,
    });
  }
  // the system's pop-up the first time; then it remembers the answer
  const { granted } = await Notifications.requestPermissionsAsync();
  if (!granted) return false;

  // every day at 8:00: the phone keeps the appointment, in its own time zone
  await Notifications.scheduleNotificationAsync({
    identifier: DAILY,
    content: { title, body },
    trigger: { type: Notifications.SchedulableTriggerInputTypes.DAILY, hour: 8, minute: 0, channelId: DAILY },
  });
  // and one right now, to confirm (trigger: null = immediately). It also shows that notifications work
  await Notifications.scheduleNotificationAsync({ content: { title, body: confirmation }, trigger: null });
  return true;
}

export async function turnOffReminder(): Promise<void> {
  await Notifications.cancelScheduledNotificationAsync(DAILY);
}
