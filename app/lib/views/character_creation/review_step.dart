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
import 'package:heartcraft/models/equipment.dart';
import 'package:provider/provider.dart';
import 'package:heartcraft/models/trait.dart';
import 'package:heartcraft/services/game_data_service.dart';
import '../../models/character.dart';
import '../../view_models/character_creation_view_model.dart';
import '../../theme/heartcraft_theme.dart';
import '../../utils/responsive_utils.dart';

/// Character review step at end of character creation
class ReviewStep extends StatelessWidget {
  static const double labelWidth = 120.0;
  static const double itemSpacing = 8.0;

  final CharacterCreationViewModel viewModel;

  const ReviewStep({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final character = viewModel.character;
    final gameDataService = context.read<GameDataService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveUtils.responsiveValue(
            context,
            narrow: const EdgeInsets.only(left: 16, right: 160),
            wide: const EdgeInsets.only(left: 24, right: 24),
          ),
          child: Text(
            'Review Your Character',
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
            'Make sure everything looks right before finalising your character.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveUtils.responsiveValue(context,
                      narrow: 14, wide: 16),
                ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: ResponsiveUtils.responsiveValue(
              context,
              narrow: const EdgeInsets.only(left: 16, right: 16),
              wide: const EdgeInsets.symmetric(horizontal: 24.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TODO: highlight missing sections to prompt user to fill them in

                  // Personal Details
                  _buildPersonalDetailsSection(character),

                  // Class
                  if (character.characterClass != null)
                    _buildClassSection(character),

                  // Ancestry
                  if (character.ancestry != null)
                    _buildAncestrySection(character),

                  // Community
                  if (character.community != null)
                    _buildCommunitySection(character),

                  // Traits
                  _buildTraitsSection(character),

                  // Equipment
                  if (character.inventory.isNotEmpty ||
                      character.primaryWeapon != null ||
                      character.secondaryWeapon != null ||
                      character.equippedArmor != null)
                    _buildEquipmentSection(character),

                  // Background
                  if (character.background != null ||
                      character.backgroundQuestionnaireAnswers.isNotEmpty)
                    _buildBackgroundSection(
                        context, character, gameDataService),

                  // Experiences
                  if (character.experiences.isNotEmpty)
                    _buildExperiencesSection(character),

                  // Domain Cards
                  if (character.domains.isNotEmpty &&
                      character.domainAbilities.isNotEmpty)
                    _buildDomainCardsSection(character),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsSection(Character character) {
    return _buildReviewSection(
      title: 'Personal Details',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewItem(
            'Name',
            character.name.isNotEmpty ? character.name : 'Not set',
          ),
          if (character.pronouns?.isNotEmpty == true)
            _buildReviewItem('Pronouns', character.pronouns!),
          if (character.description?.isNotEmpty == true)
            _buildReviewItem('Description', character.description!),
          if (character.connections.isNotEmpty) ...[
            const SizedBox(height: itemSpacing),
            const Text(
              'Connections:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...character.connections.map(
              (connection) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text('• $connection'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassSection(Character character) {
    return _buildReviewSection(
      title: 'Class',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewItem('Class', character.characterClass!.name),
          if (character.subclass != null)
            _buildReviewItem('Subclass', character.subclass!.name),
        ],
      ),
    );
  }

  Widget _buildAncestrySection(Character character) {
    return _buildReviewSection(
      title: 'Ancestry',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewItem('Primary Ancestry', character.ancestry!.name),
          if (character.secondAncestry != null)
            _buildReviewItem(
              'Secondary Ancestry',
              character.secondAncestry!.name,
            ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection(Character character) {
    return _buildReviewSection(
      title: 'Community',
      content: _buildReviewItem('Community', character.community!.name),
    );
  }

  Widget _buildTraitsSection(Character character) {
    return _buildReviewSection(
      title: 'Traits',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: Trait.values.map((trait) {
          final value = character.traits[trait];
          final displayValue =
              value != null ? (value >= 0 ? '+$value' : '$value') : '—';
          return _buildReviewItem(trait.displayName, displayValue);
        }).toList(),
      ),
    );
  }

  Widget _buildEquipmentSection(Character character) {
    return _buildReviewSection(
      title: 'Equipment',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeaponItem("Primary weapon", character.primaryWeapon),
          const SizedBox(height: itemSpacing),
          _buildWeaponItem("Secondary weapon", character.secondaryWeapon),
          const SizedBox(height: itemSpacing),
          _buildArmorItem(character.equippedArmor),
          const SizedBox(height: itemSpacing),
          ...character.inventory.map(_buildEquipmentItem)
        ],
      ),
    );
  }

  Widget _buildWeaponItem(String weaponLabel, Weapon? weapon) {
    String content = "<none>";
    if (weapon != null) {
      content =
          '${weapon.name} (${weapon.damageType}) - ${weapon.trait} • ${weapon.range} • '
          '${weapon.damage} • ${weapon.burden.displayName}';
    }
    return _buildReviewItem(weaponLabel, content);
  }

  Widget _buildArmorItem(Armor? armor) {
    String content = "<none>";
    if (armor != null) {
      content = '${armor.name} - '
          '${armor.majorDamageThreshold} / ${armor.severeDamageThreshold}, '
          'Base Score: ${armor.baseScore}';
    }
    return _buildReviewItem("Armor", content);
  }

  Widget _buildEquipmentItem(Item item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: itemSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '• ${item.name}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (item.quantity > 1) Text(' (${item.quantity}x)'),
            ],
          ),
          if (item.description?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                item.description!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundSection(
    BuildContext context,
    Character character,
    GameDataService gameDataService,
  ) {
    return _buildReviewSection(
      title: 'Background',
      content: _buildBackgroundContent(
        character,
        gameDataService,
      ),
    );
  }

  Widget _buildBackgroundContent(
    Character character,
    GameDataService gameDataService,
  ) {
    final classQuestions =
        gameDataService.backgroundQuestions[character.characterClass?.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Questionnaire answers
        if (character.backgroundQuestionnaireAnswers.isNotEmpty &&
            classQuestions != null)
          ..._buildQuestionnaireAnswers(character, classQuestions),

        // General background
        if (character.background?.isNotEmpty == true) ...[
          if (character.backgroundQuestionnaireAnswers.isNotEmpty)
            const SizedBox(height: itemSpacing),
          Text(character.background!),
        ],
      ],
    );
  }

  List<Widget> _buildQuestionnaireAnswers(
    Character character,
    Map<String, BackgroundQuestion> classQuestions,
  ) {
    final widgets = <Widget>[];
    final entries = character.backgroundQuestionnaireAnswers.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final question = classQuestions[entry.key];

      if (question != null) {
        widgets.add(
          Text(
            '${question.text} - ${entry.value}',
            style: const TextStyle(height: 1.4),
          ),
        );

        if (i < entries.length - 1) {
          widgets.add(const SizedBox(height: itemSpacing));
        }
      }
    }

    return widgets;
  }

  Widget _buildExperiencesSection(Character character) {
    return _buildReviewSection(
      title: 'Experiences',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: character.experiences.map((experience) {
          return Padding(
            padding: const EdgeInsets.only(bottom: itemSpacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ${experience.name}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Text(
                  '(+${experience.modifier})',
                  style: const TextStyle(
                    color: HeartcraftTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDomainCardsSection(Character character) {
    return _buildReviewSection(
      title: 'Domain Cards',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: character.domainAbilities.map((ability) {
          return Padding(
            padding: const EdgeInsets.only(bottom: itemSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ${ability.name}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (ability.description?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      ability.description!,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewSection({
    required String title,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: HeartcraftTheme.gold,
            ),
          ),
          const SizedBox(height: itemSpacing),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HeartcraftTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HeartcraftTheme.darkPrimaryPurple),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: itemSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
