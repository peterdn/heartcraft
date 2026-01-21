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
import 'package:heartcraft/models/character.dart';
import 'package:provider/provider.dart';
import '../../view_models/character_view_model.dart';
import '../../view_models/edit_mode_view_model.dart';
import '../../theme/heartcraft_theme.dart';
import '../../widgets/character_view/resource_card.dart';

/// Character resources tab
/// Manages evasion, damage thresholds, armor, HP, stress, and hope
class ResourcesTab extends StatelessWidget {
  const ResourcesTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final characterViewModel = context.watch<CharacterViewModel>();
    final editMode = context.watch<EditModeViewModel>().editMode;
    final character = characterViewModel.currentCharacter;
    if (character == null) return const SizedBox();

    final evasion = character.evasion;

    final maxArmor = character.maxArmor;
    final currentArmor =
        character.currentArmor.clamp(0, maxArmor as num) as int;

    final maxHP = character.maxHitPoints;
    final markedHP = character.currentHitPoints.clamp(0, maxHP);

    final maxStress = character.maxStress;
    final markedStress = character.currentStress.clamp(0, maxStress);

    final maxHope = character.maxHope;
    final markedHope = character.currentHope.clamp(0, maxHope);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEvasionAndDamageThresholdsCard(
              context, character, editMode, evasion, characterViewModel),
          _buildArmorCard(
              context, editMode, maxArmor, currentArmor, characterViewModel),
          _buildHPCard(context, editMode, maxHP, markedHP, characterViewModel),
          _buildStressCard(
              context, editMode, maxStress, markedStress, characterViewModel),
          _buildHopeCard(
              context, editMode, maxHope, markedHope, characterViewModel),
        ],
      ),
    );
  }

  Widget _buildEvasionAndDamageThresholdsCard(
    BuildContext context,
    Character character,
    bool editMode,
    int evasion,
    CharacterViewModel characterViewModel,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 32,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            // Evasion Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48, // Fixed height to match two-line labels
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (editMode) ...[
                            Row(
                              children: [
                                ResourceEditButton(
                                  icon: Icons.remove_circle_outline,
                                  onPressed: evasion > 1
                                      ? () => characterViewModel
                                          .updateEvasion(evasion - 1)
                                      : null,
                                ),
                                ResourceEditButton(
                                  icon: Icons.add_circle_outline,
                                  onPressed: () => characterViewModel
                                      .updateEvasion(evasion + 1),
                                ),
                              ],
                            ),
                          ],
                          Text(
                            'Evasion',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: HeartcraftTheme.gold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HeartcraftTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: HeartcraftTheme.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    evasion.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: HeartcraftTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            // Major Damage Threshold Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (editMode) ...[
                            Row(
                              children: [
                                ResourceEditButton(
                                  icon: Icons.remove_circle_outline,
                                  onPressed: character.majorDamageThreshold > 1
                                      ? () => characterViewModel
                                          .updateMajorDamageThreshold(
                                              character.majorDamageThreshold -
                                                  1)
                                      : null,
                                ),
                                ResourceEditButton(
                                  icon: Icons.add_circle_outline,
                                  onPressed: character.majorDamageThreshold <
                                          character.severeDamageThreshold - 1
                                      ? () => characterViewModel
                                          .updateMajorDamageThreshold(
                                              character.majorDamageThreshold +
                                                  1)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                          Text(
                            'Major\nDamage',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: HeartcraftTheme.gold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HeartcraftTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: HeartcraftTheme.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    character.majorDamageThreshold.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: HeartcraftTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            // Severe Damage Threshold Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (editMode) ...[
                            Row(
                              children: [
                                ResourceEditButton(
                                  icon: Icons.remove_circle_outline,
                                  onPressed: character.severeDamageThreshold >
                                          character.majorDamageThreshold + 1
                                      ? () => characterViewModel
                                          .updateSevereDamageThreshold(
                                              character.severeDamageThreshold -
                                                  1)
                                      : null,
                                ),
                                ResourceEditButton(
                                  icon: Icons.add_circle_outline,
                                  onPressed: () => characterViewModel
                                      .updateSevereDamageThreshold(
                                          character.severeDamageThreshold + 1),
                                ),
                              ],
                            ),
                          ],
                          Text(
                            'Severe\nDamage',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: HeartcraftTheme.gold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HeartcraftTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: HeartcraftTheme.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    character.severeDamageThreshold.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: HeartcraftTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArmorCard(
    BuildContext context,
    bool editMode,
    int maxArmor,
    int currentArmor,
    CharacterViewModel characterViewModel,
  ) {
    return ResourceCard(
      editMode: editMode,
      title: 'Armor',
      maxValue: maxArmor,
      currentValue: currentArmor,
      icon: Icons.shield,
      color: Colors.blue,
      onMaxDecrement: maxArmor >= 1
          ? () => characterViewModel.updateMaxArmor(maxArmor - 1)
          : null,
      onMaxIncrement: () => characterViewModel.updateMaxArmor(maxArmor + 1),
      onValueChanged: (value) => characterViewModel.updateArmor(value),
    );
  }

  Widget _buildHPCard(
    BuildContext context,
    bool editMode,
    int maxHP,
    int markedHP,
    CharacterViewModel characterViewModel,
  ) {
    return ResourceCard(
      editMode: editMode,
      title: 'HP',
      maxValue: maxHP,
      currentValue: markedHP,
      icon: Icons.favorite,
      color: Colors.red,
      onMaxDecrement: maxHP > 1
          ? () => characterViewModel.updateMaxHitPoints(maxHP - 1)
          : null,
      onMaxIncrement: () => characterViewModel.updateMaxHitPoints(maxHP + 1),
      onValueChanged: (value) =>
          characterViewModel.updateCurrentHitPoints(value),
    );
  }

  Widget _buildStressCard(
    BuildContext context,
    bool editMode,
    int maxStress,
    int markedStress,
    CharacterViewModel characterViewModel,
  ) {
    return ResourceCard(
      editMode: editMode,
      title: 'Stress',
      maxValue: maxStress,
      currentValue: markedStress,
      icon: Icons.warning,
      color: Colors.orange,
      onMaxDecrement: maxStress > 1
          ? () => characterViewModel.updateMaxStress(maxStress - 1)
          : null,
      onMaxIncrement: () => characterViewModel.updateMaxStress(maxStress + 1),
      onValueChanged: (value) => characterViewModel.updateStress(value),
    );
  }

  Widget _buildHopeCard(
    BuildContext context,
    bool editMode,
    int maxHope,
    int markedHope,
    CharacterViewModel characterViewModel,
  ) {
    return ResourceCard(
      editMode: editMode,
      title: 'Hope',
      maxValue: maxHope,
      currentValue: markedHope,
      icon: Icons.star,
      color: Colors.green,
      onMaxDecrement: maxHope > 1
          ? () => characterViewModel.updateMaxHope(maxHope - 1)
          : null,
      onMaxIncrement: () => characterViewModel.updateMaxHope(maxHope + 1),
      onValueChanged: (value) => characterViewModel.updateHope(value),
    );
  }
}
