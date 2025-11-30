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
import 'package:heartcraft/views/character_advancement_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/character_provider.dart';
import '../providers/edit_mode_provider.dart';
import '../routes.dart';
import 'character_view/resources_tab.dart';
import 'character_view/abilities_tab.dart';
import 'character_view/equipment_tab.dart';
import 'character_view/character_tab.dart';
import 'character_view/notes_tab.dart';
import 'character_view/companion_tab.dart';

/// Screen for viewing and managing an existing character:
/// - Contains tabs for details, abilities, resources, equipment, and notes
/// - Optionally shows a companion tab if the character has a companion
/// - App bar includes buttons for editing, leveling up, and sharing the character
/// - Edit mode propagates to child tabs via EditModeProvider
class CharacterViewScreen extends StatefulWidget {
  const CharacterViewScreen({super.key});

  @override
  CharacterViewScreenState createState() => CharacterViewScreenState();
}

class CharacterViewScreenState extends State<CharacterViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _maxCharacterLevel = 1;

  @override
  void initState() {
    super.initState();
    // If the character has a companion, show the companion tab
    final tabCount = Provider.of<CharacterProvider>(context, listen: false)
                .currentCharacter
                ?.companion !=
            null
        ? 6
        : 5;
    _tabController = TabController(length: tabCount, vsync: this);

    // HACK: remove this once character levelling up is fully implemented
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _maxCharacterLevel = prefs.getInt('maxCharacterLevel') ??
            CharacterProvider.maxCharacterLevel;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditModeProvider(),
      child: Consumer<CharacterProvider>(
        builder: (context, characterProvider, child) {
          final character = characterProvider.currentCharacter;

          if (character == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('No Character'),
              ),
              body: const Center(
                child: Text('No character loaded'),
              ),
            );
          }

          return Consumer<EditModeProvider>(
            builder: (context, editModeProvider, _) {
              return Scaffold(
                appBar: AppBar(
                  // Home button to return to character list
                  leading: IconButton(
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.home,
                        (route) => false,
                      );
                    },
                    tooltip: 'Home',
                  ),
                  title: Text(character.name.isEmpty
                      ? 'Unnamed Character'
                      : character.name),
                  actions: [
                    // Edit mode toggle
                    IconButton(
                      icon: Icon(
                        editModeProvider.editMode ? Icons.check : Icons.edit,
                      ),
                      onPressed: editModeProvider.toggleEditMode,
                      tooltip: editModeProvider.editMode
                          ? 'Save Changes'
                          : 'Edit Character',
                    ),
                    // Level up button
                    IconButton(
                      icon: Icon(
                        Icons.arrow_upward,
                      ),
                      onPressed: character.level < _maxCharacterLevel
                          ? () => {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CharacterAdvancementScreen(),
                                  ),
                                )
                              }
                          : null,
                      tooltip: character.level < _maxCharacterLevel
                          ? 'Level up!'
                          : 'Max Level Reached',
                    ),
                    // Share button
                    IconButton(
                      icon: Icon(
                        Icons.share,
                      ),
                      onPressed: () {
                        characterProvider.shareCharacter(context);
                      },
                      tooltip: 'Share Character',
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.person),
                        text: 'Character',
                      ),
                      Tab(
                        icon: Icon(Icons.flash_on),
                        text: 'Abilities',
                      ),
                      if (character.companion != null)
                        Tab(
                          icon: Icon(Icons.pets),
                          text: 'Companion',
                        ),
                      Tab(
                        icon: Icon(Icons.psychology),
                        text: 'Resources',
                      ),
                      Tab(
                        icon: Icon(Icons.backpack),
                        text: 'Equipment',
                      ),
                      Tab(
                        icon: Icon(Icons.notes),
                        text: 'Notes',
                      ),
                    ],
                  ),
                ),
                body: Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        const CharacterTab(),
                        const AbilitiesTab(),
                        if (character.companion != null)
                          CompanionTab(
                            companion: character.companion!,
                          ),
                        const ResourcesTab(),
                        const EquipmentTab(),
                        const NotesTab(),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
