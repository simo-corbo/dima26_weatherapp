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

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(

      )
    );
  }
}
