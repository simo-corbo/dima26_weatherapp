package com.example.weather

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel

// The first screen: the weather of the chosen city, or the saved cities.
// It doesn't know the other screens: when the user wants one, it calls onSearch, onSettings
// or onOpenCity, and WeatherApp (MainActivity.kt) decides where to go.
@Composable
fun HomeScreen(
    weather: WeatherViewModel,
    onSearch: () -> Unit,
    onSettings: () -> Unit,
    onOpenCity: (String) -> Unit,
) {
    // State that only Home needs. var ... by rememberSaveable { mutableStateOf(...) }:
    // Compose keeps the value between one drawing and the next, and draws Home again when it changes.
    // Saveable: the value also survives a rotation. Flutter: the fields of a State, changed in setState.
    var tab by rememberSaveable { mutableIntStateOf(0) }                // 0 = Home, 1 = Saved
    var selected by rememberSaveable { mutableStateOf<String?>(null) } // wide Saved tab: the city on the right. null = none yet

    // BoxWithConstraints: how much space does Home have? A phone on its side, a tablet,
    // an unfolded phone are all just a bigger maxWidth. Flutter: LayoutBuilder
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(sky())       // the sky behind everything, from edge to edge: day or night
            .safeDrawingPadding(),   // the content stays away from the status bar, the notch and the navigation bar
    ) {
        val wide = maxWidth >= 600.dp // the same breakpoint as in Flutter

        // a row: on a wide screen the tabs move to the left (SideRail), next to the content
        Row(Modifier.padding(horizontal = if (wide) 32.dp else 20.dp)) {
            if (wide) SideRail(activeIndex = tab, onTabPress = { tab = it })

            // weight(1f): the column takes all the width the rail leaves free
            Column(Modifier.weight(1f)) {
                // the top bar: title on the left, settings on the right
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(stringResource(R.string.app_name), style = AppText.ScreenTitle)
                    GlassIconButton(Icons.Rounded.Settings, stringResource(R.string.settings), onSettings)
                }
                Spacer(Modifier.height(12.dp))
                // the search bar opens the picker. The picker changes the shared city, and Home shows it
                SearchBar(onClick = onSearch)
                Spacer(Modifier.height(12.dp))

                // the middle: weight(1f) takes all the height the bars leave free
                if (tab == 0) {
                    CenteredScroll(Modifier.weight(1f)) {
                        CityCard(weather.city, weather)
                    }
                } else if (wide) {
                    // wide Saved tab: master-detail. The list on the left, the selected city on the right
                    Row(Modifier.weight(1f)) {
                        CityList(weather.saved, onPick = { selected = it }, modifier = Modifier.width(260.dp))
                        Spacer(Modifier.width(32.dp))
                        CenteredScroll(Modifier.weight(1f)) {
                            val city = selected // a plain copy: Kotlin can check it for null once and trust it
                            if (city == null) {
                                Text(stringResource(R.string.choose_on_left), style = AppText.Description)
                            } else {
                                CityCard(city, weather)
                            }
                        }
                    }
                } else {
                    // phone Saved tab: just the list. A tap opens the city's own screen
                    CityList(weather.saved, onPick = onOpenCity, modifier = Modifier.weight(1f))
                }

                // on a wide screen the tabs are in the SideRail: no bottom bar
                if (!wide) BottomTabBar(activeIndex = tab, onTabPress = { tab = it })
            }
        }
    }
}

// The whole Home in the editor, on a phone and on a tablet. {} = a function that does nothing.
// viewModel() also works here: the preview gets its own ViewModel.
@Preview(device = "id:pixel_9")
@Preview(device = "id:pixel_tablet")
@Composable
private fun HomeScreenPreview() {
    HomeScreen(viewModel(), onSearch = {}, onSettings = {}, onOpenCity = {})
}
