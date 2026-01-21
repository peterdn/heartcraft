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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heartcraft/models/class.dart';
import 'package:provider/provider.dart';
import '../../view_models/character_creation_view_model.dart';
import '../../services/game_data_service.dart';
import '../../theme/heartcraft_theme.dart';
import '../../utils/responsive_utils.dart';

/// Class selection step in character creation
class ClassSelectionStep extends StatelessWidget {
  const ClassSelectionStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveUtils.responsiveValue(
            context,
            narrow: const EdgeInsets.only(left: 16, right: 160),
            wide: const EdgeInsets.symmetric(horizontal: 24.0),
          ),
          child: Text(
            'Choose your class and subclass',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HeartcraftTheme.gold,
                  fontSize: ResponsiveUtils.responsiveValue(context,
                      narrow: 20, wide: 24),
                ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: ResponsiveUtils.responsiveValue(
            context,
            narrow: const EdgeInsets.only(left: 16, right: 160),
            wide: const EdgeInsets.symmetric(horizontal: 24.0),
          ),
          child: Text(
            'This determines your character\'s core abilities and their role in the party.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveUtils.responsiveValue(context,
                      narrow: 14, wide: 16),
                ),
          ),
        ),
        const SizedBox(height: 16),
        // List of classes
        Expanded(
          child: Consumer<CharacterCreationViewModel>(
            builder: (context, characterViewModel, child) {
              final classes = context.read<GameDataService>().characterClasses;

              if (classes.isEmpty) {
                return const Center(child: Text('No classes available'));
              }

              final selectedClass = characterViewModel.character.characterClass;

              return ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final characterClass = classes[index];
                  final isSelected = selectedClass?.id == characterClass.id;
                  return _buildClassCard(context, characterClass, isSelected);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(
      BuildContext context, CharacterClass characterClass, bool isSelected) {
    final characterViewModel =
        Provider.of<CharacterCreationViewModel>(context, listen: false);

    return Card(
      key: ValueKey('class_${characterClass.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      color: isSelected
          ? HeartcraftTheme.darkPrimaryPurple.withValues(alpha: 0.3)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: isSelected
            ? const BorderSide(color: HeartcraftTheme.gold, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectClass(context, characterClass),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                characterClass.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected ? HeartcraftTheme.gold : null,
                    ),
              ),
              // Class description
              if (characterClass.description != null) ...[
                const SizedBox(height: 8),
                Text(characterClass.description!),
              ],
              // Selected subclass info
              if (isSelected &&
                  characterViewModel.character.subclass != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: HeartcraftTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subclass: ${characterViewModel.character.subclass!.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (characterViewModel.character.subclass!.description !=
                          null) ...[
                        const SizedBox(height: 2),
                        Text(
                          characterViewModel.character.subclass!.description!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show modal bottom sheet for subclass selection
  void _selectClass(BuildContext context, CharacterClass characterClass) async {
    final gameDataService = context.read<GameDataService>();
    final viewModel =
        Provider.of<CharacterCreationViewModel>(context, listen: false);

    final subclassEntities = gameDataService.subclasses[characterClass.id]!;

    final selectedSubclass = await showModalBottomSheet<SubClass>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubclassSelectionBottomSheet(
        characterClass: characterClass,
        subclassEntities: subclassEntities,
        currentSubclass:
            viewModel.character.characterClass?.id == characterClass.id
                ? viewModel.character.subclass
                : null,
      ),
    );

    if (selectedSubclass != null) {
      viewModel.selectClass(characterClass, selectedSubclass);
    }
  }
}

/// Modal bottom sheet for subclass selection
class _SubclassSelectionBottomSheet extends StatelessWidget {
  final CharacterClass characterClass;
  final List<SubClass> subclassEntities;
  final SubClass? currentSubclass;

  const _SubclassSelectionBottomSheet({
    required this.characterClass,
    required this.subclassEntities,
    this.currentSubclass,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.responsiveValue(context,
                narrow: 16.0, wide: 24.0)),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                        width: ResponsiveUtils.responsiveValue(context,
                            narrow: 12, wide: 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            characterClass.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Choose a subclass',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[400],
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                // Subclass description
                if (characterClass.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    characterClass.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                          height: 1.4,
                        ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Subclass list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.responsiveValue(context,
                    narrow: 16.0, wide: 24.0),
                vertical: 8.0,
              ),
              itemCount: subclassEntities.length,
              itemBuilder: (context, index) {
                final subclass = subclassEntities[index];
                final isSelected = currentSubclass?.id == subclass.id;
                return _buildSubclassTile(context, subclass, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubclassTile(
      BuildContext context, SubClass subclass, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: HeartcraftTheme.gold, width: 2)
            : BorderSide.none,
      ),
      color: isSelected ? HeartcraftTheme.gold.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(subclass),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.responsiveValue(context,
              narrow: 16.0, wide: 20.0)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subclass.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ? HeartcraftTheme.gold : null,
                                ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: HeartcraftTheme.gold,
                            size: 24,
                          ).animate().scale(
                                duration: 200.ms,
                                curve: Curves.elasticOut,
                              ),
                      ],
                    ),
                    if (subclass.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subclass.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? HeartcraftTheme.gold.withValues(alpha: 0.8)
                                  : Colors.grey[500],
                              height: 1.4,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: isSelected ? HeartcraftTheme.gold : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
