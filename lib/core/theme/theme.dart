import 'package:flutter/material.dart';

class AppTheme {
  static const Color purple200 = Color(0xFFBB86FC);
  static const Color purple500 = Color(0xFF6200EE);
  static const Color purple700 = Color(0xFF3700B3);
  static const Color teal200 = Color(0xFF03DAC5);
  static const Color teal700 = Color(0xFF018786);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const String fontFamily = 'SmoochSans';

  static final ThemeData lightTheme = ThemeData(
    primaryColor: purple500,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: fontFamily,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: purple500),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: black),
    ),
  );
}
