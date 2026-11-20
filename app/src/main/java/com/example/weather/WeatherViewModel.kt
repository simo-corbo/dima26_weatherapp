package com.example.weather

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel

// The state that several SCREENS read: the chosen city, the saved cities, the units.
// Home, the picker, the city screen and Settings are separate screens: none of them is the parent
// of the others. So the state lives above all of them, in one ViewModel that WeatherApp creates
// (MainActivity.kt) and hands to every screen.
// A ViewModel also survives a rotation: Android rebuilds the activity, the ViewModel stays.
// Flutter: the providers of Riverpod.
class WeatherViewModel : ViewModel() {
    // mutableStateOf: a value Compose watches. When it changes, every composable that read it
    // is drawn again. "by" lets us write city instead of city.value.
    var city by mutableStateOf("London")          // the city shown on Home
    var saved by mutableStateOf(listOf<String>()) // the cities with the heart
        private set                                // only this class changes it: the screens call toggleSaved
    var celsius by mutableStateOf(true)            // true = °C, false = °F
    var kmh by mutableStateOf(true)                // true = km/h, false = mph

    // the heart: if the city was saved, remove it; if not, add it.
    // A Kotlin List can't be changed: minus and plus give back a NEW list, and Compose sees the change.
    fun toggleSaved(c: String) {
        saved = if (c in saved) saved - c else saved + c
    }
}
