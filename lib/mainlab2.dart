import 'package:dima26_weatherapp/design_tokens.dart';
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

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  int _tab = 0;                         // 0 = Home, 1 = Saved
  String _city = 'London';              // the city shown on Home
  final Set<String> _savedCities = {};  // the cities with the heart

  void _toggleSaved(String city) {
    setState(() {
      if (!_savedCities.add(city)) {
        // add() returns false if it was already present -> it's a "remove".
        _savedCities.remove(city);
      }
    });
  }

  // Opens the city picker and waits until it's closed.
  // It gives back the chosen city, or null if the user just went back.
  Future<void> _pickCity() async {
    final city = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const CityPickerScreen()),
    );
    if (city == null || city.isEmpty) return; // back without choosing, or empty text
    setState(() => _city = city);
  }

  // Opens the detail screen of a city: the data goes in the constructor.
  void _openCity(String city) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CityDetailScreen(city: city)),
    );
  }

  @override
  Widget build(BuildContext context){
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
                    GlassIconButton(icon: Icons.settings_rounded)
                  ],
                ),
                SizedBox(height: 12),
                SearchField(onTap: _pickCity),
                Expanded(
                  child: _tab == 0
                      // Home tab: the weather card, in the middle
                      ? Center(
                          child: WeatherCard(
                            city: _city,
                            condition: 'Rain',
                            temp: 12,
                            description: 'Light rain',
                            humidity: 80,
                            windKmh: 15,
                            saved: _savedCities.contains(_city),
                            onToggleSave: () => _toggleSaved(_city),
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
                BottomTabBar(
                  activeIndex: _tab,
                  onTap: (index) => setState(() => _tab = index),
                )
              ],)
          )
        )
      )
    );
  }
}

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
  final VoidCallback? onToggleSave; // called when the heart is tapped

  const WeatherCard({super.key, required this.city, required this.condition, required this.temp, required this.description, required this.humidity, required this.windKmh, required this.saved, this.onToggleSave});

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
            GestureDetector(
              onTap: onToggleSave,
              child: Icon(
                saved ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: saved ? AppColors.sun : Colors.white.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WeatherIcon(size: 96, condition: condition),
        Text('${temp.toStringAsFixed(0)}°', style: AppText.temp),
        Text(description, style: AppText.description),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoChip(icon: Icons.water_drop_rounded, value: '$humidity%', label: 'Humidity'),
            const SizedBox(width: 8),
            InfoChip(icon: Icons.air_rounded, value: '$windKmh km/h', label: 'Wind'),
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
    return GestureDetector(
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
  const BottomTabBar({super.key, this.activeIndex = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabItem(
            icon: Icons.home_rounded, label: 'Home', active: activeIndex == 0,
            onTap: () => onTap(0)),
        const SizedBox(width: 48),
        _TabItem(
            icon: Icons.bookmark_rounded, label: 'Saved', active: activeIndex == 1,
            onTap: () => onTap(1)),
      ],
    );
  }
}

/// A reusable 34×34 glass square for the top-bar icon buttons (in the home this is the settings button)
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  const GlassIconButton({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: GlassCard(
        radius: 12,
        fill: AppColors.chipFill,
        padding: EdgeInsets.zero,
        child: Center(child: Icon(icon, size: 18, color: AppColors.ink)),
      ),
    );
  }
}

/// The cities the picker offers.
const cities = ['London', 'Bergamo', 'Milano', 'Oslo', 'New York'];

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
  const CityDetailScreen({super.key, required this.city});

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
        child: WeatherCard(
          city: city,
          condition: 'Rain',
          temp: 12,
          description: 'Light rain',
          humidity: 80,
          windKmh: 15,
          saved: true,
        ),
      ),
    );
  }
}
