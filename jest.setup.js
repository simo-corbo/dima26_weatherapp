// LAB 8: runs before every test file.
// The tests never use the real disk or the real key: a fake AsyncStorage (in memory) and a fake key.
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock'),
);
process.env.EXPO_PUBLIC_OPENWEATHER_API_KEY = 'test-key';
// No phone, no notifications: a fake module that does nothing (and says yes to the permission)
jest.mock('expo-notifications', () => ({
  setNotificationHandler: jest.fn(),
  setNotificationChannelAsync: jest.fn(),
  requestPermissionsAsync: jest.fn(() => Promise.resolve({ granted: true })),
  scheduleNotificationAsync: jest.fn(),
  cancelScheduledNotificationAsync: jest.fn(),
  AndroidImportance: { DEFAULT: 3 },
  SchedulableTriggerInputTypes: { DAILY: 'daily' },
}));
// findBy... and waitFor wait up to 5 s (default 1 s): the first start of the whole app is slow on a busy computer
require('@testing-library/react-native').configure({ asyncUtilTimeout: 5000 });
