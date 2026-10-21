import 'package:dima26_weatherapp/design_tokens.dart';
import 'package:dima26_weatherapp/weather_api.dart'; // LAB 3: the REST API (Weather, WeatherService)
import 'package:flutter/material.dart';
import 'dart:ui';

void main () => runApp(const WeatherApp());

// equivalent to 

//void main(){
//  runApp(const WeatherApp()); 
//}

class WeatherApp extends StatelessWidget{
  const WeatherApp({super.key});

  @override
  Widget build (BuildContext context){
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true
      )
    );
  }
}

// here we introduce the stateful widget, because the HomeScreen has a state: the city and the saved cities.
class HomeScreen extends StatefulWidget{ 
  const HomeScreen({super.key});


  // the stateful widget is split in two classes: the widget itself, and the state. The state is where the mutable data is stored.
  // the only mandatory method of the stateful widget is createState(), which returns the state object. 
  @override
  State<HomeScreen> createState() => _HomeScreenState();


  // build was here
}

// this is the state of the HomeScreen. It is a private class (the underscore at the beginning of the name makes it private).
// it is a subclass of State<HomeScreen>, which means it is the state of the HomeScreen widget.
class _HomeScreenState extends State<HomeScreen>{

  // here we consider the tab index of the bottom bar
  int _tab = 0;                         // 0 = Home, 1 = Saved

  // default city is London
  String _city = 'London';              // the city shown on Home
  final Set<String> _savedCities = {};  // the cities with the heart

  // the units. They live here, in HomeScreen, because different widgets need them:
  // the settings screen changes them, the weather cards show them.
  // They are not parent and child, so the state goes up to their common parent (state hoisting)
  bool _celsius = true;  // true = °C, false = °F
  bool _kmh = true;      // true = km/h, false = mph

  // the API. One service, and the Futures we already asked for, one per city.
  // Why keep them? build runs many times (every setState, every rotation): if build called
  // fetchCurrent, every rebuild would send a new request. So we ask once, and keep the Future.
  final _service = WeatherService();
  final Map<String, Future<Weather>> _current = {};
  final Map<String, Future<List<DayForecast>>> _forecasts = {};

  // putIfAbsent: if the city is already in the map, gives back its Future;
  // if not, calls the function (the request), stores the Future, and gives it back.
  Future<Weather> _currentOf(String city) => _current.putIfAbsent(city, () => _service.fetchCurrent(city));
  Future<List<DayForecast>> _forecastOf(String city) => _forecasts.putIfAbsent(city, () => _service.fetchForecast(city));

  // toggles the heart of a city: if it was saved, it is removed; if it was not saved, it is added.
  void _toggleSaved(String city) {
    setState(() {
      if (!_savedCities.add(city)) {
        // add() returns false if it was already present -> it's a "remove".
        _savedCities.remove(city);
      }
    });
  }

  // LAB 3: opens the settings. The units go down in the constructor (data down),
  // the changes come back with two callbacks, which run setState here (events up).
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          celsius: _celsius,
          kmh: _kmh,
          onCelsiusChanged: (celsius) => setState(() => _celsius = celsius),
          onKmhChanged: (kmh) => setState(() => _kmh = kmh),
        ),
      ),
    );
  }

  // Opens the city picker and waits until it's closed.
  // It gives back the chosen city, or null if the user just went back.
  Future<void> _pickCity() async {
    final city = await Navigator.of(context).push<String>(
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
        builder: (context) => CityDetailScreen(
          city: city,
          // mind that we pass the Future with a parameter, there
          current: _currentOf(city),
          forecast: _forecastOf(city),
          // LAB 3: we also pass the units, and the two Futures with its data
          celsius: _celsius,
          kmh: _kmh,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    // same as before
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: skyGradient),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    Text('Weather', style: AppText.screenTitle),
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
                            // LAB 3: the weather arrives later. FutureBuilder builds again when the Future changes:
                            // waiting, then data or error.
                            child: FutureBuilder<Weather>(
                              future: _currentOf(_city),
                              builder: (context, snapshot) {
                                // the request failed: the message of the WeatherException
                                if (snapshot.hasError) return ErrorView(message: '${snapshot.error}');
                                // no data yet: still waiting for the server
                                if (!snapshot.hasData) return const LoadingView();

                                // the data arrived. ! : "I know it's not null", we just checked hasData
                                final weather = snapshot.data!;
                                return WeatherCard(
                                  city: _city,
                                  condition: weather.condition,
                                  temp: weather.temp,
                                  description: weather.description,
                                  humidity: weather.humidity,
                                  windKmh: weather.windKmh,
                                  saved: _savedCities.contains(_city),
                                  onToggleSave: () => _toggleSaved(_city),
                                  celsius: _celsius,
                                  kmh: _kmh,
                                );
                              },
                            ),
                          ),
                        )
                      // Saved tab: the list of saved cities
                      : ListView(
                          children: [
                            for (final city in _savedCities)
                              ListTile(
                                title: Text(city, style: AppText.cityName),
                                onTap: () => _openCity(city),
                              ),
                          ],
                        ),
                ),
                // bottom tab bar now has a onTap function
                // this syntax means that the argument that is passed onto the function (index) is used then to set the state, in particular by
                // setting _tab to index
                BottomTabBar(
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
          )
        )
      )
    );
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
            InfoChip(icon: Icons.water_drop_rounded, value: '$humidity%', label: 'Humidity'),
            const SizedBox(width: 8),
            InfoChip(icon: Icons.air_rounded, value: formatWind(windKmh, kmh), label: 'Wind'),
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
            Text('Search city', style: AppText.searchHint),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabItem(
            icon: Icons.home_rounded, label: 'Home', active: activeIndex == 0,

            // onTap changes the state of the HomeScreen to the index of the tab, which is 0 for the first tab
            // onTap(0) returns the value 0 to the awaiting function in the HomeScreen, which sets the state of the HomeScreen to 0
            onTap: () => onTap(0)),
        const SizedBox(width: 48),
        _TabItem(
            icon: Icons.bookmark_rounded, label: 'Saved', active: activeIndex == 1,
            onTap: () => onTap(1)),
      ],
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
      backgroundColor: AppColors.skyMid,
      // AppBar adds the back arrow by itself, because this screen was pushed
      appBar: AppBar(
        title: const Text('Choose a city'),
        backgroundColor: AppColors.skyMid,
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
                  hintText: 'Or type a city',
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
  // LAB 3: the data, as Futures from HomeScreen, and the units
  final Future<Weather> current;
  final Future<List<DayForecast>> forecast;
  final bool celsius;
  final bool kmh;
  const CityDetailScreen({super.key, required this.city, required this.current, required this.forecast, required this.celsius, required this.kmh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyMid,
      appBar: AppBar(
        title: Text(city),
        backgroundColor: AppColors.skyMid,
        foregroundColor: AppColors.ink,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // LAB 3: two requests, two FutureBuilders: the card and the forecast each appear when their data arrives
              FutureBuilder<Weather>(
                future: current,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return ErrorView(message: '${snapshot.error}');
                  if (!snapshot.hasData) return const LoadingView();
                  final weather = snapshot.data!;
                  return WeatherCard(
                    city: city,
                    condition: weather.condition,
                    temp: weather.temp,
                    description: weather.description,
                    humidity: weather.humidity,
                    windKmh: weather.windKmh,
                    saved: true,
                    celsius: celsius,
                    kmh: kmh,
                  );
                },
              ),
              const SizedBox(height: 24),
              // LAB 3: the next 5 days, one DayCard each
              FutureBuilder<List<DayForecast>>(
                future: forecast,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('${snapshot.error}', style: AppText.description);
                  if (!snapshot.hasData) return const LoadingView();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final day in snapshot.data!) DayCard(day: day, celsius: celsius),
                    ],
                  );
                },
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(day.day, style: AppText.chipLabel),
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
// It doesn't own the units: it receives them (data down) and reports the changes with callbacks (events up).
class SettingsScreen extends StatefulWidget {
  final bool celsius;                        // the units when the screen opens
  final bool kmh;
  final ValueChanged<bool> onCelsiusChanged; // called with the new unit
  final ValueChanged<bool> onKmhChanged;
  const SettingsScreen({super.key, required this.celsius, required this.kmh, required this.onCelsiusChanged, required this.onKmhChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // A copy of the units, for this screen only. Why a copy?
  // HomeScreen's setState rebuilds HomeScreen, not the screens pushed on top of it:
  // without a copy, the switches would keep showing the old unit. So we update both: the copy and HomeScreen.
  // late: "it has no value yet, I promise to give it one before using it" (in initState).
  late bool _celsius;
  late bool _kmh;

  // Notifications and location come in a later lab: for now these switches only change here.
  // Nobody else needs them, so they are local state.
  bool _reminder = true;
  bool _useLocation = false;

  @override
  void initState() {
    super.initState();
    _celsius = widget.celsius; // the starting values come from HomeScreen
    _kmh = widget.kmh;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyMid,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.skyMid,
        foregroundColor: AppColors.ink,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Temperature in °C', style: AppText.cityName),
            value: _celsius,
            onChanged: (celsius) {
              setState(() => _celsius = celsius); // this screen
              widget.onCelsiusChanged(celsius);   // HomeScreen
            },
          ),
          SwitchListTile(
            title: Text('Wind in km/h', style: AppText.cityName),
            value: _kmh,
            onChanged: (kmh) {
              setState(() => _kmh = kmh);
              widget.onKmhChanged(kmh);
            },
          ),
          SwitchListTile(
            title: Text('Daily reminder', style: AppText.cityName),
            value: _reminder,
            onChanged: (value) => setState(() => _reminder = value),
          ),
          SwitchListTile(
            title: Text('Use my location', style: AppText.cityName),
            value: _useLocation,
            onChanged: (value) => setState(() => _useLocation = value),
          ),
        ],
      ),
    );
  }
}
