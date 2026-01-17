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
import 'package:provider/provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/edit_mode_provider.dart';
import '../../theme/heartcraft_theme.dart';
import '../../models/character.dart';
import '../../models/gold.dart';
import '../../models/equipment.dart';
import '../../services/game_data_service.dart';
import '../../widgets/weapon_dropdown.dart';
import '../../widgets/armor_dropdown.dart';

/// Equipment tab for character view
/// Allows managing active weapons, armor, gold, and inventory
/// TODO: support custom weapons/armor; override 2h weapon constraint
class EquipmentTab extends StatelessWidget {
  const EquipmentTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final characterProvider = context.watch<CharacterProvider>();
    final editMode = context.watch<EditModeProvider>().editMode;
    final character = characterProvider.currentCharacter;
    if (character == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActiveWeaponsSection(
                context, character, editMode, characterProvider),
            const SizedBox(height: 8),
            _buildActiveArmorSection(
                context, character, editMode, characterProvider),
            const SizedBox(height: 8),
            _buildGoldSection(context, character, editMode, characterProvider),
            const SizedBox(height: 8),
            _buildInventorySection(
                context, character, editMode, characterProvider),
          ],
        ),
      ),
    );
  }

  /// Build active weapons section
  /// Includes proficiency field and primary/secondary weapon cards
  Widget _buildActiveWeaponsSection(BuildContext context, Character character,
      bool editMode, CharacterProvider characterProvider) {
    final proficiency = character.proficiency;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // HACK? manually wrap Proficiency field to next line if not enough space
                // Seriously, there has GOT to be a built-in way of doing this
                const titleWidth = 200.0;
                const proficiencyWidth = 150.0;
                const padding = 16.0;

                final hasSpaceForSameLine = constraints.maxWidth >=
                    (titleWidth + proficiencyWidth + padding);

                final titleWidget = Text(
                  'Active Weapons',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: HeartcraftTheme.gold,
                      ),
                );

                final proficiencyWidget = _buildProficiencyField(
                  context,
                  proficiency,
                  editMode,
                  characterProvider,
                );

                if (hasSpaceForSameLine) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [titleWidget, proficiencyWidget],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 8),
                      proficiencyWidget,
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // Primary Weapon
            _buildWeaponCard(
              context,
              'Primary Weapon',
              character.primaryWeapon,
              editMode,
              (weapon) => characterProvider.updatePrimaryWeapon(weapon),
              true, // isPrimary
              characterProvider,
            ),
            const SizedBox(height: 12),

            // Secondary Weapon
            _buildWeaponCard(
              context,
              'Secondary Weapon',
              character.secondaryWeapon,
              editMode &&
                  character.primaryWeapon?.burden != WeaponBurden.twoHanded,
              (weapon) => characterProvider.updateSecondaryWeapon(weapon),
              false, // isPrimary
              characterProvider,
            ),

            // Show constraint message for two-handed weapons
            // TODO: allow override
            if (character.primaryWeapon?.burden == WeaponBurden.twoHanded)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, color: Colors.grey[400], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You cannot wield a secondary weapon with a two-handed primary weapon',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[400],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build proficiency field with dropdown in edit mode
  Widget _buildProficiencyField(
    BuildContext context,
    int proficiency,
    bool editMode,
    CharacterProvider characterProvider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Proficiency:  ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: HeartcraftTheme.gold,
              ),
        ),
        if (editMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: HeartcraftTheme.surfaceColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: proficiency,
                dropdownColor: HeartcraftTheme.surfaceColor,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HeartcraftTheme.gold,
                    ),
                onChanged: (value) {
                  if (value != null) {
                    characterProvider.updateProficiency(value);
                  }
                },
                items: List.generate(6, (index) => index + 1)
                    .map((value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        ))
                    .toList(),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: HeartcraftTheme.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: HeartcraftTheme.gold.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              proficiency.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HeartcraftTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
      ],
    );
  }

  /// Build active armor section
  Widget _buildActiveArmorSection(BuildContext context, Character character,
      bool editMode, CharacterProvider characterProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Armor',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: HeartcraftTheme.gold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildArmorCard(
              context,
              character.equippedArmor,
              character.tier,
              editMode,
              (armor) => characterProvider.updateEquippedArmor(armor),
            ),
          ],
        ),
      ),
    );
  }

  /// Build gold display section
  Widget _buildGoldSection(BuildContext context, Character character,
      bool editMode, CharacterProvider characterProvider) {
    final gold = character.gold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Gold',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: HeartcraftTheme.gold,
                      ),
                ),
                if (editMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _showModifyGoldDialog(context, characterProvider);
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_money),
                          SizedBox(width: 8),
                          Text('Earn / Spend'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      gold.toString(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: HeartcraftTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${gold.totalCoins} coins',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: HeartcraftTheme.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total value',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[400],
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

  /// Show dialog to modify (add) gold
  void _showModifyGoldDialog(BuildContext context, CharacterProvider provider) {
    final chestsController = TextEditingController(text: '0');
    final bagsController = TextEditingController(text: '0');
    final handfulsController = TextEditingController(text: '0');
    final coinsController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          Gold parseEntered() {
            final chests = int.tryParse(chestsController.text) ?? 0;
            final bags = int.tryParse(bagsController.text) ?? 0;
            final handfuls = int.tryParse(handfulsController.text) ?? 0;
            final coins = int.tryParse(coinsController.text) ?? 0;
            return Gold(
                chests: chests, bags: bags, handfuls: handfuls, coins: coins);
          }

          final entered = parseEntered();
          final available = provider.currentCharacter?.gold ?? Gold.empty();
          final canAfford =
              available.canAfford(entered) && entered.totalCoins > 0;

          return AlertDialog(
            title: const Text('Earn / Spend Gold'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: chestsController,
                  decoration: const InputDecoration(
                    labelText: 'Chests',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bagsController,
                  decoration: const InputDecoration(
                    labelText: 'Bags',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: handfulsController,
                  decoration: const InputDecoration(
                    labelText: 'Handfuls',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coinsController,
                  decoration: const InputDecoration(
                    labelText: 'Coins',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final entered = parseEntered();
                  if (entered.totalCoins <= 0) {
                    Navigator.pop(context);
                    return;
                  }
                  provider.addGold(entered);
                  Navigator.pop(context);
                },
                child: const Text('Earn'),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: canAfford
                    ? () {
                        final toSpend = parseEntered();
                        provider.spendGold(toSpend);
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Spend'),
              ),
            ],
          );
        });
      },
    );
  }

  /// Build inventory section
  Widget _buildInventorySection(BuildContext context, Character character,
      bool editMode, CharacterProvider characterProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Inventory',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: HeartcraftTheme.gold,
                      ),
                ),
                if (editMode)
                  Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          _showAddItemDialog(context, characterProvider);
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text('Add Item'),
                          ],
                        ),
                      )),
              ],
            ),
            const SizedBox(height: 16),
            character.inventory.isEmpty
                ? const Center(
                    child: Text('No items in inventory'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: character.inventory.length,
                    itemBuilder: (context, index) {
                      final item = character.inventory[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: item.description != null
                            ? Text(item.description!)
                            : null,
                        trailing: editMode
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${item.quantity}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                    onPressed: item.quantity > 1
                                        ? () {
                                            characterProvider
                                                .updateItemQuantity(
                                                    item.id, item.quantity - 1);
                                          }
                                        : () {
                                            characterProvider
                                                .removeItem(item.id);
                                          },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      characterProvider.updateItemQuantity(
                                          item.id, item.quantity + 1);
                                    },
                                  ),
                                ],
                              )
                            : Text('${item.quantity}',
                                style: Theme.of(context).textTheme.bodyMedium),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to add item to inventory
  void _showAddItemDialog(BuildContext context, CharacterProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final desc = descController.text.trim();
                  final quantity = int.tryParse(quantityController.text) ?? 1;

                  provider.addItem(
                    Item(
                      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      description: desc.isNotEmpty ? desc : null,
                      quantity: quantity > 0 ? quantity : 1,
                    ),
                  );

                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Build a weapon card for either display or edit mode
  Widget _buildWeaponCard(
    BuildContext context,
    String title,
    Weapon? weapon,
    bool canEdit,
    Function(Weapon?) onChanged,
    bool isPrimary,
    CharacterProvider characterProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: HeartcraftTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HeartcraftTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (canEdit) ...[
            // Edit mode - only show dropdown
            _buildWeaponDropdown(
                context, isPrimary, onChanged, characterProvider, weapon),
          ] else ...[
            // Display mode - show weapon details or empty state
            if (weapon == null) ...[
              Text(
                'No weapon equipped',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ] else ...[
              // Weapon equipped - show details
              Text(
                weapon.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Trait & range: ${weapon.trait} ${weapon.range}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[300],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Damage dice & type: ${weapon.damage}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[300],
                    ),
              ),
              if (weapon.feature.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  weapon.feature,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  /// Build weapon dropdown for edit mode
  Widget _buildWeaponDropdown(BuildContext context, bool isPrimary,
      Function(Weapon?) onChanged, CharacterProvider characterProvider,
      [Weapon? currentWeapon]) {
    final gameDataService = context.read<GameDataService>();
    final character = characterProvider.currentCharacter!;

    List<Weapon> availableWeapons;
    List<Weapon> physicalWeapons;
    List<Weapon> magicWeapons;
    if (isPrimary) {
      physicalWeapons = gameDataService.primaryWeapons
          .where((w) => w.type == 'physical')
          .toList();
      magicWeapons = gameDataService.primaryWeapons
          .where((w) => w.type == 'magic')
          .toList();
    } else {
      physicalWeapons = gameDataService.secondaryWeapons
          .where((w) => w.type == 'physical')
          .toList();
      magicWeapons = gameDataService.secondaryWeapons
          .where((w) => w.type == 'magic')
          .toList();
    }

    // Include magic weapons only if character has spellcast trait
    if (character.subclass?.spellcastTrait != null) {
      availableWeapons = [...physicalWeapons, ...magicWeapons];
    } else {
      availableWeapons = physicalWeapons;
    }

    return WeaponDropdown(
      weapons: availableWeapons,
      selectedWeapon: currentWeapon,
      maxTier: character.tier,
      onChanged: onChanged,
    );
  }

  /// Build armor card for either display or edit mode
  Widget _buildArmorCard(
    BuildContext context,
    Armor? armor,
    int maxTier,
    bool canEdit,
    Function(Armor?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: HeartcraftTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Armor',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HeartcraftTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (canEdit) ...[
            // Edit mode - only show dropdown
            _buildArmorDropdown(context, onChanged, armor, maxTier),
          ] else ...[
            // Display mode - show armor details or empty state
            if (armor == null) ...[
              Text(
                'No armor equipped',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ] else ...[
              // Armor equipped - show details
              Text(
                armor.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Thresholds: ${armor.baseThresholds}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[300],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Base Score: ${armor.baseScore}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[300],
                    ),
              ),
              if (armor.feature.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  armor.feature,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  /// Build armor dropdown for edit mode
  Widget _buildArmorDropdown(BuildContext context, Function(Armor?) onChanged,
      Armor? currentArmor, int maxTier) {
    final gameDataService = context.read<GameDataService>();
    final availableArmor = gameDataService.armor;

    return ArmorDropdown(
      armor: availableArmor,
      selectedArmor: currentArmor,
      maxTier: maxTier,
      onChanged: onChanged,
    );
  }
}
