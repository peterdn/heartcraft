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
import 'package:flutter/services.dart';
import 'package:heartcraft/services/character_data_service.dart';
import 'package:heartcraft/services/game_data_service.dart';
import 'package:heartcraft/services/portrait_service.dart';
import 'package:provider/provider.dart';
import 'theme/heartcraft_theme.dart';
import 'view_models/character_creation_view_model.dart';
import 'view_models/character_view_model.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const HeartcraftApp());
}

class HeartcraftApp extends StatefulWidget {
  const HeartcraftApp({super.key});

  @override
  State<HeartcraftApp> createState() => _HeartcraftAppState();
}

class _HeartcraftAppState extends State<HeartcraftApp> {
  late final GameDataService gameDataService;
  late final CharacterDataService characterDataService;
  late final PortraitService portraitService;

  @override
  void initState() {
    super.initState();
    gameDataService = GameDataService();
    characterDataService =
        CharacterDataService(gameDataService: gameDataService);
    portraitService = PortraitService();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => gameDataService),
        Provider(create: (_) => characterDataService),
        Provider(create: (_) => portraitService),
        ChangeNotifierProvider(
            create: (_) => CharacterViewModel(
                dataService: characterDataService,
                portraitService: portraitService)),
        ChangeNotifierProvider(
            create: (_) =>
                CharacterCreationViewModel(gameDataService: gameDataService)),
      ],
      child: MaterialApp(
        title: 'Heartcraft',
        theme: HeartcraftTheme.themeData,
        initialRoute: Routes.initializer,
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            SafeArea(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
