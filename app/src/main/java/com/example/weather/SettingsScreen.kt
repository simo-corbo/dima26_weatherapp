package com.example.weather

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp

// Settings. The units are shared (Home and the city screen show them): they live in the ViewModel.
// Flutter: SettingsScreen with SwitchListTile rows inside a GlassCard.
@Composable
fun SettingsScreen(weather: WeatherViewModel, onBack: () -> Unit) {
    SubScreen(title = stringResource(R.string.settings), onBack = onBack) {
        // on a wide screen the rows stay at most 600 wide, in the middle: the label stays close to its switch
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
            GlassCard(
                modifier = Modifier.widthIn(max = 600.dp).fillMaxWidth(),
                padding = PaddingValues(horizontal = 20.dp, vertical = 8.dp),
            ) {
                Column {
                    // the switch shows the value in the ViewModel, and writes the new one there
                    SwitchRow(stringResource(R.string.temperature_celsius), checked = weather.celsius, onCheckedChange = { weather.celsius = it })
                    SwitchRow(stringResource(R.string.wind_kmh), checked = weather.kmh, onCheckedChange = { weather.kmh = it })
                }
            }
        }
    }
}

// one row: the label on the left, the switch on the right. Flutter: SwitchListTile
@Composable
private fun SwitchRow(title: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, style = AppText.CityName)
        // Switch: Material's toggle. checked shows it, onCheckedChange asks to change it
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedTrackColor = AppColors.White80,
                checkedThumbColor = AppColors.SkyMid,
                uncheckedTrackColor = AppColors.ChipFill,
                uncheckedThumbColor = AppColors.Ink,
                uncheckedBorderColor = AppColors.GlassStroke,
            ),
        )
    }
}
