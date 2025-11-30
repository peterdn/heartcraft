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

import 'package:heartcraft/widgets/app_initializer.dart';

import 'package:flutter/material.dart';
import 'views/home_screen.dart';
import 'views/character_view_screen.dart';
import 'views/character_creation_screen.dart';
import 'views/compendium_management_screen.dart';

/// Route names used throughout the app
class Routes {
  static const String initializer = '/';
  static const String home = '/home';
  static const String viewCharacter = '/character';
  static const String createCharacter = '/create';
  static const String manageCompendiums = '/manage-compendiums';
}

/// Generate route settings for the app
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.initializer:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AppInitializer(),
        );

      case Routes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );

      case Routes.viewCharacter:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CharacterViewScreen(),
        );

      case Routes.createCharacter:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CharacterCreationScreen(),
        );

      case Routes.manageCompendiums:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CompendiumManagementScreen(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
