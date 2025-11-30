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
import 'package:heartcraft/models/character.dart';
import 'package:heartcraft/models/experience.dart';
import 'package:heartcraft/theme/heartcraft_theme.dart';
import 'package:heartcraft/widgets/character_view/traits_card.dart';
import 'package:heartcraft/widgets/domain_card.dart';
import 'package:heartcraft/widgets/feature_card.dart';
import 'package:provider/provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/edit_mode_provider.dart';
import '../../services/game_data_service.dart';

/// Abilities tab for character view
/// Shows traits, experiences, class/subclass/heritage features, and domain cards
class AbilitiesTab extends StatefulWidget {
  const AbilitiesTab({
    super.key,
  });

  @override
  AbilitiesTabState createState() => AbilitiesTabState();
}

class AbilitiesTabState extends State<AbilitiesTab> {
  final experienceController = TextEditingController();
  List<Map<String, String>> allExperiences = [];

  static const cardWidth = 350.0;

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

  void _addExperience() {
    final text = experienceController.text.trim();
    final characterProvider = context.read<CharacterProvider>();
    final character = characterProvider.currentCharacter;
    if (text.isNotEmpty && character != null) {
      characterProvider.addExperience(text);
      setState(() {
        experienceController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = context.watch<CharacterProvider>();
    final character = characterProvider.currentCharacter;
    if (character == null) return const SizedBox();
    final editMode = context.watch<EditModeProvider>().editMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TraitsCard(),
          _buildExperiencesCard(
              context, character, characterProvider, editMode),
          _buildClassFeaturesCard(context, character),
          _buildSubclassFeaturesCard(context, character),
          _buildAncestryFeaturesCard(context, character),
          _buildCommunityFeaturesCard(context, character),
          if (character.domainAbilities.isNotEmpty)
            _buildDomainCardsCard(context, character),
        ],
      ),
    );
  }

  Widget _buildExperiencesCard(
    BuildContext context,
    Character character,
    CharacterProvider characterProvider,
    bool editMode,
  ) {
    final experiences = character.experiences.map((exp) {
      final found = allExperiences.firstWhere(
        (e) => e['name'] == exp.name,
        orElse: () => {'name': exp.name, 'category': 'Unknown'},
      );
      return {'name': exp.name, 'category': found['category'] ?? 'Unknown'};
    }).toList();

    return Card(
      margin: const EdgeInsets.all(8.0),
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
            if (editMode) _buildAddExperienceField(),
            if (experiences.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No experiences added yet'),
                ),
              )
            else
              ..._buildExperiencesList(
                experiences,
                character,
                characterProvider,
                editMode,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddExperienceField() {
    return Column(
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
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildExperiencesList(
    List<Map<String, String>> experiences,
    Character character,
    CharacterProvider characterProvider,
    bool editMode,
  ) {
    return experiences.asMap().entries.map((entry) {
      final index = entry.key;
      final experienceName = entry.value['name']!;
      final category = entry.value['category'];
      final experienceObj = character.experiences.firstWhere(
        (exp) => exp.name == experienceName,
        orElse: () => Experience(name: experienceName, modifier: 2),
      );

      return Padding(
        padding: EdgeInsets.only(
          bottom: index < experiences.length - 1 ? 8 : 0,
        ),
        child: Card(
          child: ListTile(
            leading: iconForExperienceCategory(category),
            title: Row(
              children: [
                Expanded(child: Text(experienceName)),
                const SizedBox(width: 8),
                if (editMode)
                  _buildExperienceModifierField(
                    experienceObj,
                    experienceName,
                    characterProvider,
                  )
                else
                  Text(
                    '(+${experienceObj.modifier})',
                    style: const TextStyle(
                      color: HeartcraftTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: editMode
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () =>
                        characterProvider.removeExperience(experienceName),
                  )
                : null,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildExperienceModifierField(
    Experience experience,
    String experienceName,
    CharacterProvider characterProvider,
  ) {
    return SizedBox(
      width: 60,
      child: TextField(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          prefix: Text('+'),
        ),
        keyboardType: TextInputType.number,
        controller: TextEditingController(text: experience.modifier.toString()),
        onChanged: (value) {
          final newModifier = int.tryParse(value);
          if (newModifier != null) {
            characterProvider.updateExperienceModifier(
              experienceName,
              newModifier,
            );
          }
        },
      ),
    );
  }

  Widget _buildClassFeaturesCard(BuildContext context, Character character) {
    final classFeatures = character.characterClass!.classFeatures;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${character.characterClass!.name} Class Features',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFeatureGrid(classFeatures),
          ],
        ),
      ),
    );
  }

  Widget _buildSubclassFeaturesCard(BuildContext context, Character character) {
    final subclassFeatures = character.subclassFeatures;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${character.subclass!.name} Subclass Features',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFeatureGrid(subclassFeatures),
          ],
        ),
      ),
    );
  }

  Widget _buildAncestryFeaturesCard(BuildContext context, Character character) {
    final ancestryFeatures = character.selectedAncestryFeatures;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${character.ancestryDisplayName} Ancestry Features',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFeatureGrid(ancestryFeatures),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityFeaturesCard(
    BuildContext context,
    Character character,
  ) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${character.community!.name} Community Features',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFeatureGrid([character.community!.feature]),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainCardsCard(BuildContext context, Character character) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Domain Card Loadout',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final crossAxisCount = availableWidth ~/ cardWidth;
                return MasonryGridView.count(
                  crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  itemCount: character.domainAbilities.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => DomainCard(
                    ability: character.domainAbilities[index],
                    domains: character.domains,
                    isSelected: false,
                    onTap: () {},
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(List<dynamic> features) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = availableWidth ~/ cardWidth;
        return MasonryGridView.count(
          crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: features.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => FeatureCard(
            featureName: features[index].name,
            featureDescription: features[index].description,
          ),
        );
      },
    );
  }
}
