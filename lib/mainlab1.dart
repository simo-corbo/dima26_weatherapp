import 'package:dima26_weatherapp/design_tokens.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

void main() => runApp(const WeatherApp());

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

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: skyGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child:Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Weather', style: AppText.screenTitle),
                    GlassIconButton(icon: Icons.settings_rounded)
                  ],
                ),
                const SizedBox(height: 12),
                const SearchField(),
                const Spacer(),
                WeatherCard(
                  city: 'London',
                  condition: 'Rain',
                  temp: 12,
                  description: 'Light rain',
                  humidity: 80,
                  windKmh: 15,
                  saved: true
                ),
                const Spacer(),
                const BottomTabBar()
              ],)
          )
        )
      )
    );
  }
}


class GlassCard extends StatelessWidget{
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? fill; 

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(20),
    this.fill,
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

  const WeatherIcon({super.key, this.size=96, required this.condition});

  @override
  Widget build(BuildContext context){
    IconData glyph = Icons.cloud_rounded;
    Color color= AppColors.ink;

    switch(condition){
      case 'Clear': 
        glyph = Icons.sunny;
        color=AppColors.sun;
        // no break
      case 'Clouds':
        glyph = Icons.cloud_rounded;
      case 'Rain':
      case 'Drizzle':
        glyph = Icons.water_drop_rounded;
        color = AppColors.ink;
      case 'Thunderstorm':
        glyph = Icons.bolt_rounded;
      case 'Snow':
        glyph = Icons.ac_unit_rounded;
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

  const WeatherCard({super.key, required this.city, required this.condition, required this.temp, required this.description, required this.humidity, required this.windKmh, required this.saved});

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
            Icon(
              saved ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: saved ? AppColors.sun : Colors.white.withValues(alpha: 0.80),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WeatherIcon(condition: condition, size: 96),
        Text('$temp°', style: AppText.temp),
        Text(description, style: AppText.description),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoChip(icon: Icons.water_drop_outlined, value: '$humidity%', label: 'Humidity'),
            const SizedBox(width: 10),
            InfoChip(icon: Icons.air, value: '$windKmh km/h', label: 'Wind'),
          ],
        )
      ],
    );
  }
}

// not live coded 

/// SearchField
class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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
    );
  }
}


class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _TabItem(
      {required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: active ? 1.0 : 0.55, // active = full, inactive = 55%
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.ink),
          const SizedBox(height: 2),
          Text(label, style: AppText.tabLabel),
        ],
      ),
    );
  }
}

/// The bottom tab bar 
class BottomTabBar extends StatelessWidget {
  final int activeIndex; // which tab is active (from 0 to numOfTabs-1)
  const BottomTabBar({super.key, this.activeIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabItem(
            icon: Icons.home_rounded, label: 'Home', active: activeIndex == 0),
        const SizedBox(width: 48),
        _TabItem(
            icon: Icons.bookmark_rounded, label: 'Saved', active: activeIndex == 1),
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
