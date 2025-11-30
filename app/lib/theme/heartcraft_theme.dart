// Copyright (c) 2025 Peter Nelson & Heartcraft contributors
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Website: https://heartcraft.app
// GitHub: https://github.com/peterdn/heartcraft
//
// Heartcraft is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Heartcraft is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

import 'package:flutter/material.dart';

/// Purple and gold color scheme Theme
class HeartcraftTheme {
  // Main colors
  static const Color primaryPurple = Color.fromARGB(255, 168, 116, 228);
  static const Color darkPrimaryPurple = Color(0xFF4A148C);
  static const Color darkPurple = Color(0xFF2E0A52);
  static const Color lightPurple = Color.fromARGB(255, 168, 116, 228);
  static const Color gold = Color(0xFFFFC107);

  // Background colors
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardBackgroundColor = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF262626);
  static const Color errorRed = Color(0xFFB00020);

  // Text colors
  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Color(0xFFB3B3B3);
  static const Color darkTextColor = Color.fromARGB(255, 23, 5, 41);

  /// Get the main ThemeData for the app
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardBackgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: gold,
        tertiary: lightPurple,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPurple,
        foregroundColor: primaryTextColor,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: gold,
        unselectedLabelColor: secondaryTextColor,
        indicatorColor: gold,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: primaryTextColor,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: gold,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: primaryTextColor,
        ),
        bodyMedium: TextStyle(
          color: primaryTextColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryPurple,
          foregroundColor: primaryTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: darkPurple,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: gold, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: primaryPurple, width: 1.0),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: darkPrimaryPurple,
        contentTextStyle: TextStyle(color: primaryTextColor),
      ),
    );
  }

  static Color getTraitColorForValue(int value) {
    if (value > 0) return Colors.green;
    if (value == 0) return HeartcraftTheme.gold;
    return Colors.red;
  }
}
