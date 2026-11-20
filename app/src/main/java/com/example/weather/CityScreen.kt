package com.example.weather

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

// The detail of one city, opened from the saved list on a phone. name comes from the route: "city/Oslo".
// Flutter: CityDetailScreen(city: city), the city passed in the constructor.
@Composable
fun CityScreen(name: String, weather: WeatherViewModel, onBack: () -> Unit) {
    SubScreen(title = name, onBack = onBack) {
        CenteredScroll(Modifier.fillMaxSize()) {
            CityCard(name, weather)
        }
    }
}
