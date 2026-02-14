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
import '../../view_models/character_view_model.dart';
import '../../view_models/edit_mode_view_model.dart';
import '../../services/game_data_service.dart';
import '../domain_cards_screen.dart';

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
    final characterViewModel = context.read<CharacterViewModel>();
    final character = characterViewModel.currentCharacter;
    if (text.isNotEmpty && character != null) {
      characterViewModel.addExperience(text);
      setState(() {
        experienceController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterViewModel = context.watch<CharacterViewModel>();
    final character = characterViewModel.currentCharacter;
    if (character == null) return const SizedBox();
    final editMode = context.watch<EditModeViewModel>().editMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TraitsCard(),
          _buildExperiencesCard(
              context, character, characterViewModel, editMode),
          _buildClassFeaturesCard(context, character),
          _buildSubclassFeaturesCard(context, character),
          _buildAncestryFeaturesCard(context, character),
          _buildCommunityFeaturesCard(context, character),
          _buildDomainCardsCard(context, character, editMode),
        ],
      ),
    );
  }

  Widget _buildExperiencesCard(
    BuildContext context,
    Character character,
    CharacterViewModel characterViewModel,
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
                characterViewModel,
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
    CharacterViewModel characterViewModel,
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
                    characterViewModel,
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
                        characterViewModel.removeExperience(experienceName),
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
    CharacterViewModel characterViewModel,
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
            characterViewModel.updateExperienceModifier(
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

  Widget _buildDomainCardsCard(
      BuildContext context, Character character, bool editMode) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  'Domain Card Loadout',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: HeartcraftTheme.gold,
                      ),
                ),
                if (editMode) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DomainCardsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inventory_2),
                      SizedBox(width: 8),
                      Text('Vault')
                    ]),
                  ),
                ]
              ],
            ),
            if (character.domainLoadout.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'No domain cards in loadout',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
              )
            else ...[
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final crossAxisCount = availableWidth ~/ cardWidth;
                  return MasonryGridView.count(
                    crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    itemCount: character.domainLoadout.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => DomainCard(
                      ability: character.domainLoadout[index],
                      domains: character.domains,
                      isSelected: false,
                      onTap: () {},
                    ),
                  );
                },
              ),
            ]
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
