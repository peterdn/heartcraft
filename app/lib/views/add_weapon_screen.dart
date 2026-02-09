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
import 'package:heartcraft/utils/dialogs.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import '../models/trait.dart';
import '../theme/heartcraft_theme.dart';

class AddWeaponScreen extends StatefulWidget {
  const AddWeaponScreen({super.key, this.existingWeapon});

  final Weapon? existingWeapon;

  @override
  State<AddWeaponScreen> createState() => AddWeaponScreenState();
}

class AddWeaponScreenState extends State<AddWeaponScreen> {
  String name = '';
  String feature = '';
  String damageModifier = '0';
  WeaponBurden? selectedBurden;
  DamageType? selectedDamageType;
  WeaponType? selectedWeaponType;
  int? selectedTier;
  Trait? selectedTrait;
  Range? selectedRange;
  DamageDie? selectedDie;
  bool isFormValid = false;
  bool editMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingWeapon != null) {
      editMode = true;
      final weapon = widget.existingWeapon!;
      name = weapon.name;
      feature = weapon.feature;
      selectedBurden = weapon.burden;
      selectedDamageType = weapon.damageType;
      selectedWeaponType = weapon.type;
      selectedTier = weapon.tier;
      selectedTrait = Trait.values.firstWhere(
          (t) => t.displayName.toLowerCase() == weapon.trait.toLowerCase());
      selectedRange = Range.values.firstWhere(
          (r) => r.displayName.toLowerCase() == weapon.range.toLowerCase());
      selectedDie =
          DamageDie.fromString(weapon.damage.split(' ')[0].split('+')[0]);
      damageModifier = weapon.damage.contains('+')
          ? weapon.damage.split('+')[1].split(' ')[0]
          : '0';

      isFormValid = true;
    }
  }

  void _checkFormValidity() {
    setState(() {
      isFormValid = name.trim().isNotEmpty &&
          selectedWeaponType != null &&
          selectedTier != null &&
          selectedTrait != null &&
          selectedRange != null &&
          selectedDie != null &&
          selectedBurden != null &&
          selectedDamageType != null;
    });
  }

  void _createAndReturnWeapon() {
    if (isFormValid) {
      final modifier = int.tryParse(damageModifier) ?? 0;
      final damageString = (modifier > 0
              ? '${selectedDie!.displayName}+$modifier'
              : selectedDie!.displayName) +
          (selectedDamageType == DamageType.magic
              ? ' mag'
              : ' phy'); // TODO: handle damage as its own type

      final weapon = Weapon(
        id: editMode
            ? widget.existingWeapon!.id
            : 'custom_${Uuid().v4().substring(0, 8)}',
        name: name.trim(),
        trait: selectedTrait!.displayName,
        range: selectedRange!.displayName,
        damage: damageString,
        burden: selectedBurden!,
        feature: feature.trim(),
        damageType: selectedDamageType!,
        type: selectedWeaponType!,
        tier: selectedTier!,
        custom: true,
      );

      Navigator.of(context).pop(weapon);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await showExitConfirmation(context, 'weapon');
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Weapon'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: isFormValid ? _createAndReturnWeapon : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFormValid ? HeartcraftTheme.gold : Colors.grey,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white70,
                ),
                icon: Icon(isFormValid ? Icons.save : Icons.pending_actions),
                label: Text(
                  'Save Weapon',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: const InputDecoration(
                          labelText: 'Weapon Name',
                          border: OutlineInputBorder(),
                          hintText: 'Enter weapon name',
                        ),
                        onChanged: (value) {
                          name = value;
                          _checkFormValidity();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<WeaponType>(
                        label: 'Type',
                        value: selectedWeaponType,
                        hint: 'Select Type',
                        items: WeaponType.values,
                        itemLabel: (type) => type.displayName,
                        onChanged: (value) {
                          setState(() {
                            selectedWeaponType = value;
                            _checkFormValidity();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<int>(
                        label: 'Tier',
                        value: selectedTier,
                        hint: 'Select Tier',
                        items: [1, 2, 3, 4],
                        itemLabel: (tier) => 'Tier $tier',
                        onChanged: (value) {
                          setState(() {
                            selectedTier = value;
                            _checkFormValidity();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<Trait>(
                        label: 'Trait',
                        value: selectedTrait,
                        hint: 'Select Trait',
                        items: Trait.values,
                        itemLabel: (trait) => trait.displayName,
                        onChanged: (value) {
                          setState(() {
                            selectedTrait = value;
                            _checkFormValidity();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<Range>(
                        label: 'Range',
                        value: selectedRange,
                        hint: 'Select Range',
                        items: Range.values,
                        itemLabel: (range) => range.displayName,
                        onChanged: (value) {
                          setState(() {
                            selectedRange = value;
                            _checkFormValidity();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDropdown<DamageDie>(
                              label: 'Damage Die',
                              value: selectedDie,
                              hint: 'Select Die',
                              items: DamageDie.values,
                              itemLabel: (die) => die.displayName,
                              onChanged: (value) {
                                setState(() {
                                  selectedDie = value;
                                  _checkFormValidity();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modifier',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: HeartcraftTheme.gold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: damageModifier,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: '0',
                                    prefixText: '+',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    damageModifier = value;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<DamageType>(
                        label: 'Damage Type',
                        value: selectedDamageType,
                        hint: 'Select Damage Type',
                        items: DamageType.values,
                        itemLabel: (type) => type.displayName,
                        onChanged: (value) {
                          setState(() {
                            selectedDamageType = value;
                            _checkFormValidity();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<WeaponBurden>(
                        label: 'Burden',
                        value: selectedBurden,
                        hint: 'Select Burden',
                        items: [WeaponBurden.oneHanded, WeaponBurden.twoHanded],
                        itemLabel: (burden) => burden.displayName,
                        onChanged: (value) {
                          setState(() {
                            selectedBurden = value;
                            _checkFormValidity();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: feature,
                        decoration: const InputDecoration(
                          labelText: 'Feature (optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Special abilities or effects',
                        ),
                        onChanged: (value) {
                          feature = value;
                        },
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HeartcraftTheme.gold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: HeartcraftTheme.surfaceColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(hint),
              isExpanded: true,
              dropdownColor: HeartcraftTheme.surfaceColor,
              onChanged: onChanged,
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel(item)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
