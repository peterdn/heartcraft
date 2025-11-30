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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heartcraft/services/portrait_service.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../services/character_data_service.dart';
import '../services/game_data_service.dart';
import '../providers/character_creation_provider.dart';
import '../models/character_summary.dart';
import '../theme/heartcraft_theme.dart';
import '../routes.dart';

/// The home screen showing character tiles and
/// character/compendium management/creation options
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late final CharacterDataService _dataService;

  List<CharacterSummary>? _characters;

  final Set<String> _selectedCharacterIds = {};
  bool _isSelectionMode = false;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dataService =
        CharacterDataService(gameDataService: context.read<GameDataService>());
    _loadCharacters();
  }

  // ******** Build methods ********

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedCharacterIds.length} selected')
            : const Text('Heartcraft'),
        centerTitle: true,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: _selectedCharacterIds.isEmpty
                      ? null
                      : _deleteSelectedCharacters,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.file_upload),
                  tooltip: 'Import Character',
                  onPressed: () {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    _dataService.importCharacter().then((character) {
                      if (character == null) return;
                      _loadCharacters();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content:
                              Text('Successfully imported ${character.name}!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }).catchError((e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to import character: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.storage),
                  tooltip: 'Manage Compendiums',
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.manageCompendiums)
                        .then((hasChanges) {
                      // Reload compendiums and characters if changes were made
                      // TODO: should this be handled via a provider instead?
                      if (hasChanges == true) {
                        _reloadData();
                      }
                    });
                  },
                )
              ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCharacters,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildCharacterGrid()),
        ],
      ),
    );
  }

  Widget _buildCharacterGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount:
          (_characters?.length ?? 0) + 1, // Add 1 for the "create new" tile
      itemBuilder: (context, index) {
        // Last tile is "Create New Character"
        if (index == _characters!.length) {
          return _buildCreateNewTile();
        }

        final character = _characters![index];
        return _buildCharacterTile(character);
      },
    );
  }

  Widget _buildCharacterTile(CharacterSummary character) {
    final isSelected = _selectedCharacterIds.contains(character.id);

    return InkWell(
      onTap: () async {
        if (_isSelectionMode) {
          _toggleSelection(character.id);
        } else {
          // Load the character into the provider and navigate to character screen
          final provider =
              Provider.of<CharacterProvider>(context, listen: false);
          final navigator = Navigator.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          try {
            await provider.loadCharacter(character.id);
            if (!mounted) return;
            navigator.pushNamed(Routes.viewCharacter).then((onValue) {
              // Refresh character list when returning from character view
              _loadCharacters();
            });
          } catch (e) {
            if (!mounted) return;
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Failed to load character: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(character.id);
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(
                  color: HeartcraftTheme.gold,
                  width: 3,
                )
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            SizedBox(
              height: 320,
              child: _CharacterTileBackground(
                character: character,
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: HeartcraftTheme.gold,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNewTile() {
    return InkWell(
      onTap: () {
        Provider.of<CharacterCreationProvider>(context, listen: false)
            .startNewCharacter();
        Navigator.pushNamed(context, Routes.createCharacter).then((value) => {
              // Refresh character list when returning from character creation
              _loadCharacters(),
            });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 48,
                color: HeartcraftTheme.gold,
              ),
              const SizedBox(height: 16),
              Text(
                'Create New Character',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ******** Tile selection methods ********

  void _toggleSelection(String characterId) {
    setState(() {
      if (_selectedCharacterIds.contains(characterId)) {
        _selectedCharacterIds.remove(characterId);
        // Exit selection mode if no characters are selected
        if (_selectedCharacterIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedCharacterIds.add(characterId);
      }
    });
  }

  void _enterSelectionMode(String characterId) {
    setState(() {
      _isSelectionMode = true;
      _selectedCharacterIds.clear();
      _selectedCharacterIds.add(characterId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedCharacterIds.clear();
    });
  }

  Future<void> _deleteSelectedCharacters() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String messageText;
    if (_selectedCharacterIds.length == 1) {
      final character = _characters!
          .firstWhere((char) => char.id == _selectedCharacterIds.first);
      messageText = character.name;
    } else {
      messageText = '${_selectedCharacterIds.length} characters';
    }

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Characters'),
        content: Text(
          'Are you sure you want to delete $messageText? This cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      for (final id in _selectedCharacterIds) {
        try {
          await _dataService.deleteCharacter(id);
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete character: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      _exitSelectionMode();
      await _loadCharacters();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Deleted $messageText'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ******** Data loading methods ********

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final characters = await _dataService.getRecentCharacters();

      setState(() {
        _characters = characters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load characters: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadData() async {
    final gameDataService = context.read<GameDataService>();
    await gameDataService.loadAllCompendiums();
    await _loadCharacters();
  }
}

/// Widget that displays character tile with portrait as background
class _CharacterTileBackground extends StatelessWidget {
  final CharacterSummary character;

  const _CharacterTileBackground({
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadPortraitPath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: HeartcraftTheme.cardBackgroundColor,
            child: const Center(
              child: CircularProgressIndicator(
                color: HeartcraftTheme.gold,
              ),
            ),
          );
        }

        final portraitPath = snapshot.data;

        return _buildContent(context, portraitPath);
      },
    );
  }

  Future<String?> _loadPortraitPath() async {
    if (character.portraitPath != null) {
      final portraitsDir = await PortraitService().getPortraitsDirectory();
      final portraitFile =
          File('${portraitsDir.path}/${character.portraitPath}');

      if (await portraitFile.exists()) {
        return portraitFile.path;
      }
    }
    return null;
  }

  Widget _buildContent(BuildContext context, String? portraitPath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (portraitPath != null)
          Image.file(
            File(portraitPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultBackground();
            },
          )
        else
          // Fall back to default background if no portrait
          _buildDefaultBackground(),

        // Dark gradient overlay at bottom of tile for text legibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.5, 0.8, 1.0],
            ),
          ),
        ),

        // Character info text: name and class/level
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  character.name.isEmpty ? 'Unnamed Character' : character.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius: 8.0,
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: const Offset(2, 2),
                        blurRadius: 4.0,
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  character.classLevelString,
                  key: ValueKey('character_${character.id}_summary'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HeartcraftTheme.gold,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 0),
                        blurRadius: 6.0,
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: const Offset(2, 2),
                        blurRadius: 3.0,
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 1.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HeartcraftTheme.darkPrimaryPurple.withValues(alpha: 0.8),
            HeartcraftTheme.darkPurple,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 96,
          color: HeartcraftTheme.gold,
        ),
      ),
    );
  }
}
