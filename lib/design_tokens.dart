
// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// The single source of truth for colour and text. Every widget reads from here
// instead of hard-coding hex values, so the look stays consistent.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // private constructor: this class is just a namespace.

  // Sky gradient stops
  static const skyTop = Color(0xFF5AA9F5);
  static const skyMid = Color(0xFF3D86E0);
  static const skyBottom = Color(0xFF2C66BE);

  // Accent + base
  static const sun = Color(0xFFFFD56B);
  static const ink = Color(0xFFFFFFFF);

  // White at the opacities the contract specifies.
  // If your Flutter is older, swap these for `.withOpacity(0.58)` etc.
  static final inkSecondary = Colors.white.withValues(alpha: 0.58);
  static final inkHint = Colors.white.withValues(alpha: 0.50);
  static final body78 = Colors.white.withValues(alpha: 0.78);
  static final glassFill = Colors.white.withValues(alpha: 0.16);
  static final chipFill = Colors.white.withValues(alpha: 0.10);
  static final glassStroke = Colors.white.withValues(alpha: 0.26);

  // Lab 3: the other whites the contract uses
  static final white90 = Colors.white.withValues(alpha: 0.90); // chip icons
  static final white85 = Colors.white.withValues(alpha: 0.85); // search icon
  static final white80 = Colors.white.withValues(alpha: 0.80); // heart, not saved
  static final white70 = Colors.white.withValues(alpha: 0.70); // empty state
  static final hairline = Colors.white.withValues(alpha: 0.13); // dividers in Settings
  static final white92 = Colors.white.withValues(alpha: 0.92); // Lab 4: switch track, on
}

// The full-screen background gradient.
const skyGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.skyTop, AppColors.skyMid, AppColors.skyBottom],
  stops: [0.0, 0.52, 1.0],
);

// Lab 4: dark mode. The same sky, at night: same stops, darker blues.
// Glass, white type and the sun don't change.
const nightTop = Color(0xFF2A3F6B);
const nightMid = Color(0xFF1C2C4F);
const nightBottom = Color(0xFF111B33);

const nightGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [nightTop, nightMid, nightBottom],
  stops: [0.0, 0.52, 1.0],
);

// Lab 4: every screen asks the Theme if we are in dark mode, and picks its colours.
// Theme.of(context) works like MediaQuery.of(context): MaterialApp puts it above every screen.
bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
LinearGradient skyOf(BuildContext context) => isDark(context) ? nightGradient : skyGradient;
Color skyMidOf(BuildContext context) => isDark(context) ? nightMid : AppColors.skyMid;

class AppText {
  AppText._();

  static const screenTitle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const cityName =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const temp = TextStyle(
      fontSize: 38, fontWeight: FontWeight.w200, color: AppColors.ink, height: 1);
  static final description =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.body78);
  static const chipValue =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink);
  static final chipLabel = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.inkSecondary);
  static final searchHint =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.inkHint);
  static const tabLabel =
      TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink);

  // Lab 3: the remaining styles of the contract (§4)
  static const heroTemp = TextStyle(
      fontSize: 56, fontWeight: FontWeight.w200, color: AppColors.ink, height: 1);
  static const savedTitle =
      TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: AppColors.ink);
  static final caption =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.inkSecondary);
  static final sectionLabel = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSecondary, letterSpacing: 1.1);
  static const searchInput =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink);
  // Saved: the temperature on the right of a CityRow
  static const rowTemp =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: AppColors.ink);
  // Detail: the DayCards of the forecast strip
  static final dayName =
      TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.body78);
  static const dayMax =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink);
  // Settings: a row is a label (+ a caption), the footer is the smallest text
  static const settingLabel =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static final settingCaption =
      TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.inkSecondary);
  static final footer = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.55));
}
