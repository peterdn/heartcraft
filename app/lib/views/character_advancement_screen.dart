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
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:heartcraft/models/domain.dart';
import 'package:heartcraft/models/experience.dart';
import 'package:heartcraft/models/character.dart';
import 'package:heartcraft/models/trait.dart';
import 'package:heartcraft/providers/character_provider.dart';
import 'package:heartcraft/providers/character_advancement_provider.dart';
import 'package:heartcraft/theme/heartcraft_theme.dart';
import 'package:heartcraft/services/game_data_service.dart';
import 'package:heartcraft/widgets/domain_card.dart';
import 'package:provider/provider.dart';

// Character advancement screen for leveling up characters
// TODO: super WIP, needs Tier3+4 suppor, optimised for mobile layout, tidied up
// Lots of inline logic everywhere.... move to provider or service
class CharacterAdvancementScreen extends StatefulWidget {
  const CharacterAdvancementScreen({super.key});

  @override
  CharacterAdvancementScreenState createState() =>
      CharacterAdvancementScreenState();
}

class CharacterAdvancementScreenState
    extends State<CharacterAdvancementScreen> {
  final experienceController = TextEditingController();
  List<Map<String, String>> allExperiences = [];

  @override
  void initState() {
    super.initState();
    allExperiences = context.read<GameDataService>().experiences;
  }

  @override
  void dispose() {
    experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = context.watch<CharacterProvider>();
    final character = characterProvider.currentCharacter;

    if (character == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Character')),
        body: const Center(child: Text('No character loaded')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) {
        final provider = CharacterAdvancementProvider();
        provider.initialize(character);
        return provider;
      },
      child: Consumer<CharacterAdvancementProvider>(
        builder: (context, advancementProvider, child) {
          final newLevel = advancementProvider.newLevel;
          final isValid = advancementProvider.isValid;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              final shouldPop = await _showExitConfirmation(context);
              if (shouldPop == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Level up!'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: _buildLevelUpButton(context, characterProvider,
                        advancementProvider, isValid),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advancing ${character.name}: Level ${character.level} -> $newLevel',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: HeartcraftTheme.gold,
                              ),
                    ),
                    const SizedBox(height: 16.0),
                    _buildLevelAchievements(character, advancementProvider),
                    if (newLevel >= 2)
                      _buildTier2Advancements(character, advancementProvider),
                    if (newLevel >= 5) _buildTier3Advancements(character),
                    if (newLevel >= 8) _buildTier4Advancements(character),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showExitConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Level-up Progress?'),
          content: const Text(
            'Your level-up progress will be lost if you exit this screen. '
            'Are you sure you want to exit?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: HeartcraftTheme.errorRed,
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLevelAchievements(
      Character character, CharacterAdvancementProvider advancementProvider) {
    final newLevel = advancementProvider.newLevel;

    final oldThresholds =
        '${character.majorDamageThreshold} / ${character.severeDamageThreshold}';
    final newThresholds =
        '${character.majorDamageThreshold + 1} / ${character.severeDamageThreshold + 1}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level Achievements',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16.0),
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                Text(
                  'Damage thresholds increase from:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildValueContainer(context, oldThresholds),
                Text(
                  'to',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildValueContainer(context, newThresholds),
                Text(
                  '!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Proficiency increase and new experience
            if (newLevel == 2 || newLevel == 5 || newLevel == 8) ...[
              Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  Text(
                    'Proficiency increase from:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _buildValueContainer(
                      context, character.proficiency.toString()),
                  Text(
                    'to',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _buildValueContainer(
                      context, (character.proficiency + 1).toString()),
                  Text(
                    '!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                'Gain a new Experience at +2:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              _buildExperiencesSection(character, advancementProvider),
              const SizedBox(height: 16.0),
            ],
            // Domain card selection (available at all levels)
            Text(
              'Gain a new Domain Card:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            _buildLevelAchievementDomainCardSection(
                character, advancementProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildExperiencesSection(
      Character character, CharacterAdvancementProvider advancementProvider) {
    final newExperienceName = advancementProvider.newExperienceName;
    final experiences = character.experiences.map((exp) {
      final found = allExperiences.firstWhere(
        (e) => e['name'] == exp.name,
        orElse: () => {'name': exp.name, 'category': 'Unknown'},
      );
      return {'name': exp.name, 'category': found['category'] ?? 'Unknown'};
    }).toList();

    // Combine existing experiences with the new one for display
    final allDisplayExperiences = [...experiences];
    if (newExperienceName != null) {
      final found = allExperiences.firstWhere(
        (e) => e['name'] == newExperienceName,
        orElse: () => {'name': newExperienceName, 'category': 'Unknown'},
      );
      allDisplayExperiences.add({
        'name': newExperienceName,
        'category': found['category'] ?? 'Unknown'
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experiences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16),
            // Add new experience form (only show if haven't added one yet)
            if (newExperienceName == null)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: experienceController,
                          enabled: true,
                          decoration: InputDecoration(
                            hintText: 'Experience',
                            border: const OutlineInputBorder(),
                            hintStyle: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 42,
                        width: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => _addExperience(advancementProvider),
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            // Experiences list
            if (allDisplayExperiences.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No experiences added yet'),
                ),
              )
            else
              ...allDisplayExperiences.asMap().entries.map((entry) {
                final index = entry.key;
                final experienceName = entry.value['name']!;
                final category = entry.value['category'];
                final isExisting = index < experiences.length;

                // Get the actual Experience object or create a default for the new one
                final experienceObj = isExisting
                    ? character.experiences.firstWhere(
                        (exp) => exp.name == experienceName,
                        orElse: () =>
                            Experience(name: experienceName, modifier: 2),
                      )
                    : Experience(name: experienceName, modifier: 2);

                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index < allDisplayExperiences.length - 1 ? 8 : 0),
                  child: Card(
                    child: ListTile(
                      leading: iconForExperienceCategory(category),
                      title: Row(
                        children: [
                          Expanded(child: Text(experienceName)),
                          const SizedBox(width: 8),
                          Text(
                            '(+${experienceObj.modifier})',
                            style: const TextStyle(
                              color: HeartcraftTheme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Only show delete button for the newly added experience
                      trailing: !isExisting
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                advancementProvider.setNewExperience(null);
                                experienceController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _addExperience(CharacterAdvancementProvider advancementProvider) {
    final text = experienceController.text.trim();
    if (text.isNotEmpty && advancementProvider.newExperienceName == null) {
      advancementProvider.setNewExperience(text);
      experienceController.clear();
    }
  }

  Widget _buildLevelAchievementDomainCardSection(
      Character character, CharacterAdvancementProvider advancementProvider) {
    final selectedLevelAchievementDomainCard =
        advancementProvider.levelAchievementDomainCard;
    final newLevel = advancementProvider.newLevel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedLevelAchievementDomainCard == null)
              ElevatedButton.icon(
                onPressed: () => _showDomainCardSelectionDialog(
                  character,
                  newLevel,
                  advancementProvider,
                  isLevelAchievement: true,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Select Domain Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HeartcraftTheme.gold,
                  foregroundColor: Colors.black,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Domain Card:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: HeartcraftTheme.gold,
                        onPressed: () => _showDomainCardSelectionDialog(
                          character,
                          newLevel,
                          advancementProvider,
                          isLevelAchievement: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DomainCard(
                    ability: selectedLevelAchievementDomainCard,
                    domains: character.domains,
                    isSelected: false,
                    onTap: () => _showDomainCardSelectionDialog(
                      character,
                      newLevel,
                      advancementProvider,
                      isLevelAchievement: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueContainer(BuildContext context, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: HeartcraftTheme.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HeartcraftTheme.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: HeartcraftTheme.gold,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTier2Advancements(
      Character character, CharacterAdvancementProvider advancementProvider) {
    final tier2 = advancementProvider.tier2;
    final remainingSelections =
        advancementProvider.getRemainingTier2Selections();

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine if there's enough width to place title
                // and "remaining" on the same line, else stack vertically
                const titleWidth = 250.0;
                const remainingWidth = 150.0;
                const padding = 16.0;

                final hasSpaceForSameLine = constraints.maxWidth >=
                    (titleWidth + remainingWidth + padding);

                final titleWidget = Text(
                  'Tier 2 Advancements',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: HeartcraftTheme.gold,
                      ),
                );

                final remainingWidget = Text(
                  'Remaining: $remainingSelections',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HeartcraftTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                );

                if (hasSpaceForSameLine) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [titleWidget, remainingWidget],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 8),
                      remainingWidget,
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Choose 2 options:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildTraitAdvancement(
                character, advancementProvider, remainingSelections),
            const SizedBox(height: 8),
            _buildSimpleAdvancement(
              context: context,
              title: 'Increase Hit Points',
              description: 'Permanently gain one Hit Point slot',
              currentCount: tier2.increaseHitpoints,
              maxCount: 2,
              remainingSelections: remainingSelections,
              onIncrement: () {
                advancementProvider.incrementHitPoints();
              },
              onDecrement: () {
                advancementProvider.decrementHitPoints();
              },
            ),
            const SizedBox(height: 8),
            _buildSimpleAdvancement(
              context: context,
              title: 'Increase Stress',
              description: 'Permanently gain one Stress slot',
              currentCount: tier2.increaseStress,
              maxCount: 2,
              remainingSelections: remainingSelections,
              onIncrement: () {
                advancementProvider.incrementStress();
              },
              onDecrement: () {
                advancementProvider.decrementStress();
              },
            ),
            const SizedBox(height: 8),
            _buildToggleAdvancement(
              context: context,
              title: 'Increase Evasion',
              description: 'Permanently gain a +1 bonus to your Evasion',
              isSelected: tier2.increaseEvasion,
              remainingSelections: remainingSelections,
              onToggle: () {
                advancementProvider.toggleEvasion();
              },
            ),
            const SizedBox(height: 8),
            _buildExperienceAdvancement(
                character, advancementProvider, remainingSelections),
            const SizedBox(height: 8),
            _buildAdditionalDomainCardAdvancement(
                character, advancementProvider, remainingSelections),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitAdvancement(
    Character character,
    CharacterAdvancementProvider advancementProvider,
    int remainingSelections,
  ) {
    final tier2 = advancementProvider.tier2;
    final markedTraits = advancementProvider.markedTraits;
    const maxTraitSelections = 3;
    final canIncrease =
        tier2.increaseTraits < maxTraitSelections && remainingSelections > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Increase Traits',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gain a +1 bonus to two unmarked traits and mark them',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Text(
                      '${tier2.increaseTraits}/$maxTraitSelections',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: HeartcraftTheme.gold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: canIncrease ? HeartcraftTheme.gold : Colors.grey,
                      onPressed: canIncrease
                          ? () {
                              advancementProvider.incrementTraits();
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      color: tier2.increaseTraits > 0
                          ? HeartcraftTheme.gold
                          : Colors.grey,
                      onPressed: tier2.increaseTraits > 0
                          ? () {
                              advancementProvider.decrementTraits();
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            if (tier2.increaseTraits > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Select traits to increase by +1 (${markedTraits.length - character.advancements.markedTraits.length}/${(tier2.increaseTraits - character.advancements.tier2.increaseTraits) * 2}):',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Trait.values.map((trait) {
                  final wasAlreadyMarked =
                      character.advancements.markedTraits.contains(trait);
                  final isNewlyMarked =
                      markedTraits.contains(trait) && !wasAlreadyMarked;
                  final currentValue = character.traits[trait] ?? 0;

                  int displayValue = currentValue;
                  if (wasAlreadyMarked) {
                    displayValue = currentValue;
                  } else if (isNewlyMarked) {
                    displayValue = currentValue + 1;
                  }

                  final displayValueStr = displayValue >= 0
                      ? "+$displayValue"
                      : displayValue.toString();

                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trait.displayName,
                          style: TextStyle(
                            color: wasAlreadyMarked
                                ? Colors.grey[200]
                                : isNewlyMarked
                                    ? Colors.white
                                    : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($displayValueStr)',
                          style: TextStyle(
                            color: wasAlreadyMarked
                                ? Colors.grey[200]
                                : isNewlyMarked
                                    ? Colors.white
                                    : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    selected: isNewlyMarked,
                    onSelected: wasAlreadyMarked
                        ? null // Disable selecting already marked traits
                        : (selected) {
                            advancementProvider.toggleTrait(trait);
                          },
                    selectedColor: HeartcraftTheme.gold.withValues(alpha: 0.3),
                    checkmarkColor: HeartcraftTheme.gold,
                    backgroundColor:
                        wasAlreadyMarked ? Colors.grey[200] : Colors.grey[300],
                    side: BorderSide(
                      color: wasAlreadyMarked
                          ? Colors.grey[400]!
                          : isNewlyMarked
                              ? HeartcraftTheme.gold
                              : Colors.grey[400]!,
                      width: 1.5,
                    ),
                    showCheckmark: isNewlyMarked,
                  );
                }).toList(),
              ),
              if (markedTraits.length -
                      character.advancements.markedTraits.length !=
                  (tier2.increaseTraits -
                          character.advancements.tier2.increaseTraits) *
                      2)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'You must mark exactly ${(tier2.increaseTraits - character.advancements.tier2.increaseTraits) * 2} NEW traits',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceAdvancement(
    Character character,
    CharacterAdvancementProvider advancementProvider,
    int remainingSelections,
  ) {
    final tier2 = advancementProvider.tier2;
    final selectedExperiencesForBonus =
        advancementProvider.selectedExperiencesForBonus;
    final newExperienceName = advancementProvider.newExperienceName;
    final canToggle = !tier2.increaseExperiences && remainingSelections > 0;

    // Build list of all experiences including the new one from level achievements
    final allExperiences = <Experience>[...character.experiences];
    if (newExperienceName != null) {
      allExperiences.add(Experience(name: newExperienceName, modifier: 2));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Increase Experiences',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Permanently gain a +1 bonus to two Experiences',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: tier2.increaseExperiences,
                  onChanged: (tier2.increaseExperiences || canToggle)
                      ? (value) {
                          advancementProvider.toggleIncreaseExperiences();
                        }
                      : null,
                  activeColor: HeartcraftTheme.gold,
                ),
              ],
            ),
            if (tier2.increaseExperiences) ...[
              const SizedBox(height: 16),
              if (allExperiences.isEmpty)
                const Text(
                  'No experiences to increase',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                )
              else ...[
                Text(
                  'Select experiences to increase by +1 (${selectedExperiencesForBonus.length}/2):',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allExperiences.map((exp) {
                    final isSelected =
                        selectedExperiencesForBonus.contains(exp.name);
                    final canSelect = selectedExperiencesForBonus.length < 2;
                    final displayModifier =
                        isSelected ? exp.modifier + 1 : exp.modifier;

                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            exp.name,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(+$displayModifier)',
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected && !isSelected && canSelect) {
                          advancementProvider
                              .toggleExperienceForBonus(exp.name);
                        } else if (!selected && isSelected) {
                          advancementProvider
                              .toggleExperienceForBonus(exp.name);
                        }
                      },
                      selectedColor:
                          HeartcraftTheme.gold.withValues(alpha: 0.3),
                      checkmarkColor: HeartcraftTheme.gold,
                      backgroundColor: Colors.grey[300],
                      side: BorderSide(
                        color: isSelected
                            ? HeartcraftTheme.gold
                            : Colors.grey[400]!,
                        width: 1.5,
                      ),
                      showCheckmark: true,
                    );
                  }).toList(),
                ),
                if (selectedExperiencesForBonus.length != 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'You must select exactly 2 experiences',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalDomainCardAdvancement(
    Character character,
    CharacterAdvancementProvider advancementProvider,
    int remainingSelections,
  ) {
    final tier2 = advancementProvider.tier2;
    final selectedAdditionalDomainCard =
        advancementProvider.additionalDomainCard;
    final canToggle = !tier2.additionalDomainCard && remainingSelections > 0;
    final newLevel = character.level + 1;
    final maxLevel = newLevel < 4 ? newLevel : 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Domain Card',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose an additional domain card of level $maxLevel or lower',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: tier2.additionalDomainCard,
                  onChanged: (tier2.additionalDomainCard || canToggle)
                      ? (value) {
                          advancementProvider.toggleAdditionalDomainCard();
                          if (advancementProvider.tier2.additionalDomainCard) {
                            _showDomainCardSelectionDialog(
                              character,
                              maxLevel,
                              advancementProvider,
                              isLevelAchievement: false,
                            );
                          }
                        }
                      : null,
                  activeColor: HeartcraftTheme.gold,
                ),
              ],
            ),
            if (tier2.additionalDomainCard &&
                !character.advancements.tier2.additionalDomainCard) ...[
              const SizedBox(height: 16),
              if (selectedAdditionalDomainCard == null)
                ElevatedButton.icon(
                  onPressed: () => _showDomainCardSelectionDialog(
                    character,
                    maxLevel,
                    advancementProvider,
                    isLevelAchievement: false,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Select Domain Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HeartcraftTheme.gold,
                    foregroundColor: Colors.black,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected Domain Card:',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DomainCard(
                      ability: selectedAdditionalDomainCard,
                      domains: character.domains,
                      isSelected: false,
                      onTap: () => _showDomainCardSelectionDialog(
                        character,
                        maxLevel,
                        advancementProvider,
                        isLevelAchievement: false,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDomainCardSelectionDialog(Character character, int maxLevel,
      CharacterAdvancementProvider advancementProvider,
      {bool isLevelAchievement = false}) async {
    final selectedAdditionalDomainCard =
        advancementProvider.additionalDomainCard;
    final selectedLevelAchievementDomainCard =
        advancementProvider.levelAchievementDomainCard;
    final allDomainAbilities = context.read<GameDataService>().domainAbilities;

    // Get IDs of domain cards the character already has
    final existingCardIds = character.domainAbilities.map((a) => a.id).toSet();

    // Also exclude the card selected in the other section
    if (isLevelAchievement && selectedAdditionalDomainCard != null) {
      existingCardIds.add(selectedAdditionalDomainCard.id);
    } else if (!isLevelAchievement &&
        selectedLevelAchievementDomainCard != null) {
      existingCardIds.add(selectedLevelAchievementDomainCard.id);
    }

    // Filter to only show cards from character's domains, at or below maxLevel,
    // and not already owned by the character, or selected in the other section
    final availableCards = allDomainAbilities.where((ability) {
      return character.domains.any((domain) => domain.id == ability.domain) &&
          ability.level <= maxLevel &&
          !existingCardIds.contains(ability.id);
    }).toList();

    // Sort by domain and level
    availableCards.sort((a, b) {
      final domainCompare = a.domain.compareTo(b.domain);
      if (domainCompare != 0) return domainCompare;
      return a.level.compareTo(b.level);
    });

    final selected = await showDialog<DomainAbility>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Select Domain Card (Level $maxLevel or lower)',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: HeartcraftTheme.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: availableCards.isEmpty
                      ? const Center(
                          child: Text('No domain cards available'),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = 350.0;
                            final availableWidth = constraints.maxWidth;
                            final crossAxisCount = availableWidth ~/ cardWidth;
                            return MasonryGridView.count(
                              crossAxisCount:
                                  crossAxisCount > 0 ? crossAxisCount : 1,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              itemCount: availableCards.length,
                              itemBuilder: (context, index) {
                                final ability = availableCards[index];
                                return DomainCard(
                                  ability: ability,
                                  domains: character.domains,
                                  isSelected:
                                      selectedAdditionalDomainCard?.id ==
                                          ability.id,
                                  onTap: () =>
                                      Navigator.of(context).pop(ability),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      if (isLevelAchievement) {
        advancementProvider.setLevelAchievementDomainCard(selected);
      } else {
        advancementProvider.setAdditionalDomainCard(selected);
      }
    }
  }

  Widget _buildSimpleAdvancement({
    required BuildContext context,
    required String title,
    required String description,
    required int currentCount,
    required int maxCount,
    required int remainingSelections,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    final canIncrease = currentCount < maxCount && remainingSelections > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 12),
                Text(
                  '$currentCount/$maxCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HeartcraftTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: canIncrease ? HeartcraftTheme.gold : Colors.grey,
                  onPressed: canIncrease ? onIncrement : null,
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  color: currentCount > 0 ? HeartcraftTheme.gold : Colors.grey,
                  onPressed: currentCount > 0 ? onDecrement : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleAdvancement({
    required BuildContext context,
    required String title,
    required String description,
    required bool isSelected,
    required int remainingSelections,
    required VoidCallback onToggle,
  }) {
    final canToggle = !isSelected && remainingSelections > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged:
                  (isSelected || canToggle) ? (value) => onToggle() : null,
              activeColor: HeartcraftTheme.gold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTier3Advancements(Character character) {
    // TODO
    return Container();
  }

  Widget _buildTier4Advancements(Character character) {
    // TODO
    return Container();
  }

  Widget _buildLevelUpButton(
    BuildContext context,
    CharacterProvider characterProvider,
    CharacterAdvancementProvider advancementProvider,
    bool isValid,
  ) {
    return ElevatedButton.icon(
      onPressed: isValid
          ? () => _performLevelUp(characterProvider, advancementProvider)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isValid ? HeartcraftTheme.gold : Colors.grey,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        disabledBackgroundColor: Colors.grey.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white70,
      ),
      icon: Icon(isValid ? Icons.arrow_upward : Icons.pending_actions),
      label: Text(
        isValid ? 'Level up!' : 'Choices Pending',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _performLevelUp(CharacterProvider characterProvider,
      CharacterAdvancementProvider advancementProvider) {
    advancementProvider.performLevelUp();

    characterProvider.saveCharacter();

    Navigator.of(context).pop();
  }
}
