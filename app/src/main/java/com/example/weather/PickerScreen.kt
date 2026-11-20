package com.example.weather

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource

// The city picker: a list of cities, or type any other one.
// Flutter: CityPickerScreen, which gave the city back with Navigator.pop(city).
// Here the picker gives the city to WeatherApp through onPick: WeatherApp changes the shared city and goes back.
private val cities = listOf("Bergamo", "Milano", "London", "Beijing", "Oslo", "New York", "Wonderland")

@Composable
fun PickerScreen(onPick: (String) -> Unit, onBack: () -> Unit) {
    SubScreen(title = stringResource(R.string.choose_city), onBack = onBack) {
        SearchField(onSubmit = { city ->
            if (city.isNotEmpty()) onPick(city) // empty text: stay here
        })
        CityList(cities, onPick = onPick)
    }
}
