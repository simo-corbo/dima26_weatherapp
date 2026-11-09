// DESIGN TOKENS

// Flutter: classes AppColors and AppText with static fields.
// React Native: plain JavaScript objects, exported by name (named exports).
// Another file imports them with:  import { colors, text } from './designTokens';

import { StyleSheet } from 'react-native';

export const colors = {
  // sky gradient stops
  skyTop: '#5AA9F5',
  skyMid: '#3D86E0',
  skyBottom: '#2C66BE',

  // accent + base
  sun: '#FFD56B',
  ink: '#FFFFFF',

  // white at the opacities of the design contract.
  // Flutter: Colors.white.withValues(alpha: 0.58). Here: a CSS colour with alpha, as on the web
  inkSecondary: 'rgba(255, 255, 255, 0.58)',
  inkHint: 'rgba(255, 255, 255, 0.50)',
  body78: 'rgba(255, 255, 255, 0.78)',
  glassFill: 'rgba(255, 255, 255, 0.16)',
  chipFill: 'rgba(255, 255, 255, 0.10)',
  glassStroke: 'rgba(255, 255, 255, 0.26)',
  white85: 'rgba(255, 255, 255, 0.85)', // search icon
  white80: 'rgba(255, 255, 255, 0.80)', // heart, not saved
};

// The full-screen background: top to bottom, three stops (0%, 52%, 100%).
// Flutter: a LinearGradient in a BoxDecoration. React Native: a CSS gradient string,
// given to the style property backgroundImage (as in the professor's slides, "Variation III").
export const skyGradient =
  `linear-gradient(180deg, ${colors.skyTop} 0%, ${colors.skyMid} 52%, ${colors.skyBottom} 100%)`;

// The text styles. StyleSheet.create checks the names and values once, when the file is loaded.
// Flutter: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ...)
// React Native: the same three, camelCase as in CSS. fontWeight is a string: '600'
export const text = StyleSheet.create({
  screenTitle: { fontSize: 16, fontWeight: '600', color: colors.ink },
  cityName: { fontSize: 15, fontWeight: '600', color: colors.ink },
  temp: { fontSize: 38, fontWeight: '200', color: colors.ink, lineHeight: 42 },
  description: { fontSize: 13, fontWeight: '400', color: colors.body78 },
  chipValue: { fontSize: 13, fontWeight: '600', color: colors.ink },
  chipLabel: { fontSize: 10, fontWeight: '400', color: colors.inkSecondary },
  searchHint: { fontSize: 14, fontWeight: '400', color: colors.inkHint },
  tabLabel: { fontSize: 11, fontWeight: '600', color: colors.ink },
});
