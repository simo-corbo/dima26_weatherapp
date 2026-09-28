
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
}

// The full-screen background gradient.
const skyGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.skyTop, AppColors.skyMid, AppColors.skyBottom],
  stops: [0.0, 0.52, 1.0],
);

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
}
