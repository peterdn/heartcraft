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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heartcraft/models/experience.dart';
import '../../view_models/character_creation_view_model.dart';
import '../../theme/heartcraft_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../services/game_data_service.dart';

/// Experiences selection step for character creation
/// Features random experience suggestion or manual input
class ExperiencesStep extends StatefulWidget {
  final CharacterCreationViewModel viewModel;

  const ExperiencesStep({super.key, required this.viewModel});

  @override
  ExperiencesStepState createState() => ExperiencesStepState();
}

class ExperiencesStepState extends State<ExperiencesStep> {
  final experienceController = TextEditingController();

  // map name => category
  // TODO definitely a better way to structure this
  late List<Map<String, String>> experiences;
  List<Map<String, String>> allExperiences = [];

  final _random = Random();

  @override
  void initState() {
    super.initState();
    experiences = widget.viewModel.character.experiences.map((exp) {
      return {'name': exp.name, 'category': 'Unknown'};
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    allExperiences = context.read<GameDataService>().experiences;
    // Update categories for existing chosen/written experiences
    experiences = experiences.map((exp) {
      final found = allExperiences.firstWhere(
        (e) => e['name'] == exp['name'],
        orElse: () => {'name': exp['name']!, 'category': 'Unknown'},
      );
      return {'name': exp['name']!, 'category': found['category'] ?? 'Unknown'};
    }).toList();
  }

  @override
  void dispose() {
    experienceController.dispose();
    super.dispose();
  }

  void _addExperience() {
    final text = experienceController.text.trim();
    if (text.isNotEmpty && experiences.length < 2) {
      // Find category for this experience
      final found = allExperiences.firstWhere(
        (e) => e['name'] == text,
        orElse: () => {'name': text, 'category': 'Unknown'},
      );
      setState(() {
        experiences
            .add({'name': text, 'category': found['category'] ?? 'Unknown'});
        experienceController.clear();
      });
      _saveExperiences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveUtils.responsiveValue(
            context,
            narrow: const EdgeInsets.only(left: 16, right: 160, bottom: 16),
            wide: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Experiences',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: HeartcraftTheme.gold,
                      fontSize: ResponsiveUtils.responsiveValue(context,
                          narrow: 20, wide: 24),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '''Add up to 2 significant experiences that shaped your character.
When you make an action, you may spend 1 Hope to add the modifier of a relevant experience to the roll.''',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveUtils.responsiveValue(context,
                          narrow: 14, wide: 16),
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: ResponsiveUtils.responsiveValue(
                context,
                narrow: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                wide: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add experience form
                      if (experiences.length < 2)
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
                                      hintStyle:
                                          TextStyle(color: Colors.grey[700]),
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
                                    onPressed: _addExperience,
                                    child: const Icon(Icons.add),
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
                                    onPressed: _randomExperience,
                                    child: const Icon(Icons.casino),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

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
                          // TODO: there is a common widget here somewhere
                          final index = entry.key;
                          final experienceName = entry.value['name']!;
                          final category = entry.value['category'];
                          // Get the actual Experience object from the character
                          final experienceObj =
                              widget.viewModel.character.experiences.firstWhere(
                            (exp) => exp.name == experienceName,
                            orElse: () =>
                                Experience(name: experienceName, modifier: 2),
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
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeExperience(index),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _randomExperience() {
    if (allExperiences.isEmpty) return;
    // Exclude already added
    final available = allExperiences
        .where((e) => !experiences.any((ex) => ex['name'] == e['name']))
        .toList();
    if (available.isEmpty) return;
    final randomExp = available[_random.nextInt(available.length)];
    setState(() {
      experienceController.text = randomExp['name'] ?? '';
    });
  }

  void _removeExperience(int index) {
    setState(() {
      experiences.removeAt(index);
    });
    _saveExperiences();
  }

  void _saveExperiences() {
    if (experiences.isNotEmpty) {
      widget.viewModel
          .addExperiences(experiences.map((e) => e['name']!).toList());
    } else {
      widget.viewModel.skipExperiences();
    }
  }
}
