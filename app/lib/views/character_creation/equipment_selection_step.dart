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
import '../../providers/character_creation_provider.dart';
import '../../theme/heartcraft_theme.dart';
import '../../models/equipment.dart';
import '../../models/gold.dart';
import '../../services/game_data_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/weapon_dropdown.dart';
import '../../widgets/armor_dropdown.dart';

/// Equipment selection step widget for character creation
class EquipmentSelectionStep extends StatefulWidget {
  final CharacterCreationProvider provider;

  const EquipmentSelectionStep({super.key, required this.provider});

  @override
  EquipmentSelectionStepState createState() => EquipmentSelectionStepState();
}

class EquipmentSelectionStepState extends State<EquipmentSelectionStep> {
  late final GameDataService gameDataService;
  late final List<Weapon> primaryPhysicalWeapons;
  late final List<Weapon> primaryMagicWeapons;
  late final List<Weapon> secondaryWeapons;
  late final List<Weapon> secondaryPhysicalWeapons;
  late final List<Weapon> secondaryMagicWeapons;
  late final List<Armor> armorList;
  late final List<OptionGroup> optionGroups;
  late final List<String> automaticItems;
  late final Gold? startingGold;

  /// Get class-specific items based on current character class
  List<String> get classItems {
    final characterClass = widget.provider.character.characterClass;
    if (characterClass == null) return [];
    return gameDataService.classItems[characterClass.id] ?? [];
  }

  @override
  void initState() {
    super.initState();
    gameDataService = context.read<GameDataService>();

    final primaryWeapons = gameDataService.primaryWeapons;
    primaryPhysicalWeapons =
        primaryWeapons.where((w) => w.type == 'physical').toList();
    primaryMagicWeapons =
        primaryWeapons.where((w) => w.type == 'magic').toList();
    secondaryWeapons = gameDataService.secondaryWeapons;
    secondaryPhysicalWeapons =
        secondaryWeapons.where((w) => w.type == 'physical').toList();
    secondaryMagicWeapons =
        secondaryWeapons.where((w) => w.type == 'magic').toList();
    armorList = gameDataService.armor;
    automaticItems = gameDataService.startingItems;
    startingGold = gameDataService.startingGold;
    optionGroups = gameDataService.startingOptionGroups;
  }

  @override
  Widget build(BuildContext context) {
    // Displays multiple sections for selecting equipment
    // - Primary Weapon
    // - Secondary Weapon (if primary is one-handed)
    // - Armor
    // - Dynamic Option Groups from compendium e.g. starting potion
    // - Class-specific item
    // - List of automatic starting items and gold
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: ResponsiveUtils.responsiveValue(
              context,
              narrow: const EdgeInsets.only(left: 16, right: 160, bottom: 16),
              wide: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Choose Starting Equipment',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: HeartcraftTheme.gold,
                      fontSize: ResponsiveUtils.responsiveValue(context,
                          narrow: 20, wide: 24),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select your weapons, armor, and other items.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveUtils.responsiveValue(context,
                          narrow: 14, wide: 16),
                    ),
              ),
            ])),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: ResponsiveUtils.responsiveValue(context,
                  narrow:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  wide: const EdgeInsets.only(left: 24, right: 24, bottom: 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Primary Weapon",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HeartcraftTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 12),

                  // Primary Weapon Selection
                  _buildWeaponSection(
                    _getAvailablePrimaryWeapons(),
                    widget.provider.character.primaryWeapon,
                    (weapon) => widget.provider.selectPrimaryWeapon(weapon),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "Secondary Weapon",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HeartcraftTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary weapon Selection (only if primary is one-handed)
                  if (widget.provider.character.primaryWeapon?.burden !=
                      WeaponBurden.twoHanded)
                    _buildWeaponSection(
                      _getAvailableSecondaryWeapons(),
                      widget.provider.character.secondaryWeapon,
                      (weapon) => widget.provider.selectSecondaryWeapon(weapon),
                    ),

                  if (widget.provider.character.primaryWeapon?.burden ==
                      WeaponBurden.twoHanded)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You cannot wield a secondary weapon with a two-handed primary weapon',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Armor selection
                  _buildArmorSection(),

                  const SizedBox(height: 24),

                  // Dynamic option groups
                  ...optionGroups
                      .map((optionGroup) => [
                            _buildOptionGroupSection(optionGroup),
                            const SizedBox(height: 24),
                          ])
                      .expand((widgets) => widgets),

                  // Class item selection (show always, with info if no class selected)
                  _buildClassItemSection(),
                  const SizedBox(height: 24),

                  // Starting items preview
                  _buildStartingItemsPreview(),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  /// Get available primary weapons based on character's subclass
  /// If subclass has spellcast trait, include magic weapons
  List<Weapon> _getAvailablePrimaryWeapons() {
    final character = widget.provider.character;
    final subclass = character.subclass;

    // If subclass has a spellcast trait, include magic weapons
    if (subclass != null && subclass.spellcastTrait != null) {
      return [...primaryPhysicalWeapons, ...primaryMagicWeapons];
    }

    // If subclass not selected or has no spellcast trait, only show physical weapons
    return primaryPhysicalWeapons;
  }

  /// Get available secondary weapons based on character's subclass
  /// If subclass has spellcast trait, include magic weapons
  List<Weapon> _getAvailableSecondaryWeapons() {
    final character = widget.provider.character;
    final subclass = character.subclass;

    // If subclass has a spellcast trait, include magic weapons
    if (subclass != null && subclass.spellcastTrait != null) {
      return [...secondaryPhysicalWeapons, ...secondaryMagicWeapons];
    }

    // If subclass not selected or has no spellcast trait, only show physical weapons
    return secondaryPhysicalWeapons;
  }

  Widget _buildWeaponSection(
    List<Weapon> weapons,
    Weapon? selected,
    Function(Weapon?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeaponDropdown(
            weapons, weapons.contains(selected) ? selected : null, onChanged),
      ],
    );
  }

  Widget _buildWeaponDropdown(
    List<Weapon> weapons,
    Weapon? selected,
    Function(Weapon?) onChanged, {
    bool isDisabled = false,
  }) {
    return WeaponDropdown(
      weapons: weapons,
      selectedWeapon: selected,
      maxTier: 1,
      onChanged: onChanged,
      isDisabled: isDisabled,
    );
  }

  Widget _buildArmorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Armor',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HeartcraftTheme.gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ArmorDropdown(
          armor: armorList,
          maxTier: 1,
          selectedArmor: widget.provider.character.equippedArmor,
          onChanged: (armor) => widget.provider.selectArmor(armor),
        ),
      ],
    );
  }

  Widget _buildOptionGroupSection(OptionGroup optionGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          optionGroup.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HeartcraftTheme.gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose one:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 12),
        _buildItemDropdown(
          value: widget.provider.optionGroupSelections[optionGroup.id],
          hint: 'Select from ${optionGroup.name}',
          onChanged: (selectedItem) => widget.provider
              .selectOptionGroupItem(optionGroup.id, selectedItem),
          items: optionGroup.options.map((option) => option.item).toList(),
          itemDescriptions: Map.fromEntries(
            optionGroup.options
                .where((option) => option.description != null)
                .map((option) => MapEntry(option.item, option.description!)),
          ),
        ),
      ],
    );
  }

  Widget _buildClassItemSection() {
    final hasClass = widget.provider.character.characterClass != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class-Specific Item',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HeartcraftTheme.gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose one class-specific item:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 12),
        if (hasClass && classItems.isNotEmpty)
          _buildItemDropdown(
            value: widget.provider.selectedClassItem,
            hint: 'Select class item',
            onChanged: (selectedItem) =>
                widget.provider.selectClassItem(selectedItem),
            items: classItems,
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasClass
                        ? 'No class-specific items available for your selected class'
                        : 'You must select a class before you can select your class-specific item',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Common dropdown widget for "simple" item selection
  Widget _buildItemDropdown({
    required String? value,
    required String hint,
    required Function(String?) onChanged,
    required List<String> items,
    Map<String, String>? itemDescriptions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: HeartcraftTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          dropdownColor: HeartcraftTheme.surfaceColor,
          itemHeight: itemDescriptions != null && itemDescriptions.isNotEmpty
              ? 80
              : null,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: HeartcraftTheme.gold,
          ),
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              hint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
          ),
          onChanged: onChanged,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'None selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ),
            ...items.map(
              (item) {
                final description = itemDescriptions?[item];
                return DropdownMenuItem<String?>(
                  value: item,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.toString(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: HeartcraftTheme.primaryTextColor,
                                  ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[400],
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartingItemsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automatic Starting Items',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HeartcraftTheme.gold,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'These items are automatically added to your inventory:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HeartcraftTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...automaticItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          item,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )),
              if (startingGold != null && startingGold!.totalCoins > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        startingGold.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HeartcraftTheme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
