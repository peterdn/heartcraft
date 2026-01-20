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
import 'package:heartcraft/providers/character_provider.dart';
import 'package:provider/provider.dart';
import '../models/equipment.dart';
import '../theme/heartcraft_theme.dart';
import 'add_weapon_screen.dart';

class CustomWeaponScreen extends StatelessWidget {
  const CustomWeaponScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final characterProvider = context.watch<CharacterProvider>();
    final character = characterProvider.currentCharacter!;

    return Scaffold(
        appBar: AppBar(title: Text('Manage Weapons'), actions: [
          // New weapon button
          IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                final newWeapon = await Navigator.of(context).push<Weapon>(
                  MaterialPageRoute(
                    builder: (context) => const AddWeaponScreen(),
                  ),
                );

                if (newWeapon != null) {
                  characterProvider.upsertCustomWeapon(newWeapon);
                }
              }),
        ]),
        body: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: character.customWeapons.isNotEmpty
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var weapon in character.customWeapons)
                              _buildWeaponCard(context, weapon),
                          ],
                        ),
                      )
                    : Center(
                        child: Text(
                          'No custom weapons for this character.\nTap the + button to create one.',
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

  Widget _buildWeaponCard(BuildContext context, Weapon weapon) {
    final characterProvider = context.read<CharacterProvider>();

    final title =
        '${weapon.name} (${weapon.type[0].toUpperCase() + weapon.type.substring(1)} - Tier ${weapon.tier})';
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
                '${weapon.trait} • ${weapon.range} • ${weapon.damage} • ${weapon.burden.displayName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[300],
                    ),
              ),
              if (weapon.feature.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  weapon.feature,
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
                    final updatedWeapon =
                        await Navigator.of(context).push<Weapon>(
                      MaterialPageRoute(
                        builder: (context) => AddWeaponScreen(
                          existingWeapon: weapon,
                        ),
                      ),
                    );

                    if (updatedWeapon != null) {
                      characterProvider.upsertCustomWeapon(updatedWeapon);

                      // If the updated weapon was equipped, update its referemce
                      final character = characterProvider.currentCharacter!;
                      if (character.primaryWeapon?.id == updatedWeapon.id) {
                        characterProvider.updatePrimaryWeapon(updatedWeapon);
                      }
                      if (character.secondaryWeapon?.id == updatedWeapon.id) {
                        characterProvider.updateSecondaryWeapon(updatedWeapon);
                      }

                      // Re-validate in case weapon type or damage type changed
                      characterProvider.validateEquippedCustomWeapons();
                    }
                  }),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  if (await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Weapon?'),
                          content: Text(
                              'Are you sure you want to delete ${weapon.name}? This action cannot be undone.'),
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
                    characterProvider.deleteCustomWeapon(weapon.id);
                  }
                },
              ),
            ],
          )),
    );
  }
}
