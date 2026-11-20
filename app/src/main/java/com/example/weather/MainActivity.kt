package com.example.weather

import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

// The activity: what Android starts when the user taps the app icon (see AndroidManifest.xml).
// ": ComponentActivity()" = it extends ComponentActivity, the activity that can show Compose.
class MainActivity : ComponentActivity() {
    // Android calls onCreate when it creates the activity: at start, and again after a rotation.
    // override: we replace the parent's version, and super.onCreate runs the parent's part first.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // draw behind the status bar and the navigation bar, with white icons on our blue sky
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.dark(Color.TRANSPARENT),
        )
        // setContent: from here on, the activity shows composables. Flutter: runApp(...)
        setContent {
            WeatherApp()
        }
    }
}

// The app: the shared state, and the map of the screens.
// Flutter: MaterialApp with its routes, inside a ProviderScope.
@Composable
fun WeatherApp() {
    // ONE ViewModel for the whole app, created here, above every screen, and handed to each of them.
    // viewModel() creates it the first time and gives back the same one after a rotation.
    val weather: WeatherViewModel = viewModel()

    // the navigation controller: it holds the stack of open screens. Flutter: the Navigator
    val nav = rememberNavController()

    // NavHost: shows the screen on top of the stack. Each composable("...") is a route: a name and its screen.
    // startDestination: the first screen. Flutter: initialRoute
    NavHost(navController = nav, startDestination = "home") {
        composable("home") {
            HomeScreen(
                weather = weather,
                onSearch = { nav.navigate("picker") },                  // push the picker. Flutter: Navigator.pushNamed
                onSettings = { nav.navigate("settings") },
                onOpenCity = { city -> nav.navigate("city/$city") },  // "city/Oslo"
            )
        }
        composable("picker") {
            PickerScreen(
                onPick = { city ->
                    weather.city = city  // the shared city changes: Home will show it...
                    nav.navigateUp()     // ...and we go back to Home
                },
                onBack = { nav.navigateUp() }, // back one screen. Flutter: Navigator.pop
            )
        }
        composable("settings") {
            SettingsScreen(weather, onBack = { nav.navigateUp() })
        }
        // {name} is a parameter of the route: "city/Oslo" opens this screen with name = "Oslo"
        composable("city/{name}") { entry ->
            val name = entry.arguments?.getString("name") ?: "" // ?. and ?: : as in Dart, for values that may be null
            CityScreen(name, weather, onBack = { nav.navigateUp() })
        }
    }
}
