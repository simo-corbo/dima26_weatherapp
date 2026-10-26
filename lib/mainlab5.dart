import 'package:dima26_weatherapp/design_tokens.dart';
import 'package:dima26_weatherapp/weather_api.dart'; // LAB 3: the REST API (Weather, WeatherService)
import 'package:dima26_weatherapp/providers.dart'; // LAB 4: the shared state, with Riverpod
import 'package:dima26_weatherapp/storage.dart'; // LAB 5: the file where we save settings and cities
import 'package:dima26_weatherapp/l10n/app_localizations.dart'; // LAB 5: generated from lib/l10n/*.arb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // LAB 4: flutter pub add flutter_riverpod
import 'package:intl/intl.dart'; // LAB 5: DateFormat, the names of the days in each language
import 'dart:ui';

// LAB 4: ProviderScope is where Riverpod keeps the values of all the providers.
// It must wrap the whole app, so every widget can reach them.
// retry: Riverpod 3 retries a failed request up to 10 times (about 40 seconds).
// A city that doesn't exist won't appear by asking again, so we say "never retry" (null).
// LAB 5: main is async now: before the app starts, we read the file (a Future) and wait for it.
// Reading a small file takes a few milliseconds: meanwhile the phone still shows the launch screen.
Future<void> main() async {
  // LAB 5: path_provider asks iOS or Android for the app's folder, through Flutter's engine.
  // Before runApp the engine isn't started yet: ensureInitialized starts it.
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppStorage.open();
  runApp(ProviderScope(
    retry: (retryCount, error) => null,
    // LAB 5: storageProvider gives this storage, already read, to every provider (see providers.dart)
    overrides: [storageProvider.overrideWithValue(storage)],
    child: const WeatherApp(),
  ));
}

// equivalent to 

//void main(){
//  runApp(const WeatherApp()); 
//}

// LAB 4: dark mode must reach every screen. With hoisting it would have to live here, in WeatherApp,
// and travel down to Settings and back up with callbacks. With Riverpod it lives in settingsProvider,
// and WeatherApp just reads it.
// ConsumerWidget = a StatelessWidget whose build also receives `ref`, to read providers.
class WeatherApp extends ConsumerWidget{
  const WeatherApp({super.key});

  @override
  Widget build (BuildContext context, WidgetRef ref){
    // LAB 4: ref.watch reads the settings AND rebuilds WeatherApp when they change (the theme choice)
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      // LAB 5: the languages of the app, and where their texts come from:
      // ours (AppLocalizations), and Flutter's own (the back button's tooltip, the date pickers...).
      // localizationsDelegates and supportedLocales are generated from the .arb files.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // LAB 5: like themeMode: null = follow the phone; otherwise the language chosen in Settings
      locale: settings.language == 'system' ? null : Locale(settings.language),
      home: const HomeScreen(), // LAB 4: no more values or callbacks to pass down
      // LAB 4: two themes, and themeMode chooses which one is used (as in the lecture).
      // ThemeMode.system: Flutter picks light or dark from the phone, and follows it live.
      // Every screen asks which one with Theme.of(context) (see skyOf in design_tokens.dart)
      theme: ThemeData(fontFamily: 'Inter', useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(fontFamily: 'Inter', useMaterial3: true, brightness: Brightness.dark),
      themeMode: settings.themeMode,
    );
  }
}

// here we introduce the stateful widget, because the HomeScreen has a state: the city and the saved cities.
// LAB 4: ConsumerStatefulWidget = a StatefulWidget that can also read providers (with `ref`).
// HomeScreen still has its own local state (the tab, the city, the selected city): that stays with setState.
class HomeScreen extends ConsumerStatefulWidget{ 
  const HomeScreen({super.key});


  // the stateful widget is split in two classes: the widget itself, and the state. The state is where the mutable data is stored.
  // the only mandatory method of the stateful widget is createState(), which returns the state object. 
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();


  // build was here
}

// this is the state of the HomeScreen. It is a private class (the underscore at the beginning of the name makes it private).
// it is a subclass of State<HomeScreen>, which means it is the state of the HomeScreen widget.
class _HomeScreenState extends ConsumerState<HomeScreen>{

  // here we consider the tab index of the bottom bar
  int _tab = 0;                         // 0 = Home, 1 = Saved

  // default city is London
  // LAB 5: null = the user hasn't picked a city yet. Then Home shows London,
  // or, if "Use my location" is on, the weather where the phone is.
  String? _city;                        // the city shown on Home

  // LAB 4: the saved cities and the units are not here any more: they are shared by several screens,
  // so they moved to providers (providers.dart). What stays here is LOCAL state: only HomeScreen uses it.

  // LAB 4: on a wide screen, Saved shows the list and the detail side by side.
  // The city shown on the right is state: null = nothing chosen yet.
  // It lives here, above the layout: so it survives when the screen rotates and the layout changes.
  String? _selected;

  // LAB 4: the API calls are not here any more either: the Map of Futures and putIfAbsent of Lab 3
  // are replaced by currentWeatherProvider and forecastProvider (providers.dart), which keep the results.

  // LAB 3: opens the settings.
  // LAB 4: no values and no callbacks: SettingsScreen reads and changes settingsProvider by itself.
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // Opens the city picker and waits until it's closed.
  // It gives back the chosen city, or null if the user just went back.
  Future<void> _pickCity() async {
    // LAB 4: on a wide screen the picker is a pop-up (a dialog) in the middle of the screen:
    // a full screen for seven cities would be mostly empty. On a phone it's still a full screen.
    // showDialog is a route too: the picker's pop(city) gives the city back exactly the same way.
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final city = wide
        ? await showDialog<String>(
            context: context,
            builder: (context) => Dialog(
              clipBehavior: Clip.antiAlias, // the rounded corners also cut the screen inside
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: const SizedBox(width: 400, height: 560, child: CityPickerScreen()),
            ),
          )
        : await Navigator.of(context).push<String>(
      // when we create a new screen we use MaterialPageRoute
      MaterialPageRoute(builder: (context) => const CityPickerScreen()),
    );
    if (city == null || city.isEmpty) return; // back without choosing, or empty text
    setState(() => _city = city);
  }

  // Opens the detail screen of a city: the data goes in the constructor.
  void _openCity(String city) {
    Navigator.of(context).push(
      // when we create a new CityDetailScreen we pass the city in the constructor
      // CityDetailScreen is a stateless widget (it doesn't have a state, it just shows the data passed in the constructor)
      MaterialPageRoute(
        // LAB 4: only the city: the weather and the units come from the providers
        builder: (context) => CityDetailScreen(city: city),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    // LAB 4: MediaQuery tells us how big the whole screen is, in logical pixels.
    // 600 is the usual breakpoint: below = phone (compact), from 600 up = tablet, or phone in landscape.
    // sizeOf (not MediaQuery.of): build runs again only when the size changes.
    // LAB 4: a dual-screen phone, or a foldable half open like a book, has a hinge in the middle.
    // If there is one, our screen is only the part on its left (see the end of build).
    final hinge = _verticalHinge(context);
    final width = hinge?.left ?? MediaQuery.sizeOf(context).width;
    final wide = width >= 600;

    // LAB 4: the shared state, from Riverpod. ref.watch = read it, and rebuild when it changes.
    final settings = ref.watch(settingsProvider);
    final saved = ref.watch(savedCitiesProvider);
    // LAB 5: the texts in the user's language. ! : it's never null below MaterialApp
    final l10n = AppLocalizations.of(context)!;

    // LAB 5: which weather Home shows: where the phone is (no city picked, and the setting is on),
    // or the city picked in the search, London by default. Both are an AsyncValue<Weather>: .when below doesn't care.
    final here = _city == null && settings.useLocation;
    final homeWeather = here ? ref.watch(hereWeatherProvider) : ref.watch(currentWeatherProvider(_city ?? 'London'));

    // same as before
    // LAB 4: we keep the screen in a variable, so we can put something next to it
    final screen = Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: skyOf(context)), // LAB 4: sky or night sky
        child: SafeArea(
          child: Padding(
            // LAB 4: on a wide screen (a tablet, or a phone sideways) more room on the sides.
            // 16 above and below on every screen: where there's no inset at the top (a phone sideways,
            // an Android phone without a notch, a window on the web) the top bar doesn't touch the edge.
            padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 20, vertical: 16),
            // LAB 4: on a wide screen the tabs move to the left (SideRail), next to the content
            child: Row(
              children: [
                wide ? SideRail(activeIndex: _tab, onTap: (index) => setState(() => _tab = index)) : const SizedBox.shrink(),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(l10n.appTitle, style: AppText.screenTitle),
                          const Spacer(),
                          // LAB 3: the settings button now opens the settings
                          GlassIconButton(icon: Icons.settings_rounded, onTap: _openSettings)
                        ],
                      ),
                      SizedBox(height: 12),
                      // the search field is a custom widget, which is a GestureDetector that calls _pickCity() when tapped
                      // notice that we pass the function itself, not the result of calling it (no parentheses)

                      // so writing SearchField(onTap: _pickCity()) would be WRONG!!!!!
                      SearchField(onTap: _pickCity),
                      // LAB 4: a little space under the search bar (sideways the content starts right below it)
                      const SizedBox(height: 12),
                      // now we use Expanded for the main content.
                      // it means that the content will take all the remaining space
                      Expanded(

                        // here we use the ternary operator to choose what to show based on the tab index
                        // condition ? case_true : case_false
                        // it is equivalent to:
                        // if (_tab == 0) {
                        //   return Center(child: WeatherCard(...));
                        // } else {
                        //   return ListView(...);
                        // }

                        child: _tab == 0
                            // Home tab: the weather card, in the middle
                            // LAB 3: SingleChildScrollView: if the card is taller than the space (landscape), it scrolls
                            ? Center(
                                child: SingleChildScrollView(
                                  // LAB 3: the weather arrives later.
                                  // LAB 4: ref.watch(currentWeatherProvider(_city)) gives an AsyncValue: loading, error or data.
                                  // .when builds the right widget for each of the three (it replaces FutureBuilder).
                                  child: homeWeather.when( // LAB 5: was ref.watch(currentWeatherProvider(_city))
                                    // no data yet: still waiting for the server
                                    loading: () => const LoadingView(),
                                    // the request failed: the message of the WeatherException
                                    error: (error, stackTrace) => ErrorView(message: '$error'),
                                    // the data arrived
                                    // LAB 5: a block instead of =>, to compute the city first.
                                    // Where the phone is, the server tells us the city's name (weather.name)
                                    data: (weather) {
                                      final city = here ? weather.name : _city ?? 'London';
                                      return WeatherCard(
                                        city: city,
                                        condition: weather.condition,
                                        temp: weather.temp,
                                        // LAB 5: not the server's description ("Light rain", always in English):
                                        // the condition ("Rain"), translated by our .arb files, like the day names
                                        description: l10n.condition(weather.condition),
                                        humidity: weather.humidity,
                                        windKmh: weather.windKmh,
                                        saved: saved.contains(city),
                                        // LAB 4: ref.read(...notifier): we call an operation, we don't need to watch
                                        onToggleSave: () => ref.read(savedCitiesProvider.notifier).toggle(city),
                                        celsius: settings.celsius,
                                        kmh: settings.kmh,
                                      );
                                    },
                                  ),
                                ),
                              )
                            // Saved tab: the list of saved cities
                            // LAB 4: LayoutBuilder tells us how much space THIS part has
                            // (the screen, minus the rail and the padding): is there room for two panes?
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final twoPanes = constraints.maxWidth >= 600;
                                  // LAB 4: the detail goes on the right: in the second pane, or on the other side of a hinge
                                  final detailOnRight = twoPanes || hinge != null;
                                  final list = ListView(
                                    children: [
                                      for (final city in saved)
                                        ListTile(
                                          title: Text(city, style: AppText.cityName),
                                          // LAB 4: detail on the right: show it there (a setState). Otherwise: push it, as in Lab 3
                                          onTap: () => detailOnRight ? setState(() => _selected = city) : _openCity(city),
                                        ),
                                    ],
                                  );
                                  // one pane (phone): just the list, as in Lab 3
                                  if (!twoPanes) return list;

                                  // two panes: the list on the left, the detail of the selected city on the right
                                  return Row(
                                    children: [
                                      SizedBox(width: 260, child: list),
                                      const SizedBox(width: 32),
                                      Expanded(child: _detailPane()),
                                    ],
                                  );
                                },
                              ),
                      ),
                      // bottom tab bar now has a onTap function
                      // this syntax means that the argument that is passed onto the function (index) is used then to set the state, in particular by
                      // setting _tab to index
                      // LAB 4: on a wide screen the tabs are in the SideRail: no bottom bar
                      wide ? const SizedBox.shrink() : BottomTabBar(
                        activeIndex: _tab,

                  
                        // this is a shorthand for:
                        // onTap: (index) {
                        //   setState(() {
                        //     _tab = index;
                        //   });
                        // }
                        // it waits for the value returned by the function onTap(index)
                        // (index) is the argument passed to the function, which is the index of the tab that was tapped
                        onTap: (index) => setState(() => _tab = index),
                      )
                    ],)
                ),
              ],
            ),
          )
        )
      )
    );

    // LAB 4: no hinge: the screen is the whole display, as before
    if (hinge == null) return screen;

    // LAB 4: a hinge: our screen on the left of it, the selected city on the right of it, nothing on the hinge
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: skyOf(context)), // LAB 4: sky or night sky
        child: Row(
          children: [
            SizedBox(width: hinge.left, child: screen),
            SizedBox(width: hinge.width),
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _detailPane(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LAB 4: the right side of master-detail: the selected city, or a hint if there is none yet.
  // Used by the two panes and by the right screen of a dual-screen phone.
  Widget _detailPane() {
    if (_selected == null) {
      return Center(child: Text(AppLocalizations.of(context)!.chooseOnTheLeft, style: AppText.description));
    }
    // the same widget that the detail screen shows, without the screen around it.
    // LAB 4: only the city: CityDetailView reads the weather and the units from the providers.
    return CityDetailView(city: _selected!);
  }

  // LAB 4: MediaQuery also lists the display features: hinges and folds, with their position.
  // We look for one that is vertical (it cuts the screen into left and right) and that we must avoid:
  // a hinge (a real gap, like on the Surface Duo), or a fold that is half open (like a book).
  // A fold that is flat (a foldable fully open) is just a big screen: we ignore it.
  Rect? _verticalHinge(BuildContext context) {
    for (final feature in MediaQuery.displayFeaturesOf(context)) {
      final vertical = feature.bounds.height > feature.bounds.width;
      final mustAvoid = feature.type == DisplayFeatureType.hinge ||
          feature.state == DisplayFeatureState.postureHalfOpened;
      if (vertical && mustAvoid) return feature.bounds;
    }
    return null;
  }
}

// unchanged
class GlassCard extends StatelessWidget {
  final double radius;
  final Color? fill;
  final EdgeInsets padding;
  final Widget child;

  const GlassCard({
    super.key,
    this.radius = 22,
    this.fill,
    this.padding = const EdgeInsets.all(20),
    required this.child
  });

  @override
  Widget build(BuildContext context){
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill ?? AppColors.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: AppColors.glassStroke
            )
          ),
          child: child,
        )
      )
    );
  }
}
// unchanged
class InfoChip extends StatelessWidget{
  final IconData icon;
  final String value;
  final String label;

  const InfoChip({super.key, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context){
    return GlassCard(
      radius: 14,
      fill: AppColors.chipFill,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.ink),
        const SizedBox(width: 6),
        Column(children: [
          Text(value, style: AppText.chipValue),
          Text(label, style: AppText.chipLabel)
        ],)
      ],
      )
    );
  }
} 

// unchanged
class WeatherIcon extends StatelessWidget{
  final double size;
  final String condition;
  
  const WeatherIcon({super.key, required this.size, required this.condition});

  @override
  Widget build(BuildContext context){
    IconData glyph = Icons.sunny;
    Color color = AppColors.sun;

    switch(condition){
      case 'Clear':
        glyph = Icons.sunny;
        color = AppColors.sun;
      case 'Clouds':
        glyph = Icons.cloud_rounded;
        color = AppColors.ink;
      case 'Rain':
      case 'Drizzle':
        glyph = Icons.water_drop_rounded;
        color = AppColors.ink;
      case 'Thunderstorm':
        glyph = Icons.bolt_rounded;
      case 'Snow':
        glyph = Icons.ac_unit_rounded;
        color = AppColors.ink;
    }
  return Icon(glyph, size: size, color: color);
  }
}

  
class WeatherCard extends StatelessWidget{
  final String city;
  final String condition;
  final int temp;
  final String description;
  final int humidity;
  final int windKmh;
  final bool saved;

  // added now: this is the function called when the heart icon is tapped, and handles the saving of the city
  // the ? tells us that it can be null
  // when we declare it in the home page we pass it with _toggleSaved, which in turn changes the state of the homepage and therefore it updates the screen
  // adding the saved cities to the set of saved cities
  // when the widget is built, it checks if the city is in the set of saved cities and shows the heart accordingly

  final VoidCallback? onToggleSave; 
  // void function() 

  // LAB 3: the units. The card doesn't decide them: it receives them from HomeScreen.
  final bool celsius;
  final bool kmh;

  const WeatherCard({super.key, required this.city, required this.condition, required this.temp, required this.description, required this.humidity, required this.windKmh, required this.saved, this.onToggleSave, required this.celsius, required this.kmh});

  @override
  Widget build(BuildContext context){
    final l10n = AppLocalizations.of(context)!; // LAB 5
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(city, style: AppText.cityName),
            const SizedBox(width: 8),
            // the GestureDetector is a widget that detects gestures, in this case a tap
            GestureDetector(
              // onToggleSave is the parameter passed in the constructor, which is a function that handles the saving of the city
              // when we instantiate the WeatherCard in the HomeScreen, we pass _toggleSaved
              // 
              onTap: onToggleSave,
              child: Icon(
                // saved is a boolean, passed in the constructor and it is COMPUTED
                // saved is true if the city is in the set of saved cities, false otherwise
                // saved: _savedCities.contains(_city),
                saved ? Icons.favorite : Icons.favorite_border,
                // if(saved == true) then Icons.favorite else Icons.favorite_border
                size: 18,
                color: saved ? AppColors.sun : Colors.white.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WeatherIcon(size: 96, condition: condition),
        // LAB 3: the temperature in the unit we received
        Text(formatTemp(temp, celsius), style: AppText.temp),
        Text(description, style: AppText.description),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoChip(icon: Icons.water_drop_rounded, value: '$humidity%', label: l10n.humidity),
            const SizedBox(width: 8),
            InfoChip(icon: Icons.air_rounded, value: formatWind(windKmh, kmh), label: l10n.wind),
          ]
        ),

      ]
    );
  }
}


/// SearchField
class SearchField extends StatelessWidget {
  final VoidCallback onTap; // called when the field is tapped
  const SearchField({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // the GestureDetector is a widget that detects gestures, in this case a tap
    return GestureDetector(
      // onTap is the parameter passed in the constructor, which is a function that handles the tap
      // when we instantiate the SearchField in the HomeScreen, we pass _pickCity
      // onTap: _pickCity
      // notice that we pass the function itself, not the result of calling it (no parentheses)
      // pickCity is a function that opens the CityPickerScreen and waits for the result, which is the city chosen by the user
      onTap: onTap,
      child: GlassCard(
        radius: 14,
        fill: AppColors.chipFill,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.searchCity, style: AppText.searchHint), // LAB 5
          ],
        ),
      ),
    );
  }
}


class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem(
      {required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap is the parameter passed in the constructor, which is a function that handles the tap
      // when we instantiate the _TabItem in the BottomTabBar, we pass a function that sets the state of the HomeScreen to the index of the tab
      // in this case the function is () => onTap(0) for the first tab, and () => onTap(1) for the second tab
      // the value in the parentheses is the value that is returned to the awaiting function in the HomeScreen
      onTap: onTap,
      child: Opacity(
      opacity: active ? 1.0 : 0.55, // active = full, inactive = 55%
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.ink),
          const SizedBox(height: 2),
          Text(label, style: AppText.tabLabel),
        ],
      ),
    ),
    );
  }
}

/// The bottom tab bar 
class BottomTabBar extends StatelessWidget {
  final int activeIndex; // which tab is active (from 0 to numOfTabs-1)
  final ValueChanged<int> onTap; // called with the index of the tapped tab
  // equivalent to: final void Function(int) onTap;
  const BottomTabBar({super.key, this.activeIndex = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // LAB 5
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabItem(
            icon: Icons.home_rounded, label: l10n.home, active: activeIndex == 0,

            // onTap changes the state of the HomeScreen to the index of the tab, which is 0 for the first tab
            // onTap(0) returns the value 0 to the awaiting function in the HomeScreen, which sets the state of the HomeScreen to 0
            onTap: () => onTap(0)),
        const SizedBox(width: 48),
        _TabItem(
            icon: Icons.bookmark_rounded, label: l10n.saved, active: activeIndex == 1,
            onTap: () => onTap(1)),
      ],
    );
  }
}

// LAB 4: the same two tabs as the BottomTabBar, in a column on the left, for wide screens.
// Same _TabItem, same look: only the arrangement changes (Column instead of Row).
class SideRail extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;
  const SideRail({super.key, this.activeIndex = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // LAB 5
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TabItem(
              icon: Icons.home_rounded, label: l10n.home, active: activeIndex == 0,
              onTap: () => onTap(0)),
          const SizedBox(height: 32),
          _TabItem(
              icon: Icons.bookmark_rounded, label: l10n.saved, active: activeIndex == 1,
              onTap: () => onTap(1)),
        ],
      ),
    );
  }
}

// unchanged
/// A reusable 34×34 glass square for the top-bar icon buttons (in the home this is the settings button)
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap; // LAB 3: called when the button is tapped, same as SearchField
  const GlassIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: GlassCard(
          radius: 12,
          fill: AppColors.chipFill,
          padding: EdgeInsets.zero,
          child: Center(child: Icon(icon, size: 18, color: AppColors.ink)),
        ),
      ),
    );
  }
}

/// The cities the picker offers.
const cities = ['Bergamo', 'Milano', 'London', 'Beijing', 'Oslo', 'New York', 'Wonderland'];

/// A pushed screen: shows the cities and gives back the one you tap,
/// or the one you type in the text box at the bottom.
class CityPickerScreen extends StatelessWidget {
  const CityPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: skyMidOf(context),
      // AppBar adds the back arrow by itself, because this screen was pushed
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chooseCity), // LAB 5
        backgroundColor: skyMidOf(context),
        foregroundColor: AppColors.ink,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // the predefined cities
            Expanded(
              child: ListView(
                children: [
                  // a list of all the predefined cities
                  for (final city in cities)
                    ListTile(
                      title: Text(city, style: AppText.cityName),
                      onTap: () => Navigator.of(context).pop(city), // gives back the city
                    ),
                ],
              ),
            ),
            // or any other city, typed by the user
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                style: AppText.cityName,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.orTypeCity, // LAB 5
                  hintStyle: AppText.searchHint,
                ),
                // called when the user presses enter on the keyboard 
                onSubmitted: (text) => Navigator.of(context).pop(text), // gives back the typed city
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pushed screen: receives a city in the constructor and shows it.
class CityDetailScreen extends StatelessWidget {
  final String city;
  // LAB 4: just the city. In Lab 3 it also received two Futures and the units from HomeScreen.
  const CityDetailScreen({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: skyMidOf(context),
      appBar: AppBar(
        title: Text(city),
        backgroundColor: skyMidOf(context),
        foregroundColor: AppColors.ink,
      ),
      // LAB 4: the content moved into CityDetailView, so the two-pane layout can show it too
      body: CityDetailView(city: city),
    );
  }
}

// LAB 4: what the detail screen shows (the card and the forecast), without the Scaffold and the AppBar.
// Two homes for one widget: inside CityDetailScreen on a phone, inside the right pane on a wide screen.
// LAB 4: a ConsumerWidget: it reads what it needs from the providers, nobody has to pass it.
class CityDetailView extends ConsumerWidget {
  final String city;
  const CityDetailView({super.key, required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final saved = ref.watch(savedCitiesProvider);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // LAB 3: two requests: the card and the forecast each appear when their data arrives
            // LAB 4: two providers for this city, each shown with .when (loading, error, data)
            ref.watch(currentWeatherProvider(city)).when(
              loading: () => const LoadingView(),
              error: (error, stackTrace) => ErrorView(message: '$error'),
              data: (weather) => WeatherCard(
                city: city,
                condition: weather.condition,
                temp: weather.temp,
                description: AppLocalizations.of(context)!.condition(weather.condition), // LAB 5: as on Home
                humidity: weather.humidity,
                windKmh: weather.windKmh,
                // LAB 4: the heart now works here too: the saved cities are reachable from any screen
                saved: saved.contains(city),
                onToggleSave: () => ref.read(savedCitiesProvider.notifier).toggle(city),
                celsius: settings.celsius,
                kmh: settings.kmh,
              ),
            ),
            const SizedBox(height: 24),
            // LAB 3: the next 5 days, one DayCard each
            ref.watch(forecastProvider(city)).when(
              loading: () => const LoadingView(),
              error: (error, stackTrace) => Text('$error', style: AppText.description),
              data: (days) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final day in days) DayCard(day: day, celsius: settings.celsius),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// LAB 3: the units, in one place. The data is always in °C and km/h:
// we convert only when we show it, so changing the unit never changes the data.
String formatTemp(int celsius, bool useCelsius) =>
    useCelsius ? '$celsius°' : '${(celsius * 9 / 5 + 32).round()}°';

String formatWind(int kmh, bool useKmh) =>
    useKmh ? '$kmh km/h' : '${(kmh * 0.621).round()} mph';

// LAB 3: one day of the forecast: the day, the icon, the max and the min
class DayCard extends StatelessWidget {
  final DayForecast day;
  final bool celsius;
  const DayCard({super.key, required this.day, required this.celsius});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // LAB 5: DateFormat.E = the short name of the day in the app's language: "Tue" in English, "mar" in Italian.
    // The first day keeps its word, translated: "Today" / "Oggi"
    final label = day.day == 'Today' ? l10n.today : DateFormat.E(l10n.localeName).format(day.date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(label, style: AppText.chipLabel),
          const SizedBox(height: 4),
          WeatherIcon(size: 24, condition: day.condition),
          const SizedBox(height: 4),
          Text(formatTemp(day.max, celsius), style: AppText.chipValue),
          Text(formatTemp(day.min, celsius), style: AppText.chipLabel),
        ],
      ),
    );
  }
}

// LAB 3: while we wait for the server
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: CircularProgressIndicator(color: AppColors.ink),
    );
  }
}

// LAB 3: when the request fails: a short message, no stack traces
class ErrorView extends StatelessWidget {
  final String message;
  const ErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.ink),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: AppText.description),
        ],
      ),
    );
  }
}

// LAB 3: the settings. A pushed screen, like the city picker.
// LAB 4: no values in the constructor, no callbacks, no copy of the units (Lab 3 needed one, because
// HomeScreen's setState didn't rebuild a pushed screen). Now the screen watches settingsProvider:
// when a setting changes, every screen that watches it rebuilds, this one included.
// LAB 5: a ConsumerWidget now. Its only local state, the two switches, became real settings
// (Home needs "Use my location", and both must survive a restart): nothing local is left.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // LAB 4: watch to show the settings; read(...notifier) to change them
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!; // LAB 5: every text of this screen
    return Scaffold(
      backgroundColor: skyMidOf(context),
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: skyMidOf(context),
        foregroundColor: AppColors.ink,
      ),
      // LAB 4: on a large screen the rows would stretch across the whole width,
      // with each label very far from its switch. We keep them at most 600 wide, centred.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // LAB 4: the rows inside one glass card, as in the design contract's Settings screen
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                // a transparent Material: the rows draw their tap ripple on it, in front of the glass
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      // LAB 4: GlassSwitchTile (below): the contract's toggle, still an iOS switch on iPhone and a Material one on Android
                      GlassSwitchTile(
                        title: l10n.temperatureInCelsius,
                        value: settings.celsius,
                        onChanged: notifier.setCelsius, // the Notifier changes the state: every screen updates
                      ),
                      GlassSwitchTile(
                        title: l10n.windInKmh,
                        value: settings.kmh,
                        onChanged: notifier.setKmh,
                      ),
                      // LAB 4: the theme: a three-way choice. WeatherApp watches the same provider and switches the theme
                      // Same shape as a switch: value shows the setting, onChanged changes it.
                      ListTile(
                        title: Text(l10n.theme, style: AppText.cityName),
                        trailing: DropdownButton<ThemeMode>(
                          value: settings.themeMode,
                          // white like the rest of Settings, the menu in the colour of the sky, no underline
                          iconEnabledColor: AppColors.ink,
                          dropdownColor: skyMidOf(context),
                          underline: const SizedBox.shrink(),
                          onChanged: (mode) => notifier.setThemeMode(mode!), // ! : a dropdown gives a ThemeMode?, here never null
                          items: [
                            DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system, style: AppText.cityName)),
                            DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light, style: AppText.cityName)),
                            DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark, style: AppText.cityName)),
                          ],
                        ),
                      ),
                      // LAB 5: the language, the same shape as the theme. Saved in the file like every setting.
                      // The names of the languages are written in their own language: who can't read English must still find "Italiano".
                      ListTile(
                        title: Text(l10n.language, style: AppText.cityName),
                        trailing: DropdownButton<String>(
                          value: settings.language,
                          iconEnabledColor: AppColors.ink,
                          dropdownColor: skyMidOf(context),
                          underline: const SizedBox.shrink(),
                          onChanged: (language) => notifier.setLanguage(language!),
                          items: [
                            DropdownMenuItem(value: 'system', child: Text(l10n.system, style: AppText.cityName)),
                            DropdownMenuItem(value: 'en', child: Text('English', style: AppText.cityName)),
                            DropdownMenuItem(value: 'it', child: Text('Italiano', style: AppText.cityName)),
                          ],
                        ),
                      ),
                      // LAB 5: the reminder asks the phone for permission, so the answer arrives later (async).
                      // If the user says no, the switch stays off and a SnackBar explains why.
                      GlassSwitchTile(
                        title: l10n.dailyReminder,
                        value: settings.reminder,
                        onChanged: (value) async {
                          final allowed = await notifier.setReminder(value,
                              title: l10n.reminderTitle, body: l10n.reminderBody, confirmation: l10n.reminderConfirm);
                          // after an await the screen may be closed: check before using its context
                          if (!allowed && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.notificationsDenied)));
                          }
                        },
                      ),
                      // LAB 5: Home watches this setting. The permission is asked by LocationService, on Home
                      GlassSwitchTile(
                        title: l10n.useMyLocation,
                        value: settings.useLocation,
                        onChanged: notifier.setUseLocation,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// LAB 4: the toggle of the design contract, used for every switch in Settings.
// ON: a white track (92%) and a blue knob. OFF: a glass track (white 10% + stroke) and a white knob.
// Inside it's still SwitchListTile.adaptive: an iOS switch on iPhone and iPad, a Material switch on Android,
// both drawn in our colours.
class GlassSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const GlassSwitchTile({super.key, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(title, style: AppText.cityName),
      value: value,
      onChanged: onChanged,
      activeThumbColor: skyMidOf(context), // the knob takes the colour of the sky (or of the night sky)
      activeTrackColor: AppColors.white92,
      inactiveThumbColor: AppColors.ink,
      inactiveTrackColor: AppColors.chipFill,
      trackOutlineColor: WidgetStatePropertyAll(AppColors.glassStroke), // the glass border
    );
  }
}
