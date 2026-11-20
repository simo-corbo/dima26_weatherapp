package com.example.weather

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.AcUnit
import androidx.compose.material.icons.rounded.Air
import androidx.compose.material.icons.rounded.Bolt
import androidx.compose.material.icons.rounded.Bookmark
import androidx.compose.material.icons.rounded.Cloud
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.FavoriteBorder
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.WaterDrop
import androidx.compose.material.icons.rounded.WbSunny
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlin.math.roundToInt

// The small components of the weather screen: the same pieces as the widgets of Flutter's Lab 1.
//
// A component is a FUNCTION marked @Composable. Its parameters are what the parent passes in
// (the constructor parameters of a Flutter widget); its body calls other composables, and
// what they draw is what appears. It returns nothing: it describes the UI, it doesn't build an object.

// GlassCard
// The rounded, translucent box that everything sits on.
// Parameters with "= value" have a default: the caller may leave them out.
// content is a composable function: what goes inside. Being the last parameter, the caller can
// write it after the parentheses:  GlassCard(radius = 14.dp) { Text("...") }
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,             // size, position, taps: decided by the parent
    radius: Dp = 22.dp,
    fill: Color = AppColors.GlassFill,
    padding: PaddingValues = PaddingValues(20.dp),
    onClick: (() -> Unit)? = null,             // ? = may be null: most cards can't be tapped
    content: @Composable () -> Unit,
) {
    val shape = RoundedCornerShape(radius)
    Box(
        // A modifier is a chain, applied in order, from the outside in:
        modifier = modifier
            .clip(shape)                                // 1. cut everything to the rounded shape
            .background(fill)                           // 2. paint the fill
            .border(1.dp, AppColors.GlassStroke, shape) // 3. draw the border
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier) // 4. taps, only if wanted
            .padding(padding),                          // 5. the space between the border and the content
    ) {
        content()
    }
    // Flutter also blurred what's behind (BackdropFilter). Behind our cards there is only the smooth
    // sky gradient, so a blur would change nothing visible: we keep just the fill and the border.
}

// InfoChip
// A small glass chip: an icon, a value and a label ("80%" / "Humidity").
@Composable
fun InfoChip(icon: ImageVector, value: String, label: String) {
    GlassCard(radius = 14.dp, fill = AppColors.ChipFill, padding = PaddingValues(horizontal = 13.dp, vertical = 9.dp)) {
        // Row: side by side. verticalAlignment: how they line up across the row
        Row(verticalAlignment = Alignment.CenterVertically) {
            // contentDescription: what a screen reader says. null: decoration, the text says it all
            Icon(icon, contentDescription = null, tint = AppColors.Ink, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(6.dp)) // the space between the icon and the texts. Flutter: SizedBox(width: 6)
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(value, style = AppText.ChipValue)
                Text(label, style = AppText.ChipLabel)
            }
        }
    }
}

// WeatherIcon
// The big icon of the weather. when: Kotlin's switch, and it gives back a value
@Composable
fun WeatherIcon(condition: String, size: Dp = 96.dp) {
    val icon = when (condition) {
        "Clear" -> Icons.Rounded.WbSunny
        "Rain", "Drizzle" -> Icons.Rounded.WaterDrop
        "Thunderstorm" -> Icons.Rounded.Bolt
        "Snow" -> Icons.Rounded.AcUnit
        else -> Icons.Rounded.Cloud
    }
    val color = if (condition == "Clear") AppColors.Sun else AppColors.Ink // if is also a value, like Dart's ?:
    Icon(icon, contentDescription = condition, tint = color, modifier = Modifier.size(size))
}

// WeatherCard
// The centre of the screen: city and heart, big icon, temperature, description, two chips.
// Same parameters as the Flutter WeatherCard.
@Composable
fun WeatherCard(
    city: String,
    condition: String,
    temp: Int,              // °C. Int: a whole number; Double: a number with decimals (as in Dart)
    description: String,
    humidity: Int,          // %
    windKmh: Int,
    saved: Boolean,
    onToggleSave: () -> Unit, // called when the heart is tapped. Flutter: VoidCallback onToggleSave
    celsius: Boolean,         // the units chosen in Settings
    kmh: Boolean,
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(city, style = AppText.CityName)
            Spacer(Modifier.width(8.dp))
            // The card doesn't change saved itself (parameters are read-only): it tells its parent
            Icon(
                if (saved) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder,
                contentDescription = stringResource(if (saved) R.string.remove_saved else R.string.save),
                tint = if (saved) AppColors.Sun else AppColors.White80,
                modifier = Modifier.size(18.dp).clickable(onClick = onToggleSave),
            )
        }
        Spacer(Modifier.height(8.dp))
        WeatherIcon(condition, size = 96.dp)
        // in °F if the user chose it. 5.0 makes the division a Double; roundToInt brings it back to Int
        val shown = if (celsius) temp else (temp * 9 / 5.0 + 32).roundToInt()
        Text("$shown°", style = AppText.Temp) // "$shown°": a value inside a text, as in Dart
        Text(description, style = AppText.Description)
        Spacer(Modifier.height(16.dp))
        // FlowRow: a Row that wraps. If the two chips don't fit side by side (very big text),
        // the second one goes on the next line. The spacing works in both directions.
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(10.dp, Alignment.CenterHorizontally),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            InfoChip(Icons.Rounded.WaterDrop, "$humidity%", stringResource(R.string.humidity))
            InfoChip(
                Icons.Rounded.Air,
                if (kmh) "$windKmh km/h" else "${(windKmh * 0.621).roundToInt()} mph", // ${...}: an expression inside a text
                stringResource(R.string.wind),
            )
        }
    }
}

// The card of one city, with its data. It reads the hearts and the units from the shared state:
// Home, the right pane of Saved and the city screen just give it the city.
// The weather is still invented: only the city changes.
@Composable
fun CityCard(city: String, weather: WeatherViewModel) {
    WeatherCard(
        city = city,
        condition = "Rain",
        temp = 12,
        description = stringResource(R.string.light_rain), // the text in the phone's language: res/values*/strings.xml
        humidity = 80,
        windKmh = 15,
        saved = city in weather.saved,
        onToggleSave = { weather.toggleSaved(city) }, // a lambda: a function written in place
        celsius = weather.celsius,
        kmh = weather.kmh,
    )
}

// The middle of a screen: centres its content, and scrolls when the content is taller than the space
// (a phone on its side, very big text). Flutter: SingleChildScrollView + ConstrainedBox + Center.
@Composable
fun CenteredScroll(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    // BoxWithConstraints tells its content how much space it has: maxWidth, maxHeight
    BoxWithConstraints(modifier) {
        Box(
            modifier = Modifier
                .verticalScroll(rememberScrollState()) // scrollable, and it remembers how far it scrolled
                .fillMaxWidth()
                .heightIn(min = maxHeight)             // at least as tall as the space: so it can be centred
                .padding(vertical = 12.dp),
            contentAlignment = Alignment.Center,
        ) {
            content()
        }
    }
}

// The search bar of Home: only the look of a field. Tapping it opens the picker.
// Flutter: SearchField(onTap: _pickCity)
@Composable
fun SearchBar(onClick: () -> Unit) {
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        radius = 14.dp,
        fill = AppColors.ChipFill,
        padding = PaddingValues(horizontal = 14.dp, vertical = 12.dp),
        onClick = onClick,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.Search, contentDescription = null, tint = AppColors.White85, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(10.dp))
            Text(stringResource(R.string.search_city), style = AppText.SearchHint)
        }
    }
}

// SearchField
// A real field: type a city and press search on the keyboard. It lives in the picker.
@Composable
fun SearchField(onSubmit: (String) -> Unit) {
    // What's being typed is local state: only the field needs it, so it stays here.
    // rememberSaveable: keep the value while this composable is on screen, even across a rotation.
    var typed by rememberSaveable { mutableStateOf("") }
    GlassCard(
        modifier = Modifier.fillMaxWidth(),
        radius = 14.dp,
        fill = AppColors.ChipFill,
        padding = PaddingValues(horizontal = 14.dp, vertical = 12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.Search, contentDescription = null, tint = AppColors.White85, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(10.dp))
            // A field with no look of its own: the GlassCard around it is the look.
            // It shows typed, and asks to change it: Compose doesn't change it by itself.
            BasicTextField(
                value = typed,
                onValueChange = { typed = it },                     // every key: the new text. it = the lambda's parameter
                textStyle = AppText.SearchHint.copy(color = AppColors.Ink),
                cursorBrush = SolidColor(AppColors.Ink),
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search), // the keyboard shows a search key
                keyboardActions = KeyboardActions(onSearch = { onSubmit(typed) }), // ...that hands the city to the parent
                modifier = Modifier.fillMaxWidth(),
                // decorationBox: what is drawn around the text. Here: the hint, while the field is empty
                decorationBox = { field ->
                    if (typed.isEmpty()) Text(stringResource(R.string.search_city), style = AppText.SearchHint)
                    field()
                },
            )
        }
    }
}

// CityList
// A list of cities: tap one to pick it. The picker and the Saved tab both use it.
// LazyColumn builds only the rows that are on screen. Flutter: ListView.builder
@Composable
fun CityList(cities: List<String>, onPick: (String) -> Unit, modifier: Modifier = Modifier) {
    if (cities.isEmpty()) {
        // only the saved list can be empty. The Box takes the space of the list, so the tab bar stays at the bottom
        Box(modifier) {
            Text(stringResource(R.string.no_saved), style = AppText.SearchHint)
        }
        return
    }
    LazyColumn(modifier) {
        // one row for each city. key: a unique name for each row, the city itself
        items(cities, key = { it }) { city ->
            // one row: the name of the city, tappable, as tall as a ListTile. Flutter: ListTile(title: Text(city), onTap: ...)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 56.dp)
                    .clickable { onPick(city) }
                    .padding(horizontal = 16.dp),
                contentAlignment = Alignment.CenterStart,
            ) {
                Text(city, style = AppText.CityName)
            }
        }
    }
}

// GlassIconButton
// The 34×34 glass square of the top bar: settings on Home, back on the other screens.
// 8 + 18 + 8 = 34: the padding centres the icon.
@Composable
fun GlassIconButton(icon: ImageVector, contentDescription: String, onClick: () -> Unit) {
    GlassCard(radius = 12.dp, fill = AppColors.ChipFill, padding = PaddingValues(8.dp), onClick = onClick) {
        Icon(icon, contentDescription = contentDescription, tint = AppColors.Ink, modifier = Modifier.size(18.dp))
    }
}

// The frame of every screen except Home: the sky, the safe area, and a top bar with
// a back button and the title. Flutter: Scaffold with an AppBar, which adds the back arrow.
@Composable
fun SubScreen(title: String, onBack: () -> Unit, content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(sky())          // the sky from edge to edge, also behind the status bar: day or night
            .safeDrawingPadding()       // then keep the content away from the bars, the notch, the keyboard
            .padding(horizontal = 20.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            GlassIconButton(Icons.AutoMirrored.Rounded.ArrowBack, stringResource(R.string.back), onBack)
            Spacer(Modifier.width(12.dp))
            Text(title, style = AppText.ScreenTitle)
        }
        Spacer(Modifier.height(12.dp))
        content()
    }
}

// BottomTabBar
// Two tabs. TabItem is private: only this file can use it (Flutter: the private _TabItem).
@Composable
private fun TabItem(icon: ImageVector, label: String, active: Boolean, onClick: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .alpha(if (active) 1f else 0.55f) // the open tab is bright, the other one dimmed
            .clickable(onClick = onClick),
    ) {
        Icon(icon, contentDescription = null, tint = AppColors.Ink, modifier = Modifier.size(22.dp))
        Spacer(Modifier.height(2.dp))
        Text(label, style = AppText.TabLabel)
    }
}

// The tab bar doesn't know which tab is open: HomeScreen tells it (activeIndex),
// and the bar tells HomeScreen when a tab is tapped (onTabPress). Flutter: onTap: (index) => ...
@Composable
fun BottomTabBar(activeIndex: Int, onTabPress: (Int) -> Unit) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
        TabItem(Icons.Rounded.Home, stringResource(R.string.home), active = activeIndex == 0, onClick = { onTabPress(0) })
        Spacer(Modifier.width(48.dp))
        TabItem(Icons.Rounded.Bookmark, stringResource(R.string.saved), active = activeIndex == 1, onClick = { onTabPress(1) })
    }
}

// The same two tabs as the BottomTabBar, in a column on the left, for wide screens.
// Same TabItem, same look: only the arrangement changes (a Column instead of a Row).
@Composable
fun SideRail(activeIndex: Int, onTabPress: (Int) -> Unit) {
    Column(Modifier.fillMaxHeight().padding(end = 20.dp), verticalArrangement = Arrangement.Center) {
        TabItem(Icons.Rounded.Home, stringResource(R.string.home), active = activeIndex == 0, onClick = { onTabPress(0) })
        Spacer(Modifier.height(32.dp))
        TabItem(Icons.Rounded.Bookmark, stringResource(R.string.saved), active = activeIndex == 1, onClick = { onTabPress(1) })
    }
}

// @Preview: Android Studio draws this function in the editor (Split or Design view), without
// starting the app. Handy to check one component; the parameters are invented.
@Preview(showBackground = true, backgroundColor = 0xFF3D86E0)
@Composable
private fun WeatherCardPreview() {
    WeatherCard(
        city = "London", condition = "Rain", temp = 12, description = "Light rain",
        humidity = 80, windKmh = 15, saved = true, onToggleSave = {}, celsius = true, kmh = true,
    )
}
