// lib/utils/theme.dart
import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: Colors.blueGrey[900],
  colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orange),
  scaffoldBackgroundColor: Colors.black87,
  textTheme: TextTheme(
    displayLarge: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: Colors.white70),
  ),
  cardColor: Colors.grey[850],
  // Add more theme configurations as needed
);