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
import 'package:heartcraft/models/experience.dart';
import '../../providers/character_creation_provider.dart';
import '../../theme/heartcraft_theme.dart';
import '../../utils/responsive_utils.dart';

/// Companion selection step widget for character creation
class CompanionSelectionStep extends StatefulWidget {
  final CharacterCreationProvider provider;

  const CompanionSelectionStep({super.key, required this.provider});

  @override
  CompanionSelectionStepState createState() => CompanionSelectionStepState();
}

class CompanionSelectionStepState extends State<CompanionSelectionStep> {
  late final nameController = TextEditingController();
  late final subTypeController = TextEditingController();
  late final experienceController = TextEditingController();

  late List<Experience> experiences;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    final provider = widget.provider;

    // Load character's current companion data
    final currentCompanion = provider.character.companion;
    if (currentCompanion != null) {
      nameController.text = currentCompanion.name ?? '';
      subTypeController.text = currentCompanion.subType ?? '';
      experiences = currentCompanion.experiences;
    } else {
      experiences = [];
    }

    nameController.addListener(_saveCompanion);
    subTypeController.addListener(_saveCompanion);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveCompanion();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    subTypeController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final companion = provider.character.subclass?.companion;

    if (companion == null) {
      return const Center(
        child: Text('No companion data available'),
      );
    }

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
                'Companion',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: HeartcraftTheme.gold,
                      fontSize: ResponsiveUtils.responsiveValue(context,
                          narrow: 20, wide: 24),
                    ),
              ),
              const SizedBox(height: 4),
              // Companion description
              Text(
                companion.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveUtils.responsiveValue(context,
                          narrow: 14, wide: 16),
                    ),
              ),
              const SizedBox(height: 8),
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
                      // Name input
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Companion Name',
                          border: OutlineInputBorder(),
                          hintText: 'What do you call your companion?',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sub type input
                      TextField(
                        controller: subTypeController,
                        decoration: InputDecoration(
                          labelText: '${companion.typeTitle} Type',
                          border: const OutlineInputBorder(),
                          hintText:
                              'What kind of ${companion.type} is your companion?',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Experiences section
                      ..._buildExperienceSection(),
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

  List<Widget> _buildExperienceSection() {
    return [
      Text(
        'Companion Experiences (up to 2)',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HeartcraftTheme.gold,
            ),
      ),
      const SizedBox(height: 8),

      // Add experience form
      if (experiences.length < 2)
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: experienceController,
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
          final index = entry.key;
          final experienceName = entry.value.name;
          return Padding(
            padding:
                EdgeInsets.only(bottom: index < experiences.length - 1 ? 8 : 0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.star),
                title: Row(
                  children: [
                    Expanded(child: Text(experienceName)),
                    const SizedBox(width: 8),
                    const Text(
                      '(+2)',
                      style: TextStyle(
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
        })
    ];
  }

  void _addExperience() {
    final text = experienceController.text.trim();
    if (text.isNotEmpty && experiences.length < 2) {
      setState(() {
        experiences.add(Experience(name: text, modifier: 2));
        experienceController.clear();
      });
      _saveCompanion();
    }
  }

  void _removeExperience(int index) {
    setState(() {
      experiences.removeAt(index);
    });
    _saveCompanion();
  }

  // Select and display a random experience
  void _randomExperience() {
    final provider = widget.provider;
    final availableCompanionExperiences =
        provider.character.subclass?.companion?.availableExperiences ?? [];
    if (availableCompanionExperiences.isEmpty) return;
    final available = availableCompanionExperiences
        .where((e) => !experiences.any((ex) => ex.name == e))
        .toList();
    if (available.isEmpty) return;
    final randomExp = available[_random.nextInt(available.length)];
    experienceController.text = randomExp;
  }

  void _saveCompanion() {
    final provider = widget.provider;
    final name = nameController.text.trim();
    final subType = subTypeController.text.trim();

    provider.setCompanion(name, subType, experiences);
  }
}
