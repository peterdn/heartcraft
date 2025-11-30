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
import 'package:heartcraft/models/experience.dart';
import 'package:provider/provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/edit_mode_provider.dart';
import '../../theme/heartcraft_theme.dart';
import '../../models/companion.dart';
import '../../services/game_data_service.dart';
import '../../widgets/character_view/resource_card.dart';

/// Companion management tab for character view
/// Includes companion details, combat stats, stress, experiences
class CompanionTab extends StatefulWidget {
  final Companion companion;

  const CompanionTab({
    super.key,
    required this.companion,
  });

  @override
  CompanionTabState createState() => CompanionTabState();
}

class CompanionTabState extends State<CompanionTab> {
  final nameController = TextEditingController();
  final subTypeController = TextEditingController();
  final standardAttackController = TextEditingController();
  late List<Map<String, String>> allExperiences;

  // TODO: both of these should be an enum somewhere
  List<String> rangeOptions = ['Melee', 'Close', 'Far', 'Very Far'];
  List<String> damageDieOptions = ['d4', 'd6', 'd8', 'd10', 'd12'];

  @override
  void initState() {
    super.initState();

    allExperiences = context.read<GameDataService>().experiences;

    nameController.text = widget.companion.name ?? '';
    subTypeController.text = widget.companion.subType ?? '';
    standardAttackController.text = widget.companion.standardAttack;
  }

  @override
  void dispose() {
    nameController.dispose();
    subTypeController.dispose();
    standardAttackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = context.watch<CharacterProvider>();
    final editMode = context.watch<EditModeProvider>().editMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBasicInfoCard(characterProvider, editMode),
          _buildCombatCard(characterProvider, editMode),
          _buildStressCard(characterProvider, editMode),
          _buildExperiencesCard(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(
      CharacterProvider characterProvider, bool editMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Companion name
            Row(
              children: [
                const Icon(Icons.pets, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: editMode
                      ? TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Companion Name',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            characterProvider.updateCompanionName(value);
                          },
                        )
                      : Text(
                          widget.companion.name?.isEmpty != false
                              ? 'Unnamed Companion'
                              : widget.companion.name!,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Animal type
            Row(
              children: [
                const Icon(Icons.category, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: editMode
                      ? TextFormField(
                          controller: subTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Animal Type',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., Wolf, Eagle, Bear',
                          ),
                          onChanged: (value) {
                            characterProvider.updateCompanionSubType(value);
                          },
                        )
                      : Text(
                          widget.companion.subType?.isEmpty != false
                              ? 'No type specified'
                              : widget.companion.subType!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombatCard(CharacterProvider characterProvider, bool editMode) {
    final evasion = widget.companion.evasion;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Combat Stats',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16),
            // Evasion Row
            Row(
              children: [
                if (editMode) ...[
                  ResourceEditButton(
                    icon: Icons.remove_circle_outline,
                    onPressed: evasion > 1
                        ? () => characterProvider
                            .updateCompanionEvasion(evasion - 1)
                        : null,
                  ),
                  ResourceEditButton(
                    icon: Icons.add_circle_outline,
                    onPressed: () =>
                        characterProvider.updateCompanionEvasion(evasion + 1),
                  ),
                ],
                Text(
                  'Evasion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HeartcraftTheme.gold,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: HeartcraftTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: HeartcraftTheme.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    evasion.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HeartcraftTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Standard Attack
            editMode
                ? TextField(
                    controller: standardAttackController,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HeartcraftTheme.primaryTextColor,
                        ),
                    decoration: InputDecoration(
                      labelText: 'Standard Attack',
                      labelStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: HeartcraftTheme.gold,
                              ),
                      hintText: 'e.g., Claws, bite, talons',
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[400],
                              ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: HeartcraftTheme.gold),
                      ),
                      fillColor: HeartcraftTheme.surfaceColor,
                      filled: true,
                    ),
                    onChanged: (value) {
                      characterProvider.updateCompanionStandardAttack(value);
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Standard Attack',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: HeartcraftTheme.gold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.companion.standardAttack,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: HeartcraftTheme.primaryTextColor,
                            ),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),

            // Range
            Row(
              children: [
                Expanded(
                  child: editMode
                      ? DropdownButtonFormField<String>(
                          initialValue: widget.companion.range,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: HeartcraftTheme.primaryTextColor,
                                  ),
                          dropdownColor: HeartcraftTheme.surfaceColor,
                          decoration: InputDecoration(
                            labelText: 'Range',
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: HeartcraftTheme.gold,
                                ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: HeartcraftTheme.gold),
                            ),
                            fillColor: HeartcraftTheme.surfaceColor,
                            filled: true,
                          ),
                          items: rangeOptions.map((String range) {
                            return DropdownMenuItem<String>(
                              value: range,
                              child: Text(
                                range,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: HeartcraftTheme.primaryTextColor,
                                    ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              characterProvider.updateCompanionRange(newValue);
                            }
                          },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Range',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: HeartcraftTheme.gold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.companion.range,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: HeartcraftTheme.primaryTextColor,
                                  ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 16),

                // Damage Die
                Expanded(
                  child: editMode
                      ? DropdownButtonFormField<String>(
                          initialValue: widget.companion.damageDie,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: HeartcraftTheme.primaryTextColor,
                                  ),
                          dropdownColor: HeartcraftTheme.surfaceColor,
                          decoration: InputDecoration(
                            labelText: 'Damage Die',
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: HeartcraftTheme.gold,
                                ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: HeartcraftTheme.gold),
                            ),
                            fillColor: HeartcraftTheme.surfaceColor,
                            filled: true,
                          ),
                          items: damageDieOptions.map((String die) {
                            return DropdownMenuItem<String>(
                              value: die,
                              child: Text(
                                die,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: HeartcraftTheme.primaryTextColor,
                                    ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              characterProvider
                                  .updateCompanionDamageDie(newValue);
                            }
                          },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Damage Die',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: HeartcraftTheme.gold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.companion.damageDie,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: HeartcraftTheme.primaryTextColor,
                                  ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStressCard(CharacterProvider characterProvider, bool editMode) {
    final maxStress = widget.companion.maxStress;
    final currentStress = widget.companion.currentStress;

    return ResourceCard(
      title: 'Stress',
      maxValue: maxStress,
      currentValue: currentStress,
      icon: Icons.warning,
      color: Colors.orange,
      editMode: editMode,
      onMaxDecrement: maxStress > 1
          ? () => characterProvider.updateCompanionMaxStress(maxStress - 1)
          : null,
      onMaxIncrement: () =>
          characterProvider.updateCompanionMaxStress(maxStress + 1),
      onValueChanged: (newValue) {
        characterProvider.updateCompanionStress(newValue);
      },
    );
  }

  Widget _buildExperiencesCard() {
    // TODO: lots here to share with character abilities tab
    final experiences = widget.companion.experiences.map((exp) {
      final found = allExperiences.firstWhere(
        (e) => e['name'] == exp.name,
        orElse: () => {'name': exp.name, 'category': 'Unknown'},
      );
      return {'name': exp.name, 'category': found['category'] ?? 'Unknown'};
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experiences',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16),

            // Experiences list
            if (experiences.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No experiences added yet'),
                ),
              )
            else
              ...experiences.asMap().entries.map((entry) {
                final index = entry.key;
                final experienceName = entry.value['name']!;
                final category = entry.value['category'];
                // Get the actual Experience object from the companion
                final experienceObj = widget.companion.experiences.firstWhere(
                  (exp) => exp.name == experienceName,
                  orElse: () => Experience(name: experienceName, modifier: 2),
                );

                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index < experiences.length - 1 ? 8 : 0),
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
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
