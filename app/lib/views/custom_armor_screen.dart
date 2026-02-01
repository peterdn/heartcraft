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
import 'package:heartcraft/view_models/character_view_model.dart';
import 'package:heartcraft/views/add_armor_screen.dart';
import 'package:provider/provider.dart';
import '../theme/heartcraft_theme.dart';

class CustomArmorScreen extends StatelessWidget {
  const CustomArmorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final characterViewModel = context.watch<CharacterViewModel>();
    final character = characterViewModel.currentCharacter!;

    return Scaffold(
        appBar: AppBar(title: Text('Manage Armor'), actions: [
          // New armor button
          IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                final newArmor = await Navigator.of(context).push<Armor>(
                  MaterialPageRoute(
                    builder: (context) => const AddArmorScreen(),
                  ),
                );

                if (newArmor != null) {
                  characterViewModel.upsertCustomArmor(newArmor);
                }
              }),
        ]),
        body: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: character.customArmor.isNotEmpty
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var armor in character.customArmor)
                              _buildArmorCard(context, armor),
                          ],
                        ),
                      )
                    : Center(
                        child: Text(
                          'No custom armor for this character.\nTap the + button to create one.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                        ),
                      ),
              ),
            ),
          ],
        ));
  }

  Widget _buildArmorCard(BuildContext context, Armor armor) {
    final characterViewModel = context.read<CharacterViewModel>();

    final title = '${armor.name} (Tier ${armor.tier})';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
          title: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: HeartcraftTheme.lightPurple)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                'Thresholds: ${armor.baseThresholds} • Base Score: ${armor.baseScore}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[300],
                    ),
              ),
              if (armor.feature.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  armor.feature,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[300],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final updatedArmor =
                        await Navigator.of(context).push<Armor>(
                      MaterialPageRoute(
                        builder: (context) => AddArmorScreen(
                          existingArmor: armor,
                        ),
                      ),
                    );

                    if (updatedArmor != null) {
                      characterViewModel.upsertCustomArmor(updatedArmor);

                      // If the updated armor was equipped, update its reference
                      final character = characterViewModel.currentCharacter!;
                      if (character.equippedArmor?.id == updatedArmor.id) {
                        characterViewModel.updateEquippedArmor(updatedArmor);
                      }
                    }
                  }),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  if (await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Armor?'),
                          content: Text(
                              'Are you sure you want to delete ${armor.name}? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: HeartcraftTheme.errorRed,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ==
                      true) {
                    characterViewModel.deleteCustomArmor(armor.id);
                  }
                },
              ),
            ],
          )),
    );
  }
}
