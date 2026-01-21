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
import 'package:heartcraft/views/splash_screen.dart';
import 'package:provider/provider.dart';

import '../services/game_data_service.dart';
import '../services/character_data_service.dart';
import '../view_models/character_creation_view_model.dart';
import '../routes.dart';

/// Headless widget to initialise app services and determine entry route
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  AppInitializerState createState() => AppInitializerState();
}

class AppInitializerState extends State<AppInitializer> {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(
        initialization: _initializeApp(),
        nextRouteBuilder: () => _getEntryRoute(context));
  }

  Future<void> _initializeApp() async {
    final gameDataService = context.read<GameDataService>();
    final characterDataService = context.read<CharacterDataService>();

    // Ensure app directories exist and default game data is created and loaded
    await gameDataService.bootstrapBuiltinGameData();
    await gameDataService.loadAllCompendiums();
    await characterDataService.ensureDirectoriesExist();

    if (!mounted) return;

    final characterCreationViewModel =
        Provider.of<CharacterCreationViewModel>(context, listen: false);
    await characterCreationViewModel.initialize();
  }

  Future<String> _getEntryRoute(BuildContext context) async {
    // Check if chjaracter creation is in progress, and route accordingly
    final characterCreationViewModel =
        Provider.of<CharacterCreationViewModel>(context, listen: false);
    final hasProgress =
        await characterCreationViewModel.hasCharacterCreationInProgress();
    return hasProgress ? Routes.createCharacter : Routes.home;
  }
}
