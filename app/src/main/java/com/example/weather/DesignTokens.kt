package com.example.weather

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// DESIGN TOKENS: the colours and text styles of the design contract, in one place.
// The same values as Flutter's AppColors and AppText.

// object: a class with exactly one instance, made by Kotlin. We read AppColors.Sun directly.
object AppColors {
    // sky gradient stops. 0xFF5AA9F5 is 0xAARRGGBB: FF = fully opaque, then red, green, blue
    val SkyTop = Color(0xFF5AA9F5)
    val SkyMid = Color(0xFF3D86E0)
    val SkyBottom = Color(0xFF2C66BE)

    // accent + base
    val Sun = Color(0xFFFFD56B)
    val Ink = Color.White

    // white at the opacities of the design contract. copy: the same colour with another alpha
    val InkSecondary = Color.White.copy(alpha = 0.58f)
    val InkHint = Color.White.copy(alpha = 0.50f)
    val Body78 = Color.White.copy(alpha = 0.78f)
    val GlassFill = Color.White.copy(alpha = 0.16f)
    val ChipFill = Color.White.copy(alpha = 0.10f)
    val GlassStroke = Color.White.copy(alpha = 0.26f)
    val White85 = Color.White.copy(alpha = 0.85f) // search icon
    val White80 = Color.White.copy(alpha = 0.80f) // heart, not saved

    // dark mode: the same sky at night, darker blues. Glass, white text and the sun don't change
    val NightTop = Color(0xFF2A3F6B)
    val NightMid = Color(0xFF1C2C4F)
    val NightBottom = Color(0xFF111B33)
}

// The full-screen background: top to bottom, three stops (0%, 52%, 100%).
// "0.52f to AppColors.SkyMid" makes a pair: where the stop is, and its colour.
val SkyGradient = Brush.verticalGradient(
    0f to AppColors.SkyTop,
    0.52f to AppColors.SkyMid,
    1f to AppColors.SkyBottom,
)

// The night sky: same stops, night colours
val NightGradient = Brush.verticalGradient(
    0f to AppColors.NightTop,
    0.52f to AppColors.NightMid,
    1f to AppColors.NightBottom,
)

// The sky to paint: night if the phone is in dark mode. isSystemInDarkTheme() reads the phone's
// setting, and the screens using sky() are drawn again when the user switches it.
@Composable
fun sky(): Brush = if (isSystemInDarkTheme()) NightGradient else SkyGradient

// The text styles. sp = the text unit: dp that also follows the text size chosen in the phone's settings.
object AppText {
    val ScreenTitle = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = AppColors.Ink)
    val CityName = TextStyle(fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = AppColors.Ink)
    val Temp = TextStyle(fontSize = 38.sp, fontWeight = FontWeight.ExtraLight, color = AppColors.Ink, lineHeight = 42.sp)
    val Description = TextStyle(fontSize = 13.sp, color = AppColors.Body78)
    val ChipValue = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = AppColors.Ink)
    val ChipLabel = TextStyle(fontSize = 10.sp, color = AppColors.InkSecondary)
    val SearchHint = TextStyle(fontSize = 14.sp, color = AppColors.InkHint)
    val TabLabel = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = AppColors.Ink)
}
