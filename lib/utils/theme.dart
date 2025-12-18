import 'package:flutter/material.dart';

class AppColors {
static const bordeaux = Color(0xFF7B1F2D);


  static const gold = Color(0xFFF2C94C);
  static const navy = Color(0xFF001F3F);
  static const Color accent = Color(0xFFFE4C50); 
   static const Color surface = Color(0xFF181818);
}

final lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.bordeaux,
    primary: AppColors.bordeaux,
    secondary: AppColors.navy,
    brightness: Brightness.light,
  ),
  primaryColor: AppColors.bordeaux,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.navy,
    foregroundColor: Colors.white, // ensures title text is visible
    elevation: 2,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black87),
    titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
  ),
  iconTheme: const IconThemeData(color: Colors.black87),
  drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
  useMaterial3: true,
);

// DARK THEME
final darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.bordeaux,
    primary: AppColors.bordeaux,
    secondary: AppColors.navy,
    brightness: Brightness.dark,
  ),
  primaryColor: AppColors.bordeaux,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.navy,
    foregroundColor: Colors.white, // ensures title text is visible
    elevation: 2,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    bodySmall: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF121212)),
  useMaterial3: true,
);
final ThemeData adminTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color.fromARGB(255, 161, 17, 19),
  colorScheme: const ColorScheme.dark(
    primary: Color.fromARGB(255, 141, 28, 30),
    secondary: Color(0xfffe4c50),
  ),
  scaffoldBackgroundColor: const Color(0xff1e1e2c),
  fontFamily: 'Inter',
  useMaterial3: true,
);
